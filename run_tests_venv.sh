#!/usr/bin/env bash
set -e

PROJECT_ROOT="/home/void/prj/animesync"
VENV_DIR="$HOME/.venvs/venv-animesync"

cd "$PROJECT_ROOT/server"

# Kill any existing backend
pkill -f "python.*app.main" 2>/dev/null || true

# Remove old venv if exists
if [ -d "$VENV_DIR" ]; then
  echo "Removing existing venv at $VENV_DIR"
  rm -rf "$VENV_DIR"
fi

# Create virtual environment in ~/.venvs
mkdir -p "$HOME/.venvs"
python -m venv "$VENV_DIR"

# Upgrade pip and install dependencies
"$VENV_DIR/bin/pip" install --upgrade pip
"$VENV_DIR/bin/pip" install -r "$PROJECT_ROOT/requirements.txt"

# Start backend
echo "Starting backend with venv python..."
"$VENV_DIR/bin/python" -m app.main > /tmp/animesync_backend_venv.log 2>&1 &
SERVER_PID=$!
echo "Backend PID: $SERVER_PID"

# Wait for health (max 15s)
ready=0
for i in {1..15}; do
  if curl -s http://localhost:8000/api/health | grep -q 'running'; then
    echo "Backend ready"
    ready=1
    break
  fi
  sleep 1
done
if [ $ready -ne 1 ]; then
  echo "Backend failed to start after 15s"
  kill $SERVER_PID 2>/dev/null || true
  exit 1
fi

# Run tests
cd "$PROJECT_ROOT"
echo "Running pytest with venv..."
"$VENV_DIR/bin/pytest" tests/ -v --tb=short

# Stop backend
kill $SERVER_PID 2>/dev/null || true
echo "Backend stopped"