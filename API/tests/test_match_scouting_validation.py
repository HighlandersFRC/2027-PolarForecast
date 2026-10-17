import unittest

from pydantic import ValidationError

from models.match_scouting import AutoScouting, TeleopScouting


class MatchScoutingValidationTests(unittest.TestCase):
    def test_auto_fuel_accepts_limit(self):
        self.assertEqual(AutoScouting(fuel_scored=300).fuel_scored, 300)

    def test_auto_fuel_rejects_outlier(self):
        with self.assertRaises(ValidationError):
            AutoScouting(fuel_scored=301)

    def test_fuel_cannot_be_negative(self):
        with self.assertRaises(ValidationError):
            AutoScouting(fuel_scored=-1)
        with self.assertRaises(ValidationError):
            TeleopScouting(fuel_scored=-1)


if __name__ == "__main__":
    unittest.main()
