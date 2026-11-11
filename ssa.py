"""Convert ordered assignments to static single assignment form."""
from collections import defaultdict
from dataclasses import dataclass
from pathlib import Path
from parser import Equation

@dataclass(frozen=True)
class SSAResult:
    equations: list[Equation]
    inputs: list[str]
    final_versions: dict[str, str]


def convert_to_ssa(equations: list[Equation]) -> SSAResult:
    counts = defaultdict(int)
    current = {}
    inputs = set()
    output = []
    for eq in equations:
        def resolve(operand):
            if operand.isdecimal():
                return operand
            if operand in current:
                return current[operand]
            inputs.add(operand)
            return operand
        left = resolve(eq.left)
        right = resolve(eq.right)
        counts[eq.target] += 1
        renamed = f"{eq.target}_{counts[eq.target]}"
        output.append(Equation(renamed, left, eq.operator, right))
        current[eq.target] = renamed
    # Input names and generated SSA names must be disjoint to avoid ambiguity.
    versions = {eq.target for eq in output}
    overlap = inputs & versions
    if overlap:
        raise ValueError(f"Input names conflict with SSA names: {sorted(overlap)}")
    return SSAResult(output, sorted(inputs), current)


def export_ssa(result: SSAResult, path: str | Path) -> None:
    Path(path).write_text("\n".join(map(str, result.equations)) + "\n", encoding="utf-8")
