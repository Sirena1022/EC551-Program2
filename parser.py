"""Parse two-operand arithmetic assignments from a text file."""
from dataclasses import dataclass
from pathlib import Path
import re

IDENT = r"[A-Za-z_][A-Za-z_0-9]*"
OPERAND = rf"(?:{IDENT}|\d+)"
PATTERN = re.compile(rf"^\s*({IDENT})\s*=\s*({OPERAND})\s*([+*\-])\s*({OPERAND})\s*$")

@dataclass(frozen=True)
class Equation:
    target: str
    left: str
    operator: str
    right: str

    def __str__(self):
        return f"{self.target} = {self.left} {self.operator} {self.right}"


def parse_equations(path: str | Path) -> list[Equation]:
    equations = []
    for number, raw in enumerate(Path(path).read_text(encoding="utf-8").splitlines(), 1):
        line = raw.split("#", 1)[0].strip()
        if not line:
            continue
        match = PATTERN.fullmatch(line)
        if not match:
            raise ValueError(f"Line {number}: invalid equation: {raw!r}")
        equations.append(Equation(*match.groups()))
        if len(equations) > 20:
            raise ValueError("Input must contain no more than 20 equations")
    if not equations:
        raise ValueError("Input file has no equations")
    return equations
