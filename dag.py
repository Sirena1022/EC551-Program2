"""Build a directed acyclic dependency graph from SSA equations."""
from dataclasses import dataclass
from parser import Equation

@dataclass(frozen=True)
class Operation:
    id: int
    equation: Equation
    predecessors: tuple[int, ...]


def build_dag(equations: list[Equation]) -> list[Operation]:
    producer = {}
    nodes = []
    for index, eq in enumerate(equations):
        dependencies = tuple(sorted({producer[value] for value in (eq.left, eq.right) if value in producer}))
        nodes.append(Operation(index, eq, dependencies))
        producer[eq.target] = index
    return nodes
