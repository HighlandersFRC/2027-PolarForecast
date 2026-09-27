import unittest
from unittest.mock import Mock, patch

from keycloak_client import (
    KeycloakAdminAuthError,
    request_keycloak_admin_token,
)


class KeycloakAdminClientTests(unittest.TestCase):
    def _request(self, **overrides):
        arguments = {
            "base_url": "http://keycloak:8080",
            "realm": "master",
            "client_id": "admin-cli",
            "username": "admin",
            "password": "admin",
        }
        arguments.update(overrides)
        return request_keycloak_admin_token(**arguments)

    @patch("keycloak_client.requests.post")
    def test_public_client_does_not_send_an_empty_secret(self, post):
        post.return_value = Mock(
            status_code=200,
            json=Mock(return_value={"access_token": "token"}),
        )

        self.assertEqual(self._request(), "token")
        request_data = post.call_args.kwargs["data"]
        self.assertEqual(request_data["grant_type"], "password")
        self.assertEqual(request_data["username"], "admin")
        self.assertEqual(request_data["password"], "admin")
        self.assertNotIn("client_secret", request_data)

    @patch("keycloak_client.requests.post")
    def test_confidential_client_sends_its_secret(self, post):
        post.return_value = Mock(
            status_code=200,
            json=Mock(return_value={"access_token": "token"}),
        )

        self.assertEqual(
            self._request(
                client_id="api-admin",
                client_secret="correct-secret",
            ),
            "token",
        )
        self.assertEqual(
            post.call_args.kwargs["data"]["client_secret"],
            "correct-secret",
        )
        self.assertEqual(
            post.call_args.kwargs["data"]["grant_type"],
            "client_credentials",
        )
        self.assertNotIn("username", post.call_args.kwargs["data"])
        self.assertNotIn("password", post.call_args.kwargs["data"])

    def test_explicit_service_account_mode_requires_secret(self):
        with self.assertRaisesRegex(
            KeycloakAdminAuthError,
            "KEYCLOAK_ADMIN_CLIENT_SECRET",
        ):
            self._request(
                auth_mode="client_credentials",
                client_id="polarforecast-api",
                client_secret="",
            )

    def test_password_mode_requires_credentials(self):
        with self.assertRaisesRegex(
            KeycloakAdminAuthError,
            "KEYCLOAK_ADMIN_USERNAME",
        ):
            self._request(auth_mode="password", username="", password="")

    @patch("keycloak_client.requests.post")
    def test_invalid_client_error_explains_the_relevant_settings(self, post):
        post.return_value = Mock(
            status_code=401,
            json=Mock(return_value={
                "error": "invalid_client",
                "error_description": "Invalid client credentials",
            }),
        )

        with self.assertRaisesRegex(
            KeycloakAdminAuthError,
            "KEYCLOAK_ADMIN_CLIENT_SECRET",
        ):
            self._request(client_id="api-admin")


if __name__ == "__main__":
    unittest.main()
