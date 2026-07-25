# Keycloak Auth Server

This project includes a local Keycloak auth server for development.

## What It Runs

- Keycloak URL: `http://localhost:8000`
- Admin console: `http://localhost:8000/admin`
- Admin username: `admin`
- Admin password: `admin`
- Realm: `polarforecast`
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

If you want to delete all saved Keycloak data and re-import the default realm:

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
Issuer: http://localhost:8000/realms/polarforecast
Authorization endpoint: http://localhost:8000/realms/polarforecast/protocol/openid-connect/auth
Token endpoint: http://localhost:8000/realms/polarforecast/protocol/openid-connect/token
JWKS endpoint: http://localhost:8000/realms/polarforecast/protocol/openid-connect/certs
Client ID: polarforecast-app
PKCE: S256
```

The `polarforecast-app` client is public and configured for local development redirects from `localhost` and `127.0.0.1`.

