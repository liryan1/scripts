#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

if [ -z "$1" ]; then
    echo "Usage: $0 <project-name>"
    exit 1
fi

PROJECT_NAME=$1
# Convert hyphens to underscores for the python package name
PKG_NAME=$(echo "$PROJECT_NAME" | tr '-' '_')

echo "🚀 Scaffolding project: $PROJECT_NAME (Package: $PKG_NAME)..."

# 1. Create Directories
mkdir -p "$PROJECT_NAME/src/$PKG_NAME"
mkdir -p "$PROJECT_NAME/tests"

cd "$PROJECT_NAME"

# 2. Create pyproject.toml
cat <<EOF > pyproject.toml
[project]
name = "$PROJECT_NAME"
version = "0.1.0"
description = "Production-ready python service"
readme = "README.md"
requires-python = ">=3.14"
dependencies = []

[project.scripts]
start = "$PKG_NAME.main:main"

[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"

# --- Tool Configuration ---

[tool.ruff]
line-length = 88
target-version = "py314"

[tool.ruff.lint]
select = ["E", "F", "I", "UP"]
ignore = []

[tool.pytest.ini_options]
addopts = "-ra -q"
testpaths = ["tests"]
pythonpath = ["src"]
EOF

# 3. Create .gitignore
cat <<EOF > .gitignore
__pycache__/
*.py[cod]
.venv/
.pytest_cache/
.ruff_cache/
.coverage
dist/
.env
EOF

# 4. Create Makefile
cat <<EOF > Makefile
.PHONY: install format lint test run clean

install:
	uv sync

format:
	uv run ruff format .

lint:
	uv run ruff check . --fix

test:
	uv run pytest tests/

run:
	uv run python src/$PKG_NAME/main.py

clean:
	rm -rf .venv .pytest_cache .ruff_cache __pycache__ dist
EOF

# 5. Create Dockerfile
# cat <<EOF > Dockerfile
# # Stage 1: Builder
# FROM python:3.14-slim AS builder
# WORKDIR /app
# COPY --from=ghcr.io/astral-sh/uv:latest /uv /bin/uv
# COPY pyproject.toml uv.lock ./
# RUN uv sync --frozen --no-dev --compile-bytecode
# COPY src/ src/

# # Stage 2: Runner
# FROM python:3.14-slim
# WORKDIR /app
# COPY --from=builder /app/.venv /app/.venv
# COPY --from=builder /app/src /app/src
# ENV PATH="/app/.venv/bin:\$PATH"
# RUN useradd -m appuser
# USER appuser
# CMD ["python", "-m", "$PKG_NAME.main"]
# EOF

# 6. Create Source Code
cat <<EOF > src/$PKG_NAME/__init__.py
# Expose key components here
EOF

cat <<EOF > src/$PKG_NAME/main.py
import sys

def main():
    print("Hello from $PROJECT_NAME!")
    print(f"Python version: {sys.version}")

if __name__ == "__main__":
    main()
EOF

# 7. Create Tests
cat <<EOF > tests/test_main.py
from $PKG_NAME.main import main


def test_imports():
    assert main is not None
EOF

cat <<EOF > README.md
# $PROJECT_NAME

## Setup

1. Install [uv](https://github.com/astral-sh/uv).
2. Run \`make install\`.

## Commands

- \`make run\`: Run the application.
- \`make test\`: Run tests.
- \`make lint\`: Lint and fix code style.
EOF

# 7.1 Add vs code config
mkdir -p .vscode
cat <<EOF > .vscode/settings.json
{
  "python.defaultInterpreterPath": "${workspaceFolder}/.venv/bin/python",
  "python.analysis.typeCheckingMode": "basic",
  "python.analysis.autoImportCompletions": true,
  "python.analysis.extraPaths": ["${workspaceFolder}/src"],
  "[python]": {
    "editor.defaultFormatter": "charliermarsh.ruff",
    "editor.formatOnSave": true,
    "editor.codeActionsOnSave": {
      "source.fixAll": "explicit",
      "source.organizeImports": "explicit"
    }
  }
}
EOF

cat <<EOF > .vscode/extensions.json
{
  "recommendations": [
    "charliermarsh.ruff",
    "ms-python.python"
  ]
}
EOF

# 8. Initialize Environment & Git
echo "📦 Installing dependencies with uv..."
uv add --dev ruff pytest
uv sync

echo "git init..."
git init -q
git add .
git commit -m "Initial commit" -q

echo ""
echo "✅ Project $PROJECT_NAME created successfully!"
echo "👉 cd $PROJECT_NAME"
echo "👉 make run"
