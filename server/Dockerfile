# PR 7 will refine this to a multi-stage build using poetry.lock for pinned deps.
# This single-stage build is sufficient for the PR 1 smoke test.
FROM python:3.13-slim

WORKDIR /app

RUN pip install --no-cache-dir poetry && \
    poetry config virtualenvs.create false

COPY pyproject.toml ./
RUN poetry install --no-root --no-interaction --only main

COPY src/ ./src/

RUN groupadd -g 10001 appgroup && \
    useradd -u 10001 -g appgroup -m -s /bin/bash appuser
USER 10001

EXPOSE 3000
CMD ["uvicorn", "src.main:app", "--host", "0.0.0.0", "--port", "3000"]
