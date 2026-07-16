import argparse
import os
from dataclasses import dataclass

import torch
import torch.nn as nn
from torch.nn.utils.rnn import pad_sequence, pack_padded_sequence, pad_packed_sequence
from torch.utils.data import Dataset, DataLoader


def load_sequences_from_clickhouse(host: str = None) -> list[dict]:
    import clickhouse_connect

    client = clickhouse_connect.get_client(
        host=host or os.getenv("CLICKHOUSE_HOST", "localhost"),
        port=8123,
        username="default",
        password="",
    )

    query = """
        SELECT
            child_id,
            groupArray(topic)      AS skill_sequence,
            groupArray(is_correct) AS correctness_sequence
        FROM clam_db.game_events
        WHERE is_correct IS NOT NULL
        GROUP BY child_id
        ORDER BY child_id
    """
    result = client.query(query)
    rows = []
    for child_id, skills, corrects in result.result_rows:
        if len(skills) >= 2:
            rows.append({"child_id": child_id, "skills": skills, "corrects": corrects})
    return rows


def load_sequences_from_csv(path: str) -> list[dict]:
    import csv
    from collections import defaultdict

    by_student = defaultdict(lambda: {"skills": [], "corrects": [], "ts": []})
    with open(path, newline="") as f:
        reader = csv.DictReader(f)
        for row in reader:
            sid = row["child_id"]
            by_student[sid]["skills"].append(row["topic"])
            by_student[sid]["corrects"].append(int(row["is_correct"]))
            by_student[sid]["ts"].append(row.get("created_at", ""))

    rows = []
    for child_id, d in by_student.items():
        order = sorted(range(len(d["ts"])), key=lambda i: d["ts"][i])
        skills = [d["skills"][i] for i in order]
        corrects = [d["corrects"][i] for i in order]
        if len(skills) >= 2:
            rows.append({"child_id": child_id, "skills": skills, "corrects": corrects})
    return rows


class DKTDataset(Dataset):
    def __init__(self, sequences: list[dict], skill_to_idx: dict[str, int]):
        self.sequences = sequences
        self.skill_to_idx = skill_to_idx
        self.num_skills = len(skill_to_idx)

    def __len__(self):
        return len(self.sequences)

    def __getitem__(self, idx):
        seq = self.sequences[idx]
        skills = [self.skill_to_idx[s] for s in seq["skills"]]
        corrects = seq["corrects"]

        seq_len = len(skills) - 1
        inputs = torch.zeros(seq_len, 2 * self.num_skills)
        next_skill = torch.zeros(seq_len, dtype=torch.long)
        next_correct = torch.zeros(seq_len)

        for t in range(seq_len):
            skill_id = skills[t]
            offset = self.num_skills if corrects[t] == 1 else 0
            inputs[t, offset + skill_id] = 1.0
            next_skill[t] = skills[t + 1]
            next_correct[t] = float(corrects[t + 1])

        return inputs, next_skill, next_correct


def collate_fn(batch):
    inputs, next_skill, next_correct = zip(*batch)
    lengths = torch.tensor([x.shape[0] for x in inputs])
    inputs_padded = pad_sequence(inputs, batch_first=True)
    next_skill_padded = pad_sequence(next_skill, batch_first=True)
    next_correct_padded = pad_sequence(next_correct, batch_first=True)
    return inputs_padded, next_skill_padded, next_correct_padded, lengths


class DKT(nn.Module):
    def __init__(self, num_skills: int, hidden_size: int = 64):
        super().__init__()
        self.num_skills = num_skills
        self.lstm = nn.LSTM(
            input_size=2 * num_skills,
            hidden_size=hidden_size,
            batch_first=True,
        )
        self.output_layer = nn.Linear(hidden_size, num_skills)

    def forward(self, inputs, lengths):
        packed = pack_padded_sequence(
            inputs, lengths.cpu(), batch_first=True, enforce_sorted=False
        )
        packed_out, _ = self.lstm(packed)
        out, _ = pad_packed_sequence(packed_out, batch_first=True)
        logits = self.output_layer(out)
        return logits


@dataclass
class TrainConfig:
    hidden_size: int = 64
    lr: float = 1e-3
    epochs: int = 20
    batch_size: int = 16


def train(sequences: list[dict], config: TrainConfig = TrainConfig()):
    all_skills = sorted({s for seq in sequences for s in seq["skills"]})
    skill_to_idx = {s: i for i, s in enumerate(all_skills)}
    num_skills = len(all_skills)
    print(f"Loaded {len(sequences)} student sequences over {num_skills} skills/topics.")

    if len(sequences) < 5:
        print("WARNING: very few sequences available.")

    dataset = DKTDataset(sequences, skill_to_idx)
    loader = DataLoader(
        dataset, batch_size=config.batch_size, shuffle=True, collate_fn=collate_fn
    )

    model = DKT(num_skills=num_skills, hidden_size=config.hidden_size)
    optimizer = torch.optim.Adam(model.parameters(), lr=config.lr)
    loss_fn = nn.BCEWithLogitsLoss(reduction="none")

    model.train()
    for epoch in range(config.epochs):
        total_loss = 0.0
        total_steps = 0
        for inputs, next_skill, next_correct, lengths in loader:
            optimizer.zero_grad()
            logits = model(inputs, lengths)

            pred_logits = torch.gather(
                logits, 2, next_skill.unsqueeze(-1)
            ).squeeze(-1)

            mask = torch.arange(logits.shape[1]).unsqueeze(0) < lengths.unsqueeze(1)
            loss_per_step = loss_fn(pred_logits, next_correct)
            loss = (loss_per_step * mask).sum() / mask.sum()

            loss.backward()
            optimizer.step()

            total_loss += loss.item() * mask.sum().item()
            total_steps += mask.sum().item()

        print(f"Epoch {epoch + 1}/{config.epochs} — avg loss: {total_loss / total_steps:.4f}")

    return model, skill_to_idx


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--csv", type=str, default=None)
    parser.add_argument("--clickhouse-host", type=str, default=None)
    args = parser.parse_args()

    if args.csv:
        sequences = load_sequences_from_csv(args.csv)
    else:
        sequences = load_sequences_from_clickhouse(host=args.clickhouse_host)

    model, skill_to_idx = train(sequences)
    torch.save(
        {"model_state": model.state_dict(), "skill_to_idx": skill_to_idx},
        "dkt_model.pt",
    )
    print("Saved model to dkt_model.pt")