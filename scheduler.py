
# EC551 Programming Assignment 2
# Basic ASAP and ALAP Scheduler
# Author: Sirena
#
# Interface:
# [
#   {"id": "O1", "expr": "X=A+B",
#    "op": "+", "deps": []}
# ]
#
# Each operation takes one clock cycle.

import heapq


def topological_sort(operations):
    """Validate the DAG and return a valid operation order."""

    if not isinstance(operations, list):
        raise ValueError("Operations must be a list.")

    op_map = {}

    for op in operations:
        if not isinstance(op, dict):
            raise ValueError("Invalid operation format.")

        for key in ("id", "expr", "op", "deps"):
            if key not in op:
                raise ValueError(f"Missing field: {key}")

        op_id = op["id"]

        if not isinstance(op_id, str) or not op_id:
            raise ValueError("Invalid operation ID.")

        if op_id in op_map:
            raise ValueError(f"Duplicate operation ID: {op_id}")

        if op["op"] not in ("+", "-", "*"):
            raise ValueError(f"Invalid operator in {op_id}")

        if not isinstance(op["expr"], str):
            raise ValueError(f"Invalid expression in {op_id}")

        if not isinstance(op["deps"], list):
            raise ValueError(f"Invalid dependencies in {op_id}")

        op_map[op_id] = op

    successors = {op_id: [] for op_id in op_map}
    indegree = {op_id: 0 for op_id in op_map}

    for op_id, op in op_map.items():
        dependencies = op["deps"]

        if len(dependencies) != len(set(dependencies)):
            raise ValueError(f"Duplicate dependency in {op_id}")

        for dep in dependencies:
            if dep not in op_map:
                raise ValueError(f"Unknown dependency: {dep}")

            if dep == op_id:
                raise ValueError(f"Self-dependency in {op_id}")

            successors[dep].append(op_id)
            indegree[op_id] += 1

    ready = [
        op_id for op_id, degree in indegree.items()
        if degree == 0
    ]

    heapq.heapify(ready)
    order = []

    while ready:
        current = heapq.heappop(ready)
        order.append(current)

        for nxt in successors[current]:
            indegree[nxt] -= 1

            if indegree[nxt] == 0:
                heapq.heappush(ready, nxt)

    if len(order) != len(op_map):
        raise ValueError("Cycle detected in DAG.")

    return order, successors


def asap_schedule(operations):
    """Schedule each operation as early as possible."""

    order, _ = topological_sort(operations)
    op_map = {op["id"]: op for op in operations}
    schedule = {}

    for op_id in order:
        deps = op_map[op_id]["deps"]

        if not deps:
            schedule[op_id] = 1
        else:
            schedule[op_id] = max(
                schedule[dep] for dep in deps
            ) + 1

    return schedule


def alap_schedule(operations, latency):
    """Schedule as late as possible within the latency."""

    if type(latency) is not int or latency < 1:
        raise ValueError("Latency must be a positive integer.")

    order, successors = topological_sort(operations)

    asap = asap_schedule(operations)

    if asap and latency < max(asap.values()):
        raise ValueError("Latency is too short for this DAG.")

    schedule = {}

    for op_id in reversed(order):
        next_ops = successors[op_id]

        if not next_ops:
            schedule[op_id] = latency
        else:
            schedule[op_id] = min(
                schedule[nxt] for nxt in next_ops
            ) - 1

    return schedule


def print_schedule(operations, schedule, title):
    """Display operations grouped by clock cycle."""

    op_map = {op["id"]: op for op in operations}

    print(f"\n{title}")

    for cycle in sorted(set(schedule.values())):
        print(f"Cycle {cycle}:")

        for op_id in sorted(schedule):
            if schedule[op_id] == cycle:
                op = op_map[op_id]
                print(
                    f"  {op_id}: {op['expr']} "
                    f"[{op['op']}]"
                )


# Tests run only when executing this file directly.
# Importing scheduler.py will not run these tests.

if __name__ == "__main__":

    # TEST 1: Original DAG
    operations1 = [
        {"id": "O1", "expr": "X=A+B",
         "op": "+", "deps": []},

        {"id": "O2", "expr": "Y=X*B",
         "op": "*", "deps": ["O1"]},

        {"id": "O3", "expr": "Z=X-A",
         "op": "-", "deps": ["O1"]}
    ]

    print("TEST 1: Original DAG")

    print_schedule(
        operations1,
        asap_schedule(operations1),
        "ASAP Scheduling"
    )

    print_schedule(
        operations1,
        alap_schedule(operations1, 4),
        "ALAP Scheduling (4 cycles)"
    )

    # TEST 2: Unordered DAG
    operations2 = [
        {"id": "O3", "expr": "Z=Y-A",
         "op": "-", "deps": ["O2"]},

        {"id": "O1", "expr": "X=A+B",
         "op": "+", "deps": []},

        {"id": "O2", "expr": "Y=X*B",
         "op": "*", "deps": ["O1"]}
    ]

    print("\nTEST 2: Unordered DAG")

    print_schedule(
        operations2,
        asap_schedule(operations2),
        "ASAP Scheduling"
    )

    print_schedule(
        operations2,
        alap_schedule(operations2, 3),
        "ALAP Scheduling (3 cycles)"
    )

    # TEST 3: Invalid latency
    print("\nTEST 3: Invalid Latency")

    try:
        alap_schedule(operations2, 2)
    except ValueError as error:
        print("Expected error:", error)

    # TEST 4: Cycle detection
    print("\nTEST 4: Cycle Detection")

    operations3 = [
        {"id": "O1", "expr": "X=Y+A",
         "op": "+", "deps": ["O2"]},

        {"id": "O2", "expr": "Y=X+B",
         "op": "+", "deps": ["O1"]}
    ]

    try:
        asap_schedule(operations3)
    except ValueError as error:
        print("Expected error:", error)

    # TEST 5: Parallel operations
    print("\nTEST 5: Parallel Operations")

    operations4 = [
        {"id": "O1", "expr": "X=A+B",
         "op": "+", "deps": []},

        {"id": "O2", "expr": "Y=C*D",
         "op": "*", "deps": []},

        {"id": "O3", "expr": "Z=X-Y",
         "op": "-", "deps": ["O1", "O2"]}
    ]

    print_schedule(
        operations4,
        asap_schedule(operations4),
        "ASAP Scheduling"
    )

    # TEST 6: Unknown dependency
    print("\nTEST 6: Unknown Dependency")

    try:
        asap_schedule([
            {"id": "O1", "expr": "X=A+B",
             "op": "+", "deps": ["O9"]}
        ])
    except ValueError as error:
        print("Expected error:", error)

    print("\nAll six tests completed.")
