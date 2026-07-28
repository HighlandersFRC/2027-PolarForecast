import unittest

import numpy as np

from LinReg import (
    _calculate_scouting_fuel_contribution,
    linreg,
    solve_opr,
)


class ScoutingFuelContributionTests(unittest.TestCase):
    def test_complete_fuel_values_are_combined(self):
        self.assertEqual(_calculate_scouting_fuel_contribution(2.5, 4.0), 6.5)

    def test_genuine_zero_values_produce_zero_contribution(self):
        self.assertEqual(_calculate_scouting_fuel_contribution(0.0, 0.0), 0.0)

    def test_missing_both_phases_produces_none(self):
        self.assertIsNone(_calculate_scouting_fuel_contribution(None, None))

    def test_missing_either_phase_produces_none(self):
        self.assertIsNone(_calculate_scouting_fuel_contribution(3.0, None))
        self.assertIsNone(_calculate_scouting_fuel_contribution(None, 7.0))


class CombinedOprTests(unittest.TestCase):
    def setUp(self):
        self.matches = [{
            "key": "2026test_qm1",
            "comp_level": "qm",
            "set_number": 1,
            "match_number": 1,
            "actual_time": 1,
            "alliances": [
                {
                    "teams": [1],
                    "score": 15.0,
                    "auto": 5.0,
                    "teleop": 10.0,
                    "endgame": 0.0,
                    "climb": 0.0,
                    "auto_fuel": 2.0,
                    "teleop_fuel": 3.0,
                },
                {
                    "teams": [2],
                    "score": 30.0,
                    "auto": 10.0,
                    "teleop": 20.0,
                    "endgame": 0.0,
                    "climb": 0.0,
                    "auto_fuel": 4.0,
                    "teleop_fuel": 6.0,
                },
            ],
        }]
        self.scouting = [
            self._scouting_record(team=1, auto_fuel=6, teleop_fuel=4),
            self._scouting_record(team=2, auto_fuel=1, teleop_fuel=4),
        ]

    @staticmethod
    def _scouting_record(team, auto_fuel, teleop_fuel):
        return {
            "event": "2026test",
            "match": "1",
            "team": team,
            "data": {
                "autoScouting": {"fuel_scored": auto_fuel},
                "teleopScouting": {"fuel_scored": teleop_fuel},
                "misc": {},
            },
        }

    def _calculate(self, scouting):
        return {
            row["Team"]: row
            for row in linreg(
                TBAdata=self.matches,
                Scoutdata=scouting,
                matches=self.matches,
                rankings_data={"rankings": []},
            )
        }

    def test_standard_opr_uses_matrix_least_squares(self):
        matrix = np.asarray([
            [1.0, 1.0, 0.0],
            [0.0, 1.0, 1.0],
            [1.0, 0.0, 1.0],
        ])
        scores = np.asarray([30.0, 40.0, 50.0])

        np.testing.assert_allclose(
            solve_opr(matrix, scores),
            np.asarray([20.0, 10.0, 30.0]),
        )

    def test_group_scouting_enters_combined_least_squares_system(self):
        results = self._calculate(self.scouting)

        self.assertEqual(results[1]["TBAOPR"], 15.0)
        self.assertEqual(results[1]["TBAFuelOPR"], 5.0)
        self.assertEqual(results[1]["CombinedFuelOPR"], 8.5)
        self.assertEqual(results[1]["OPR"], 18.5)
        self.assertEqual(results[2]["TBAOPR"], 30.0)
        self.assertEqual(results[2]["CombinedFuelOPR"], 6.5)
        self.assertEqual(results[2]["OPR"], 26.5)
        self.assertEqual(
            results[1]["OPRMethod"],
            "weighted_least_squares_tba_and_group_scouting",
        )

    def test_no_scouting_uses_standard_tba_opr(self):
        results = self._calculate([])

        self.assertEqual(results[1]["OPR"], 15.0)
        self.assertEqual(results[2]["OPR"], 30.0)
        self.assertEqual(results[1]["OPRMethod"], "least_squares_tba")

    def test_incomplete_scouting_is_not_added_as_zero(self):
        incomplete = [self._scouting_record(1, auto_fuel=6, teleop_fuel=None)]
        results = self._calculate(incomplete)

        self.assertEqual(results[1]["OPR"], 15.0)
        self.assertEqual(results[1]["ScoutingFuelObservations"], 0)
        self.assertEqual(results[1]["OPRMethod"], "least_squares_tba")


if __name__ == "__main__":
    unittest.main()
