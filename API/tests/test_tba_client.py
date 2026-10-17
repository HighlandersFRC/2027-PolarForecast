import unittest
from unittest.mock import Mock, patch

import requests

from tba_client import get_tba_json, get_tba_response, parse_tba_json


class TbaClientTests(unittest.TestCase):
    @patch("tba_client.requests.get")
    def test_get_tba_response_builds_url_and_returns_success(self, mock_get):
        response = Mock(status_code=200)
        mock_get.return_value = response

        result = get_tba_response("/event/2026test/matches")

        self.assertIs(result, response)
        mock_get.assert_called_once()
        self.assertTrue(
            mock_get.call_args.args[0].endswith(
                "/api/v3/event/2026test/matches"
            )
        )

    @patch("tba_client.requests.get")
    def test_get_tba_response_logs_http_error_and_returns_none(self, mock_get):
        mock_get.return_value = Mock(
            status_code=503,
            text="temporarily unavailable",
        )

        with self.assertLogs("tba_client", level="ERROR"):
            result = get_tba_response("event/2026test/matches")

        self.assertIsNone(result)

    @patch("tba_client.requests.get")
    def test_get_tba_response_logs_transport_error_and_returns_none(self, mock_get):
        mock_get.side_effect = requests.ConnectionError("offline")

        with self.assertLogs("tba_client", level="ERROR"):
            result = get_tba_response("event/2026test/matches")

        self.assertIsNone(result)

    def test_parse_tba_json_returns_default_for_invalid_json(self):
        response = Mock()
        response.json.side_effect = ValueError("invalid JSON")

        with self.assertLogs("tba_client", level="ERROR"):
            result = parse_tba_json(
                response,
                "event/2026test/matches",
                default=[],
                expected_type=list,
            )

        self.assertEqual(result, [])

    @patch("tba_client.get_tba_response", return_value=None)
    def test_get_tba_json_returns_caller_fallback(self, _mock_response):
        fallback = {"rankings": []}

        result = get_tba_json(
            "event/2026test/rankings",
            default=fallback,
            expected_type=dict,
        )

        self.assertIs(result, fallback)


if __name__ == "__main__":
    unittest.main()
