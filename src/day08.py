import math
import re
from array import array
from dataclasses import dataclass

@dataclass
class JunctionBox:
    x: int
    y: int
    z: int

    def distance(self, other: 'JunctionBox') -> int:
        return (self.x - other.x)**2 + (self.y - other.y)**2 + (self.z - other.z)**2

boxes: list[JunctionBox] = []
with open('inputs/day08.txt', 'r') as f:
    for line in f.readlines():
        match = re.match(r"(\d+),(\d+),(\d+)", line)
        if (match):
            boxes.append(
                JunctionBox(
                    int(match.group(1)),
                    int(match.group(2)),
                    int(match.group(3))
                )
            )

distances: list[int | float] = [ba.distance(bd) if ba != bd else math.inf for ba in boxes for bd in boxes]
closest_ids = sorted(range(len(distances)), key=lambda b: distances[b]);
circuits: list[set[int]] = []
connections_made = 0;
for id in closest_ids[0::2]:
    boxa, boxb = divmod(id, len(boxes))
    print(boxa, boxb)
    ca: None | int = None
    cb: None | int = None
    for circut_idx, circuit in enumerate(circuits):
        if boxa in circuit:
            ca = circut_idx
        if boxb in circuit:
            cb = circut_idx
    if ca is not None and cb is not None and (ca != cb):
        # Merge!
        circuits[ca].update(circuits[cb])
        circuits[cb] = set()
        connections_made += 1
    elif ca is not None:
        circuits[ca].add(boxb)
        connections_made += 1
    elif cb is not None:
        circuits[cb].add(boxa)
        connections_made += 1
    else:
        circuits.append({boxa, boxb})
        connections_made += 1
    #print(circuits)
    if connections_made == 1000:
        break
print(sorted(list(len(c) for c in circuits)))
solution = math.prod(sorted(len(c) for c in circuits)[-3:])
print(solution)
