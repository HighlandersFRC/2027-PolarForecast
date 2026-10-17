import numpy as np
from pymongo import MongoClient

class OPR:
    def __init__(self):
        self.matches = []

    def addMatch(self, match):
        if match.get("comp_level") != "qm":
            return

        if not match.get("score_breakdown"):
            return

        for color in ["red", "blue"]:
            alliance = match["alliances"][color]
            breakdown = match["score_breakdown"][color]

            if alliance.get("score", -1) < 0:
                continue

            self.matches.append({
                "teams": [
                    team.removeprefix("frc")
                    for team in alliance["team_keys"]
                ],
                "auto": breakdown["totalAutoPoints"],
                "teleop": breakdown["totalTeleopPoints"],
                "tower": breakdown["totalTowerPoints"],
                "total": breakdown["totalPoints"]
            })  

    def calculate(self):
        teams = sorted({
            team
            for match in self.matches
            for team in match["teams"]
        })

        if not teams:
            return {}

        team_index = {
            team: i for i, team in enumerate(teams)
        }

        A = np.zeros((len(self.matches), len(teams)))
        Y = np.zeros((len(self.matches), 4))

        for i, match in enumerate(self.matches):
            for team in match["teams"]:
                A[i, team_index[team]] = 1

            Y[i] = [
                match["auto"],
                match["teleop"],
                match["tower"],
                match["total"]
            ]

        coefficients = np.linalg.lstsq(
            A, Y, rcond=None
        )[0]

        results = {}

        for team, i in team_index.items():
            results[team] = {
                "autoOPR": float(coefficients[i][0]),
                "teleopOPR": float(coefficients[i][1]),
                "towerOPR": float(coefficients[i][2]),
                "totalOPR": float(coefficients[i][3])
            }

        return results