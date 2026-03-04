default_version := `uv version --short`
project_name := "memory_mcp"

_default:
    @ just --list --unsorted --justfile {{ justfile() }}

# Runs recipes for MR approval
pre-mr: format lint test

# Formats code
[group("Dev")]
format:
    uv run ruff check --select I --fix src tests 
    uv run ruff format src tests 

# Lints code
[group("Dev")]
lint *options:
    uv run ruff check src tests  {{ options }}

# Tests code
[group("Dev")]
test *options:
    uv run pytest -s tests/ {{ options }}

# Increments the code version
[group("Dev")]
bump type:
    uv run bump2version --current-version={{ default_version }} {{ type }}
    uv lock

# Builds the image
[group("Dev")]
build-image tag="latest":
    podman build -t {{ project_name }}:latest -f Containerfile .

# Runs the container
[group("Testing")]
test-container: (build-image "latest")
    - podman run --rm --name {{ project_name }} -it {{ project_name }}:latest /bin/sh

# Runs the webapp in a container
[group("Testing")]
test-container-webapp: (build-image "latest")
    - podman run --rm --name {{ project_name }} -p 8501:8501 {{ project_name }}:latest

# Runs the webapp locally
[group("Testing")]
test-webapp-local:
    uv run streamlit run webapp/intro.py

# Builds the Sphinx documentation
[group("Docs")]
build-docs *options:
    uv run sphinx-build docs/source docs/build {{ options }}

# Applys kubernetes manifests via Kustomize
[group("Deploy")]
oc-deploy env: && (inner-oc-deploy "{{ env }}")
    @ echo "Who: {{ MAGENTA }} $(oc whoami) {{ NORMAL }}"
    @ echo "Where: {{ MAGENTA }} $(oc project) {{ NORMAL }}"

# Shows diff between kubernetes manifests and whats deployed
[group("Deploy")]
oc-check-diff env:
    KUBECTL_EXTERNAL_DIFF="diff --color -u" oc diff -k oc-templates/overlays/{{ env }}

[private]
[confirm("Are you sure you want to deploy?")]
inner-oc-deploy env:
    @ echo "{{ RED }} ----- DEPLOYING ----- {{ NORMAL }}"
    oc apply -k oc-templates/overlays/{{ env }}
