# Keycloak Auth Server

This project includes a local Keycloak auth server for development.

## What It Runs

- Keycloak URL: `http://localhost:8000`
- Admin console: `http://localhost:8000/admin`
- Admin username: `admin`
- Admin password: `admin`
- Realm: `polarforecast-web`
- App client ID: `polarforecast-app`
- Demo user: `demo`
- Demo user password: `demo`

The Keycloak container listens on port `8080` internally, and Docker maps it to port `8000` on your machine.

## Requirements

Install Docker Desktop, then make sure it is running.

## Start Keycloak

From the project root:

```powershell
docker compose up --build
```

Open:

```text
http://localhost:8000
```

Then go to the admin console:

```text
http://localhost:8000/admin
```

## Stop Keycloak

Press `Ctrl+C` in the terminal running Docker Compose, then run:

```powershell
docker compose down
```

## Reset Everything

For a disposable local environment, this deletes all saved Keycloak **and
MongoDB** data, then re-imports the default realm:

```powershell
docker compose down -v
docker compose up --build
```

## Change Admin Login

You can override the admin username and password when starting Keycloak:

```powershell
$env:KEYCLOAK_ADMIN_USERNAME="myadmin"
$env:KEYCLOAK_ADMIN_PASSWORD="change-me"
docker compose up --build
```

## OIDC Values For Your App

Use these values when wiring your app to Keycloak:

```text
Issuer: http://localhost:8000/realms/polarforecast-web
Authorization endpoint: http://localhost:8000/realms/polarforecast-web/protocol/openid-connect/auth
Token endpoint: http://localhost:8000/realms/polarforecast-web/protocol/openid-connect/token
JWKS endpoint: http://localhost:8000/realms/polarforecast-web/protocol/openid-connect/certs
Client ID: polarforecast-app
PKCE: S256
```

The `polarforecast-app` client is public and configured for local development redirects from `localhost` and `127.0.0.1`.

## API Admin Client

The API supports two admin authentication modes. The secret is used only by the
Python API and must never be placed in an `APP_*` variable or compiled into the
Flutter web app.

### Local/testing: username and password

The local Keycloak bootstrap admin can authenticate through the public
`admin-cli` client in the `master` realm. No client secret is needed:

```dotenv
KEYCLOAK_ADMIN_AUTH_MODE=password
KEYCLOAK_ADMIN_REALM=master
KEYCLOAK_ADMIN_CLIENT_ID=admin-cli
KEYCLOAK_ADMIN_USERNAME=admin
KEYCLOAK_ADMIN_PASSWORD=admin
KEYCLOAK_ADMIN_CLIENT_SECRET=
```

### Deployed web environment: service-account secret

Production should use the confidential `polarforecast-api` client in the
application realm. Enable **Client authentication** and **Service accounts
roles**, grant its service account the required `realm-management` roles, and
copy the Credentials-tab secret into the server environment:

```dotenv
KEYCLOAK_ADMIN_AUTH_MODE=client_credentials
KEYCLOAK_ADMIN_REALM=polarforecast-web
KEYCLOAK_ADMIN_CLIENT_ID=polarforecast-api
KEYCLOAK_ADMIN_CLIENT_SECRET=replace-with-the-deployment-secret
KEYCLOAK_ADMIN_USERNAME=
KEYCLOAK_ADMIN_PASSWORD=
```

`KEYCLOAK_ADMIN_AUTH_MODE=auto` is also supported. It selects
`client_credentials` when a client secret is present and `password` otherwise.
Explicitly setting the mode is recommended for deployments.

An incorrect client ID, realm, or secret causes Keycloak's `invalid_client`
response. Incorrect local credentials cause `invalid_grant`.

Changes to bootstrap credentials only affect a new Keycloak database. For a
disposable local environment that has stale client/admin settings, use the
**Reset Everything** commands above to recreate it from the checked-in realm.

