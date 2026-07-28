import logging
from typing import Any

import requests

from config import TBA_API_URL, TBA_KEY


logger = logging.getLogger(__name__)

DEFAULT_TBA_HEADERS = {
    "X-TBA-Auth-Key": TBA_KEY,
}


def get_tba_response(
    path: str,
    *,
    headers: dict[str, str] | None = None,
    allowed_status_codes: tuple[int, ...] = (200,),
    timeout: int = 20,
) -> requests.Response | None:
    """Fetch a TBA endpoint, logging failures instead of raising them."""

    url = f"{TBA_API_URL.rstrip('/')}/{path.lstrip('/')}"

    try:
        response = requests.get(
            url,
            headers=headers or DEFAULT_TBA_HEADERS,
            timeout=timeout,
        )
    except requests.RequestException:
        logger.exception("TBA request failed for %s", path)
        return None

    if response.status_code not in allowed_status_codes:
        logger.error(
            "TBA request failed for %s: HTTP %s: %s",
            path,
            response.status_code,
            response.text,
        )
        return None

    return response


def parse_tba_json(
    response: requests.Response,
    path: str,
    *,
    default: Any = None,
    expected_type: type | tuple[type, ...] | None = None,
) -> Any:
    """Decode a successful TBA response with a safe fallback."""

    try:
        data = response.json()
    except (requests.JSONDecodeError, ValueError):
        logger.exception("TBA returned invalid JSON for %s", path)
        return default

    if expected_type is not None and not isinstance(data, expected_type):
        logger.error(
            "TBA returned an unexpected data type for %s: expected %s, got %s",
            path,
            expected_type,
            type(data).__name__,
        )
        return default

    return data


def get_tba_json(
    path: str,
    *,
    default: Any = None,
    expected_type: type | tuple[type, ...] | None = None,
    headers: dict[str, str] | None = None,
    timeout: int = 20,
) -> Any:
    """Fetch and decode TBA JSON, returning ``default`` on any failure."""

    response = get_tba_response(
        path,
        headers=headers,
        timeout=timeout,
    )

    if response is None:
        return default

    return parse_tba_json(
        response,
        path,
        default=default,
        expected_type=expected_type,
    )
