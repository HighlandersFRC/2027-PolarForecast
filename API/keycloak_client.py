import requests


class KeycloakAdminAuthError(Exception):
    """A safe description of a Keycloak admin authentication failure."""


def request_keycloak_admin_token(
    *,
    base_url: str,
    realm: str,
    client_id: str,
    auth_mode: str = "auto",
    client_secret: str = "",
    username: str = "",
    password: str = "",
) -> str:
    normalized_mode = auth_mode.strip().lower()
    if normalized_mode == "auto":
        normalized_mode = (
            "client_credentials" if client_secret else "password"
        )

    if normalized_mode not in {"password", "client_credentials"}:
        raise KeycloakAdminAuthError(
            "KEYCLOAK_ADMIN_AUTH_MODE must be password, "
            "client_credentials, or auto."
        )

    if normalized_mode == "password":
        if not username or not password:
            raise KeycloakAdminAuthError(
                "Password authentication requires "
                "KEYCLOAK_ADMIN_USERNAME and KEYCLOAK_ADMIN_PASSWORD."
            )
        request_data = {
            "grant_type": "password",
            "client_id": client_id,
            "username": username,
            "password": password,
        }
        if client_secret:
            request_data["client_secret"] = client_secret
    else:
        if not client_secret:
            raise KeycloakAdminAuthError(
                "Service-account authentication requires "
                "KEYCLOAK_ADMIN_CLIENT_SECRET."
            )
        request_data = {
            "grant_type": "client_credentials",
            "client_id": client_id,
            "client_secret": client_secret,
        }

    token_url = (
        f"{base_url.rstrip('/')}/realms/{realm}"
        "/protocol/openid-connect/token"
    )

    try:
        response = requests.post(
            token_url,
            data=request_data,
            headers={
                "Content-Type": "application/x-www-form-urlencoded",
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

        if error_code == "unauthorized_client" and normalized_mode == "password":
            reason = (
                "Direct access grants are disabled for this client. For "
                "local testing use the master realm and admin-cli client."
            )
        elif error_code == "unauthorized_client":
            reason = "Service accounts are probably disabled for this client."
        elif error_code == "invalid_client":
            reason = (
                "Verify KEYCLOAK_ADMIN_CLIENT_ID and "
                "KEYCLOAK_ADMIN_CLIENT_SECRET."
            )
        elif error_code == "invalid_grant" and normalized_mode == "password":
            reason = (
                "Verify KEYCLOAK_ADMIN_USERNAME and "
                "KEYCLOAK_ADMIN_PASSWORD."
            )
        else:
            reason = description or error_code or response.text

        raise KeycloakAdminAuthError(
            f"Keycloak {normalized_mode} login failed with HTTP "
            f"{response.status_code}: {reason}"
        )

    access_token = response_data.get("access_token")

    if not isinstance(access_token, str) or not access_token:
        raise KeycloakAdminAuthError(
            "Keycloak returned a successful response without an access_token."
        )

    return access_token
