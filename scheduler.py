"""Five scheduling strategies for unit-latency arithmetic DAGs."""
from collections import defaultdict
from dataclasses import dataclass
from dag import Operation

OPS = {"+": "adders", "-": "subtractors", "*": "multipliers"}

@dataclass(frozen=True)
class Schedule:
    mode: str
    cycles: dict[int, int]
    latency: int


def _validate(nodes, limits):
    if limits is None:
        return
    for name in OPS.values():
        if name not in limits or not isinstance(limits[name], int) or limits[name] < 1:
            raise ValueError(f"Resource limit '{name}' must be a positive integer")


def asap(nodes: list[Operation]) -> Schedule:
    cycles = {}
    for node in nodes:
        cycles[node.id] = 1 + max((cycles[p] for p in node.predecessors), default=0)
    return Schedule("asap", cycles, max(cycles.values(), default=0))


def alap(nodes: list[Operation], deadline: int) -> Schedule:
    if deadline < asap(nodes).latency:
        raise ValueError("Deadline is shorter than the critical path")
    successors = defaultdict(list)
    for node in nodes:
        for p in node.predecessors:
            successors[p].append(node.id)
    cycles = {}
    for node in reversed(nodes):
        cycles[node.id] = min((cycles[s] - 1 for s in successors[node.id]), default=deadline)
    return Schedule("alap", cycles, deadline)


def _list_schedule(nodes, limits, priority, deadline=None, mode="constrained-asap"):
    _validate(nodes, limits)
    assigned = {}
    used = defaultdict(lambda: defaultdict(int))
    remaining = {n.id for n in nodes}
    by_id = {n.id: n for n in nodes}
    t = 1
    while remaining:
        ready = [by_id[i] for i in remaining if all(p in assigned and assigned[p] < t for p in by_id[i].predecessors)]
        ready.sort(key=priority)
        scheduled_now = 0
        for node in ready:
            resource = OPS[node.equation.operator]
            if used[t][resource] < limits[resource]:
                assigned[node.id] = t
                used[t][resource] += 1
                remaining.remove(node.id)
                scheduled_now += 1
        if deadline is not None and t >= deadline and remaining:
            raise ValueError(f"No feasible schedule found by cycle {deadline} using this heuristic")
        if not scheduled_now and not ready:
            raise ValueError("No schedulable operations: dependency cycle or invalid DAG")
        t += 1
    return Schedule(mode, assigned, max(assigned.values(), default=0))


def constrained_asap(nodes, limits):
    return _list_schedule(nodes, limits, lambda n: n.id)


def _backward_constrained(nodes, limits, deadline):
    """Reverse-time list scheduling, prioritizing late-starting operations."""
    _validate(nodes, limits)
    if deadline < asap(nodes).latency:
        raise ValueError("Deadline is shorter than the critical path")
    successors = defaultdict(list)
    for n in nodes:
        for p in n.predecessors:
            successors[p].append(n.id)
    by_id = {n.id: n for n in nodes}
    assigned = {}
    remaining = set(by_id)
    for t in range(deadline, 0, -1):
        used = defaultdict(int)
        ready = [by_id[i] for i in remaining if all(s in assigned and assigned[s] > t for s in successors[i])]
        # Favor operations with more upstream dependencies (reverse critical path).
        ready.sort(key=lambda n: (-len(n.predecessors), -n.id))
        for n in ready:
            resource = OPS[n.equation.operator]
            if used[resource] < limits[resource]:
                assigned[n.id] = t
                remaining.remove(n.id)
                used[resource] += 1
    if remaining:
        raise ValueError(f"No feasible constrained ALAP schedule found for deadline {deadline} using this heuristic")
    return Schedule("constrained-alap", assigned, deadline)


def custom(nodes, limits):
    """Critical-path-first list scheduling (prioritizes long downstream chains)."""
    successors = defaultdict(list)
    for n in nodes:
        for p in n.predecessors:
            successors[p].append(n.id)
    longest = {}
    for n in reversed(nodes):
        longest[n.id] = 1 + max((longest[s] for s in successors[n.id]), default=0)
    return _list_schedule(nodes, limits, lambda n: (-longest[n.id], n.id), mode="custom")


def schedule(nodes, mode, limits=None, deadline=None):
    if mode == "asap":
        return asap(nodes)
    if mode == "alap":
        return alap(nodes, deadline if deadline is not None else asap(nodes).latency)
    if mode in ("constrained-asap", "constrained-alap", "custom"):
        if limits is None:
            raise ValueError(f"{mode} requires resource limits")
        if mode == "constrained-asap":
            return constrained_asap(nodes, limits)
        if mode == "custom":
            return custom(nodes, limits)
        if deadline is None:
            raise ValueError("constrained-alap requires --deadline")
        return _backward_constrained(nodes, limits, deadline)
    raise ValueError(f"Unknown scheduling mode: {mode}")
