import math
from collections import defaultdict

import numpy as np
import requests

from config import TBA_API_URL, TBA_KEY


HEADERS = {
    "X-TBA-Auth-Key": TBA_KEY,
}

# TBA uses "sf" for the double-elimination playoff bracket
# and "f" for finals. ef/qf remain for compatibility with
# events or seasons that expose those levels.
PREDICTABLE_MATCH_LEVELS = {
    "qm",
    "ef",
    "qf",
    "sf",
    "f",
}

MATCH_LEVEL_ORDER = {
    "qm": 0,
    "ef": 1,
    "qf": 2,
    "sf": 3,
    "f": 4,
}

# Number of qualification matches a team should play before its
# individual OPR is treated as fully established.
TEAM_MATCHES_FOR_FULL_RELIABILITY = 6

# Number of completed qualification matches before the event-wide
# model is considered to have a strong amount of training data.
EVENT_MATCHES_FOR_FULL_RELIABILITY = 20

# The model will never assume its score-margin error is lower than this.
# This prevents unrealistically high confidence percentages.
MINIMUM_MARGIN_ERROR = 10.0

# Used when there is not enough completed data to estimate model error.
DEFAULT_MARGIN_ERROR = 35.0

# Number of folds used when testing the model against completed matches.
CROSS_VALIDATION_FOLDS = 5

# Never report absolute certainty.
MAXIMUM_CONFIDENCE = 99.5


# ----------------------------------------
# FETCH MATCHES
# ----------------------------------------

def get_event_matches(event_key: str) -> list[dict]:
    response = requests.get(
        TBA_API_URL + f"event/{event_key}/matches",
        headers=HEADERS,
        timeout=20,
    )

    if response.status_code != 200:
        raise RuntimeError(
            f"Failed to fetch matches for {event_key}: "
            f"{response.status_code} - {response.text}"
        )

    data = response.json()

    if not isinstance(data, list):
        raise RuntimeError(
            f"TBA returned invalid match data for {event_key}."
        )

    return data


# ----------------------------------------
# MATCH HELPERS
# ----------------------------------------

def team_key_to_number(team_key: str) -> int:
    """
    Convert a TBA team key such as 'frc4499' into 4499.
    """

    normalized_key = str(team_key).strip()

    if normalized_key.startswith("frc"):
        normalized_key = normalized_key[3:]

    return int(normalized_key)


def get_alliance_teams(match: dict, color: str) -> list[int]:
    team_keys = (
        match
        .get("alliances", {})
        .get(color, {})
        .get("team_keys", [])
    )

    teams = []

    for team_key in team_keys:
        if not team_key:
            continue

        try:
            teams.append(team_key_to_number(team_key))
        except (TypeError, ValueError):
            # Ignore malformed team keys instead of breaking
            # prediction generation for the entire event.
            continue

    return teams


def get_alliance_score(
    match: dict,
    color: str,
) -> float | None:
    score = (
        match
        .get("alliances", {})
        .get(color, {})
        .get("score")
    )

    if not isinstance(score, (int, float)):
        return None

    if score < 0:
        return None

    return float(score)


def is_completed_qualification_match(match: dict) -> bool:
    if match.get("comp_level") != "qm":
        return False

    red_score = get_alliance_score(match, "red")
    blue_score = get_alliance_score(match, "blue")

    return red_score is not None and blue_score is not None


def get_completed_qualification_matches(
    matches: list[dict],
) -> list[dict]:
    return sorted(
        [
            match
            for match in matches
            if is_completed_qualification_match(match)
        ],
        key=match_sort_key,
    )


def match_sort_key(match: dict) -> tuple:
    return (
        MATCH_LEVEL_ORDER.get(match.get("comp_level"), 99),
        match.get("set_number", 0) or 0,
        match.get("match_number", 0) or 0,
    )


# ----------------------------------------
# OPR CALCULATION
# ----------------------------------------

def fit_opr_from_completed_matches(
    completed_matches: list[dict],
) -> dict[int, float]:
    """
    Fit OPR values from a list of completed qualification matches.

    Each alliance creates one matrix row, and the alliance's actual
    score becomes the target value for that row.
    """

    teams = set()

    for match in completed_matches:
        teams.update(get_alliance_teams(match, "red"))
        teams.update(get_alliance_teams(match, "blue"))

    sorted_teams = sorted(teams)

    if not sorted_teams:
        return {}

    team_index = {
        team: index
        for index, team in enumerate(sorted_teams)
    }

    rows = []
    scores = []

    for match in completed_matches:
        for color in ("red", "blue"):
            alliance_teams = get_alliance_teams(match, color)
            alliance_score = get_alliance_score(match, color)

            if not alliance_teams or alliance_score is None:
                continue

            row = np.zeros(len(sorted_teams), dtype=float)

            for team in alliance_teams:
                index = team_index.get(team)

                if index is not None:
                    row[index] = 1.0

            rows.append(row)
            scores.append(alliance_score)

    if not rows:
        return {}

    alliance_matrix = np.asarray(rows, dtype=float)
    score_vector = np.asarray(scores, dtype=float)

    try:
        opr_values = np.linalg.lstsq(
            alliance_matrix,
            score_vector,
            rcond=None,
        )[0]
    except np.linalg.LinAlgError as error:
        raise RuntimeError(
            "Unable to calculate OPR because the alliance matrix "
            "could not be solved."
        ) from error

    return {
        team: float(max(0.0, opr_values[index]))
        for team, index in team_index.items()
    }


def calculate_opr(matches: list[dict]) -> dict[int, float]:
    completed_matches = get_completed_qualification_matches(matches)

    return fit_opr_from_completed_matches(completed_matches)


# ----------------------------------------
# MODEL RELIABILITY
# ----------------------------------------

def calculate_team_match_counts(
    completed_matches: list[dict],
) -> dict[int, int]:
    """
    Count the number of completed qualification matches played by each team.
    """

    counts: dict[int, int] = defaultdict(int)

    for match in completed_matches:
        teams_in_match = set(
            get_alliance_teams(match, "red")
            + get_alliance_teams(match, "blue")
        )

        for team in teams_in_match:
            counts[team] += 1

    return dict(counts)


def predict_alliance_score(
    teams: list[int],
    oprs: dict[int, float],
) -> float:
    return sum(
        oprs.get(team, 0.0)
        for team in teams
    )


def append_margin_errors(
    validation_matches: list[dict],
    oprs: dict[int, float],
    errors: list[float],
) -> None:
    """
    Compare predicted score margins against actual score margins.

    Margin is used instead of individual alliance score because the
    winning alliance depends on the difference between the two scores.
    """

    for match in validation_matches:
        red_teams = get_alliance_teams(match, "red")
        blue_teams = get_alliance_teams(match, "blue")

        if not red_teams or not blue_teams:
            continue

        all_teams = red_teams + blue_teams

        # Do not evaluate a held-out match unless every team has an
        # OPR value from the training matches.
        if any(team not in oprs for team in all_teams):
            continue

        actual_red_score = get_alliance_score(match, "red")
        actual_blue_score = get_alliance_score(match, "blue")

        if actual_red_score is None or actual_blue_score is None:
            continue

        predicted_red_score = predict_alliance_score(red_teams, oprs)
        predicted_blue_score = predict_alliance_score(blue_teams, oprs)

        actual_margin = actual_red_score - actual_blue_score
        predicted_margin = predicted_red_score - predicted_blue_score

        errors.append(actual_margin - predicted_margin)


def calculate_average_alliance_score(
    completed_matches: list[dict],
) -> float:
    scores = []

    for match in completed_matches:
        red_score = get_alliance_score(match, "red")
        blue_score = get_alliance_score(match, "blue")

        if red_score is not None:
            scores.append(red_score)

        if blue_score is not None:
            scores.append(blue_score)

    if not scores:
        return 0.0

    return float(np.mean(scores))


def calculate_margin_rmse(
    completed_matches: list[dict],
    final_oprs: dict[int, float],
) -> float:
    """
    Estimate the model's typical score-margin error.

    When enough matches are available, deterministic K-fold cross-validation
    is used. The model is trained without each validation fold, and then its
    predictions are compared against those held-out matches.

    This produces a more honest error estimate than checking the model only
    against matches it was trained on.
    """

    errors: list[float] = []
    completed_count = len(completed_matches)

    if completed_count >= 6:
        fold_count = min(
            CROSS_VALIDATION_FOLDS,
            completed_count,
        )

        for fold_index in range(fold_count):
            training_matches = [
                match
                for index, match in enumerate(completed_matches)
                if index % fold_count != fold_index
            ]

            validation_matches = [
                match
                for index, match in enumerate(completed_matches)
                if index % fold_count == fold_index
            ]

            fold_oprs = fit_opr_from_completed_matches(
                training_matches
            )

            if not fold_oprs:
                continue

            append_margin_errors(
                validation_matches,
                fold_oprs,
                errors,
            )
    else:
        # There are too few matches for useful cross-validation.
        # Use in-sample error but heavily limit confidence through
        # the data-reliability calculation later.
        append_margin_errors(
            completed_matches,
            final_oprs,
            errors,
        )

    average_alliance_score = calculate_average_alliance_score(
        completed_matches
    )

    # Use a score-dependent floor so high-scoring games do not produce
    # unrealistic confidence from a very small estimated error.
    error_floor = max(
        MINIMUM_MARGIN_ERROR,
        average_alliance_score * 0.08,
    )

    if not errors:
        return max(
            DEFAULT_MARGIN_ERROR,
            error_floor,
            average_alliance_score * 0.20,
        )

    rmse = math.sqrt(
        sum(error ** 2 for error in errors)
        / len(errors)
    )

    return max(rmse, error_floor)


def calculate_event_reliability(
    completed_match_count: int,
) -> float:
    return min(
        1.0,
        completed_match_count
        / EVENT_MATCHES_FOR_FULL_RELIABILITY,
    )


def calculate_team_reliability(
    teams: list[int],
    team_match_counts: dict[int, int],
) -> float:
    if not teams:
        return 0.0

    reliability_values = [
        min(
            1.0,
            team_match_counts.get(team, 0)
            / TEAM_MATCHES_FOR_FULL_RELIABILITY,
        )
        for team in teams
    ]

    return sum(reliability_values) / len(reliability_values)


def calculate_data_reliability(
    teams: list[int],
    team_match_counts: dict[int, int],
    completed_match_count: int,
) -> float:
    """
    Combine event-wide and team-specific data reliability.

    The geometric mean prevents one strong value from completely
    hiding a weak value. For example, a late-event match containing a
    replacement team with very little data will receive reduced confidence.
    """

    event_reliability = calculate_event_reliability(
        completed_match_count
    )

    team_reliability = calculate_team_reliability(
        teams,
        team_match_counts,
    )

    return math.sqrt(
        event_reliability * team_reliability
    )


# ----------------------------------------
# CONFIDENCE CALCULATION
# ----------------------------------------

def normal_cdf(value: float) -> float:
    """
    Standard normal cumulative distribution function.

    This avoids requiring scipy.
    """

    return 0.5 * (
        1.0 + math.erf(value / math.sqrt(2.0))
    )


def get_confidence_label(confidence: float) -> str:
    if confidence < 60:
        return "low"

    if confidence < 75:
        return "medium"

    if confidence < 90:
        return "high"

    return "very_high"


def calculate_match_confidence(
    red_score: float,
    blue_score: float,
    margin_rmse: float,
    data_reliability: float,
) -> dict:
    """
    Convert the predicted score margin into win probabilities.

    A larger predicted margin compared with the model's historical error
    produces higher confidence.

    The probability is then pulled back toward 50% when there is not yet
    enough event or team data.
    """

    predicted_margin = red_score - blue_score

    safe_margin_rmse = max(
        margin_rmse,
        MINIMUM_MARGIN_ERROR,
    )

    red_win_probability = normal_cdf(
        predicted_margin / safe_margin_rmse
    )

    # Reduce confidence when limited match data is available.
    adjusted_red_probability = (
        0.5
        + (
            red_win_probability - 0.5
        ) * data_reliability
    )

    minimum_probability = (
        100.0 - MAXIMUM_CONFIDENCE
    ) / 100.0

    maximum_probability = (
        MAXIMUM_CONFIDENCE / 100.0
    )

    adjusted_red_probability = max(
        minimum_probability,
        min(
            maximum_probability,
            adjusted_red_probability,
        ),
    )

    adjusted_blue_probability = (
        1.0 - adjusted_red_probability
    )

    if red_score > blue_score:
        winner_probability = adjusted_red_probability
    elif blue_score > red_score:
        winner_probability = adjusted_blue_probability
    else:
        winner_probability = 0.5

    confidence = round(
        winner_probability * 100.0,
        1,
    )

    return {
        "confidence": confidence,
        "confidence_percentage": confidence,
        "confidence_label": get_confidence_label(confidence),
        "red_win_probability": round(
            adjusted_red_probability * 100.0,
            1,
        ),
        "blue_win_probability": round(
            adjusted_blue_probability * 100.0,
            1,
        ),
        "data_reliability": round(
            data_reliability * 100.0,
            1,
        ),
    }


# ----------------------------------------
# PREDICT MATCHES
# ----------------------------------------

def predict_matches(
    matches: list[dict],
    oprs: dict[int, float],
    team_match_counts: dict[int, int],
    completed_match_count: int,
    margin_rmse: float,
) -> list[dict]:
    predictions = []

    for match in sorted(matches, key=match_sort_key):
        comp_level = match.get("comp_level")

        if comp_level not in PREDICTABLE_MATCH_LEVELS:
            continue

        red_teams = get_alliance_teams(match, "red")
        blue_teams = get_alliance_teams(match, "blue")

        # TBA may create future playoff placeholders before
        # their teams have been determined.
        if not red_teams or not blue_teams:
            continue

        red_score = predict_alliance_score(
            red_teams,
            oprs,
        )

        blue_score = predict_alliance_score(
            blue_teams,
            oprs,
        )

        if red_score > blue_score:
            predicted_winner = "red"
        elif blue_score > red_score:
            predicted_winner = "blue"
        else:
            predicted_winner = "tie"

        all_teams = red_teams + blue_teams

        data_reliability = calculate_data_reliability(
            teams=all_teams,
            team_match_counts=team_match_counts,
            completed_match_count=completed_match_count,
        )

        confidence_data = calculate_match_confidence(
            red_score=red_score,
            blue_score=blue_score,
            margin_rmse=margin_rmse,
            data_reliability=data_reliability,
        )

        predictions.append({
            "key": match.get("key"),
            "comp_level": comp_level,
            "set_number": match.get("set_number", 0) or 0,
            "match_number": match.get("match_number", 0) or 0,

            "red_teams": red_teams,
            "red_score": round(red_score, 2),

            "blue_teams": blue_teams,
            "blue_score": round(blue_score, 2),

            "predicted_winner": predicted_winner,
            "predicted": True,

            # Confidence in whichever alliance was predicted to win.
            "confidence": confidence_data["confidence"],
            "confidence_percentage": confidence_data[
                "confidence_percentage"
            ],
            "confidence_label": confidence_data[
                "confidence_label"
            ],

            # Estimated chance of each alliance winning.
            "red_win_probability": confidence_data[
                "red_win_probability"
            ],
            "blue_win_probability": confidence_data[
                "blue_win_probability"
            ],

            # Indicates how much match history supports this result.
            "data_reliability": confidence_data[
                "data_reliability"
            ],

            # Typical historical error in predicted score margin.
            "model_margin_rmse": round(margin_rmse, 2),
        })

    return predictions


# ----------------------------------------
# TEAM STATS FOR RANKINGS PAGE
# ----------------------------------------

def build_team_stats(
    oprs: dict[int, float],
) -> list[dict]:
    rankings = sorted(
        oprs.items(),
        key=lambda item: item[1],
        reverse=True,
    )

    return [
        {
            "Team": team,
            "Rank": rank,
            "OPR": round(opr, 2),
            "Auto": 0,
            "Teleop": 0,
            "Endgame": 0,
            "Climb": 0,
        }
        for rank, (team, opr) in enumerate(
            rankings,
            start=1,
        )
    ]


# ----------------------------------------
# MAIN PREDICTION FUNCTION
# ----------------------------------------

def predict(
    event_key: str,
    matches: list[dict] | None = None,
) -> dict:
    """
    Generate OPR-based match predictions and confidence percentages.

    Confidence is estimated using:

    1. The difference between the predicted red and blue scores.
    2. The model's cross-validated score-margin error.
    3. The number of completed qualification matches.
    4. The number of completed matches played by the six teams.

    The backend cache updater should pass its already-fetched matches here.
    This prevents stats and predictions from being built from different TBA
    responses and ensures playoff matches from the cache update are included.
    """

    if matches is None:
        matches = get_event_matches(event_key)

    completed_matches = get_completed_qualification_matches(
        matches
    )

    oprs = fit_opr_from_completed_matches(
        completed_matches
    )

    team_match_counts = calculate_team_match_counts(
        completed_matches
    )

    margin_rmse = calculate_margin_rmse(
        completed_matches=completed_matches,
        final_oprs=oprs,
    )

    predictions = predict_matches(
        matches=matches,
        oprs=oprs,
        team_match_counts=team_match_counts,
        completed_match_count=len(completed_matches),
        margin_rmse=margin_rmse,
    )

    average_team_matches = (
        sum(team_match_counts.values())
        / len(team_match_counts)
        if team_match_counts
        else 0.0
    )

    average_team_reliability = (
        sum(
            min(
                1.0,
                matches_played
                / TEAM_MATCHES_FOR_FULL_RELIABILITY,
            )
            for matches_played in team_match_counts.values()
        )
        / len(team_match_counts)
        if team_match_counts
        else 0.0
    )

    event_reliability = calculate_event_reliability(
        len(completed_matches)
    )

    overall_data_reliability = math.sqrt(
        event_reliability
        * average_team_reliability
    )

    return {
        "predictions": predictions,
        "model": {
            "completed_qualification_matches": len(
                completed_matches
            ),
            "teams_with_opr": len(oprs),
            "average_team_matches": round(
                average_team_matches,
                2,
            ),
            "margin_rmse": round(
                margin_rmse,
                2,
            ),
            "data_reliability": round(
                overall_data_reliability * 100.0,
                1,
            ),
            "confidence_method": (
                "Predicted score margin compared with "
                "cross-validated margin error, adjusted for "
                "completed event and team match data."
            ),
        },
    }