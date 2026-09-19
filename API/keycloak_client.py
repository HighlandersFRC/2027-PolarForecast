import requests


class KeycloakAdminAuthError(Exception):
    """A safe description of a Keycloak service-account failure."""


def request_keycloak_admin_token(
    *,
    base_url: str,
    realm: str,
    client_id: str,
    client_secret: str,
) -> str:
    token_url = (
        f"{base_url.rstrip('/')}/realms/{realm}"
        "/protocol/openid-connect/token"
    )

    try:
        response = requests.post(
            token_url,
            data={
                "grant_type": "client_credentials",
                "client_id": client_id,
                "client_secret": client_secret,
            },
            timeout=20,
        )
    except requests.RequestException as error:
        raise KeycloakAdminAuthError(
            f"Could not reach Keycloak at {token_url}: {error}"
        ) from error

    try:
        response_data = response.json()
    except ValueError:
        response_data = {}

    if response.status_code != 200:
        error_code = response_data.get("error")
        description = response_data.get("error_description")

        if error_code == "unauthorized_client":
            reason = (
                "Service accounts are probably disabled for this client."
            )
        elif error_code == "invalid_client":
            reason = (
                "The client ID or client secret is incorrect, or client "
                "authentication is disabled."
            )
        else:
            reason = description or error_code or response.text

        raise KeycloakAdminAuthError(
            f"Keycloak service-account login failed with HTTP "
            f"{response.status_code}: {reason}"
        )

    access_token = response_data.get("access_token")

    if not isinstance(access_token, str) or not access_token:
        raise KeycloakAdminAuthError(
            "Keycloak returned a successful response without an access_token."
        )

    return access_token