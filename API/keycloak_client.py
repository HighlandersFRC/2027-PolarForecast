import requests


class KeycloakAdminAuthError(Exception):
    """A safe, actionable description of an admin token request failure."""


def request_keycloak_admin_token(
    *,
    base_url: str,
    realm: str,
    client_id: str,
    username: str,
    password: str,
    client_secret: str = "",
) -> str:
    token_url = (
        f"{base_url.rstrip('/')}/realms/{realm}"
        "/protocol/openid-connect/token"
    )
    form_data = {
        "grant_type": "password",
        "client_id": client_id,
        "username": username,
        "password": password,
    }

 
    if client_secret:
        form_data["client_secret"] = client_secret

    try:
        response = requests.post(
            token_url,
            data=form_data,
            headers={"Content-Type": "application/x-www-form-urlencoded"},
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
        error_description = response_data.get("error_description")

        if error_code == "invalid_client":
            raise KeycloakAdminAuthError(
                f"Keycloak rejected admin client '{client_id}' in realm "
                f"'{realm}'. Verify KEYCLOAK_ADMIN_CLIENT_ID and "
                "KEYCLOAK_MASTER_REALM. If Client authentication is enabled "
                "for that client, set KEYCLOAK_ADMIN_CLIENT_SECRET to its "
                "Credentials-tab secret."
            )

        if error_code == "invalid_grant":
            raise KeycloakAdminAuthError(
                f"Keycloak rejected the admin username/password in realm "
                f"'{realm}'. Verify KEYCLOAK_ADMIN_USERNAME and "
                "KEYCLOAK_ADMIN_PASSWORD."
            )

        reason = error_description or error_code or response.text
        raise KeycloakAdminAuthError(
            f"Keycloak admin login failed with HTTP "
            f"{response.status_code}: {reason}"
        )

    access_token = response_data.get("access_token")
    if not isinstance(access_token, str) or not access_token:
        raise KeycloakAdminAuthError(
            "Keycloak returned a successful admin login response without an "
            "access_token."
        )

    return access_token
