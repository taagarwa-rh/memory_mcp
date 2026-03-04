FROM quay.io/sclorg/python-312-c10s:latest as builder

COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

USER root

ENV UV_NATIVE_TLS=true \
    UV_COMPILE_BYTECODE=1 \
    UV_CACHE_DIR=/opt/app-root/src/.cache/uv \
    UV_PROJECT_ENVIRONMENT=/opt/app-root \
    UV_NO_CACHE=1

USER 1001

WORKDIR /opt/app-root/bin

COPY --chown=1001:0 pyproject.toml .python-version ./

COPY --chown=1001:0 uv.lock ./

RUN uv sync --no-install-project --no-editable --no-dev

WORKDIR /opt/app-root/src

COPY --chown=1001:0 . .

RUN uv sync --no-editable --no-dev

EXPOSE 1313

ENTRYPOINT [ "/bin/bash", "-c" ]
