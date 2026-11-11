"""EC551 Program 2: front-end arithmetic HLS scheduling CLI."""
import argparse
import json
from pathlib import Path
from parser import parse_equations
from ssa import convert_to_ssa, export_ssa
from dag import build_dag
from scheduler import schedule, OPS


def main():
    cli = argparse.ArgumentParser(description="EC551 arithmetic HLS front end")
    cli.add_argument("input", nargs="?", default="equations.txt")
    cli.add_argument("--mode", choices=["asap", "alap", "constrained-asap", "constrained-alap", "custom"], default="asap")
    cli.add_argument("--adders", type=int, default=1)
    cli.add_argument("--subtractors", type=int, default=1)
    cli.add_argument("--multipliers", type=int, default=1)
    cli.add_argument("--deadline", type=int)
    cli.add_argument("--export-ssa", nargs="?", const="ssa_output.txt", metavar="PATH")
    cli.add_argument("--output", default="schedule.json")
    args = cli.parse_args()

    equations = parse_equations(args.input)
    result = convert_to_ssa(equations)
    if args.export_ssa:
        export_ssa(result, args.export_ssa)
    nodes = build_dag(result.equations)
    limits = {"adders": args.adders, "subtractors": args.subtractors, "multipliers": args.multipliers}
    plan = schedule(nodes, args.mode, limits, args.deadline)
    data = {
        "mode": plan.mode,
        "latency_cycles": plan.latency,
        "inputs": result.inputs,
        "final_versions": result.final_versions,
        "resource_limits": limits if args.mode in ("constrained-asap", "constrained-alap", "custom") else None,
        "operations": [{"id": n.id, "target": n.equation.target, "left": n.equation.left,
                        "operator": n.equation.operator, "right": n.equation.right,
                        "predecessors": list(n.predecessors), "cycle": plan.cycles[n.id],
                        "unit": OPS[n.equation.operator]} for n in nodes]
    }
    Path(args.output).write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
    print(f"Mode: {plan.mode} | Latency: {plan.latency} cycles")
    for n in sorted(nodes, key=lambda n: (plan.cycles[n.id], n.id)):
        print(f"  Cycle {plan.cycles[n.id]}: {n.equation}")
    print(f"Wrote {args.output}")


if __name__ == "__main__":
    main()
