# PolarForecast

PolarForecast is a Flutter application with a Python backend. The project uses Docker Compose for its supporting services and includes scripts for running the backend and frontend locally.

## Project Structure

```text
PolarForecast/
├── API/
│   └── run_backend_locally.bat
├── APP/
│   └── run_frontend_locally.bat
├── .env
├── docker-compose.yml
├── requirements.txt
└── ReadMe.md
```

## Prerequisites

Make sure the following tools are installed:

* Docker Desktop
* Python and `pip`
* Flutter SDK
* A terminal such as PowerShell, Command Prompt, or Windows Terminal

Verify the installations with:

```bash
docker --version
python --version
pip --version
flutter --version
```

## Running PolarForecast Locally

### 1. Configure the Environment

Create or update the `.env` file in the project root directory.

```text
PolarForecast/
└── .env
```

Add all required environment variables to this file before starting the project.

### 2. Start the Docker Services

Open a terminal in the root directory of the project:

```bash
cd PolarForecast
```

Start the Docker Compose services:

```bash
docker compose up -d
```

The `-d` option runs the containers in the background.

You can confirm that the containers are running with:

```bash
docker compose ps
```

### 3. Install the Backend Dependencies

From the root directory, install the Python dependencies:

```bash
pip install -r requirements.txt
```

### 4. Start the Backend

Navigate to the `API` directory:

```bash
cd API
```

Run the backend startup script:

```bash
run_backend_locally.bat
```

Keep this terminal open while using the application.

### 5. Install the Flutter Dependencies

Open another terminal and navigate to the `APP` directory from the project root:

```bash
cd PolarForecast\APP
```

Install the Flutter dependencies:

```bash
flutter pub get
```

### 6. Start the Frontend

From the `APP` directory, run:

```bash
run_frontend_locally.bat
```

Keep this terminal open while using the application.

## Startup Command Summary

Run these commands from the project root:

```bash
docker compose up -d
pip install -r requirements.txt
```

Start the backend in one terminal:

```bash
cd API
run_backend_locally.bat
```

Start the frontend in another terminal:

```bash
cd APP
flutter pub get
run_frontend_locally.bat
```

## Stopping the Application

Stop the backend and frontend by pressing:

```text
Ctrl + C
```

inside their respective terminals.

To stop the Docker Compose services, run this command from the project root:

```bash
docker compose down
```

To stop the services and remove their stored Docker volumes, run:

```bash
docker compose down -v
```

> Warning: The `-v` option removes Docker volumes and may delete locally stored database data.

## Restarting the Application

After the initial setup, you usually only need to run:

```bash
docker compose up -d
```

Then start the backend:

```bash
cd API
run_backend_locally.bat
```

In another terminal, start the frontend:

```bash
cd APP
run_frontend_locally.bat
```

Run `pip install -r requirements.txt` again when the Python dependencies change.

Run `flutter pub get` again when the Flutter dependencies in `pubspec.yaml` change.
