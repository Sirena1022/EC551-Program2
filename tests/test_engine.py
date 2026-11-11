import unittest
from pathlib import Path
from tempfile import TemporaryDirectory
from parser import parse_equations
from ssa import convert_to_ssa
from dag import build_dag
from scheduler import schedule

LIMITS = {"adders": 1, "subtractors": 1, "multipliers": 1}

class EngineTests(unittest.TestCase):
    def test_parse_and_ssa_reassignment(self):
        with TemporaryDirectory() as d:
            p = Path(d) / "input.txt"
            p.write_text("X=A+B\nX=X+A\nY=X*B\n")
            result = convert_to_ssa(parse_equations(p))
            self.assertEqual([str(e) for e in result.equations], ["X_1 = A + B", "X_2 = X_1 + A", "Y_1 = X_2 * B"])

    def test_dependencies_and_all_modes(self):
        with TemporaryDirectory() as d:
            p = Path(d) / "input.txt"
            p.write_text("X=A+B\nY=X+A\nZ=X-B\nQ=B*Z\n")
            nodes = build_dag(convert_to_ssa(parse_equations(p)).equations)
            self.assertEqual([n.predecessors for n in nodes], [(), (0,), (0,), (2,)])
            for mode in ["asap", "alap", "constrained-asap", "constrained-alap", "custom"]:
                result = schedule(nodes, mode, LIMITS, 5)
                for n in nodes:
                    self.assertTrue(all(result.cycles[p] < result.cycles[n.id] for p in n.predecessors))
                if mode in ("constrained-asap", "constrained-alap", "custom"):
                    for cycle in set(result.cycles.values()):
                        for op, resource in [("+", "adders"), ("-", "subtractors"), ("*", "multipliers")]:
                            self.assertLessEqual(sum(n.equation.operator == op and result.cycles[n.id] == cycle for n in nodes), LIMITS[resource])

    def test_invalid_equation(self):
        with TemporaryDirectory() as d:
            p = Path(d) / "bad.txt"
            p.write_text("X=A/B\n")
            with self.assertRaises(ValueError):
                parse_equations(p)

if __name__ == "__main__":
    unittest.main()
