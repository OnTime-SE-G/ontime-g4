#!/usr/bin/env bash
# =============================================================================
# install-istio.sh
# Epic-02 Security — Issue: Istio 1.20 STRICT mTLS
# =============================================================================
# Usage:
#   ./install-istio.sh            # full install + rollout
#   ./install-istio.sh verify     # run acceptance checks only
#   ./install-istio.sh kiali      # open Kiali dashboard
# =============================================================================
set -euo pipefail

ISTIO_VERSION="1.20.8"
ISTIO_DIR="/tmp/istio-${ISTIO_VERSION}"
MANIFESTS_DIR="$(cd "$(dirname "$0")" && pwd)/k8s"

# All transit-* namespaces that need sidecar injection.
# Order matters: restart data-plane namespaces before platform so Kong keeps
# working last (Kong's Envoy proxy interacts with Kong's data plane traffic).
NAMESPACES=(
  transit-edge
  transit-streaming
  transit-intelligence
  transit-ui
  transit-data
  transit-platform
)

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
info()    { echo -e "${CYAN}[INFO]${NC}  $*"; }
success() { echo -e "${GREEN}[OK]${NC}    $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $*"; }
fail()    { echo -e "${RED}[FAIL]${NC}  $*"; }

# ─── helpers ──────────────────────────────────────────────────────────────────

wait_for_pods() {
  local ns="$1"
  info "Waiting for all pods in '${ns}' to be ready (timeout 3 min)..."
  kubectl wait pods --all -n "${ns}" \
    --for=condition=Ready \
    --timeout=180s 2>/dev/null || {
      warn "Some pods in ${ns} not ready after 3 min — check manually."
    }
}

count_sidecars() {
  # Returns number of pods that have 2/2 containers (app + istio-proxy)
  local ns="$1"
  kubectl get pods -n "${ns}" \
    --no-headers \
    -o custom-columns="READY:.status.containerStatuses[*].ready" 2>/dev/null \
    | grep -c "true,true" || true
}

# ─── sub-commands ─────────────────────────────────────────────────────────────

install_istioctl() {
  if command -v istioctl &>/dev/null; then
    local ver; ver=$(istioctl version --short 2>/dev/null | head -1 || true)
    if [[ "$ver" == *"${ISTIO_VERSION}"* ]]; then
      success "istioctl ${ISTIO_VERSION} already installed."
      return
    fi
  fi

  info "Downloading istioctl ${ISTIO_VERSION}..."
  local arch; arch=$(uname -m)
  local os;   os=$(uname -s | tr '[:upper:]' '[:lower:]')
  [[ "$arch" == "x86_64" ]] && arch="amd64"
  [[ "$arch" == "aarch64" ]] && arch="arm64"

  local url="https://github.com/istio/istio/releases/download/${ISTIO_VERSION}/istio-${ISTIO_VERSION}-${os}-${arch}.tar.gz"
  curl -sSL "$url" | tar -xz -C /tmp
  sudo install -m 755 "${ISTIO_DIR}/bin/istioctl" /usr/local/bin/istioctl
  success "istioctl installed → $(istioctl version --short 2>/dev/null | head -1)"
}

install_istio_control_plane() {
  info "Installing Istio ${ISTIO_VERSION} with 'default' profile..."
  # default profile: istiod + istio-ingressgateway (we won't use the gateway
  # itself — Kong is the ingress — but istiod is required for cert management)
  istioctl install \
    --set profile=default \
    --set meshConfig.defaultConfig.holdApplicationUntilProxyStarts=true \
    --set meshConfig.accessLogFile=/dev/stdout \
    -y

  info "Waiting for istiod to be ready..."
  kubectl rollout status deployment/istiod -n istio-system --timeout=180s
  success "Istio control plane ready."
}

label_namespaces() {
  info "Labelling transit-* namespaces for automatic sidecar injection..."
  for ns in "${NAMESPACES[@]}"; do
    if kubectl get namespace "${ns}" &>/dev/null; then
      kubectl label namespace "${ns}" istio-injection=enabled --overwrite
      success "  ${ns} → istio-injection=enabled"
    else
      warn "  ${ns} does not exist yet — skipping (label it when you create it)"
    fi
  done
}

apply_mtls_policies() {
  info "Applying mesh-wide STRICT PeerAuthentication + DestinationRules..."
  kubectl apply -f "${MANIFESTS_DIR}/peer-authentication-strict.yaml"
  kubectl apply -f "${MANIFESTS_DIR}/destination-rules-mtls.yaml"
  success "mTLS policies applied."
}

deploy_kiali() {
  info "Deploying Kiali dashboard..."
  kubectl apply -f "${MANIFESTS_DIR}/kiali.yaml"
  kubectl rollout status deployment/kiali -n istio-system --timeout=120s
  success "Kiali deployed."
}

rolling_restart_namespaces() {
  info "Rolling restart of all pods to inject Envoy sidecars..."
  echo ""
  for ns in "${NAMESPACES[@]}"; do
    if ! kubectl get namespace "${ns}" &>/dev/null; then
      warn "  Skipping ${ns} (namespace not found)"
      continue
    fi

    info "  Restarting workloads in ${ns}..."

    # Restart Deployments
    local deployments
    deployments=$(kubectl get deployments -n "${ns}" -o name 2>/dev/null || true)
    for d in $deployments; do
      kubectl rollout restart "${d}" -n "${ns}"
    done

    # Restart StatefulSets (Keycloak, PostgreSQL live here)
    local statefulsets
    statefulsets=$(kubectl get statefulsets -n "${ns}" -o name 2>/dev/null || true)
    for s in $statefulsets; do
      kubectl rollout restart "${s}" -n "${ns}"
    done

    # Restart DaemonSets
    local daemonsets
    daemonsets=$(kubectl get daemonsets -n "${ns}" -o name 2>/dev/null || true)
    for ds in $daemonsets; do
      kubectl rollout restart "${ds}" -n "${ns}"
    done

    wait_for_pods "${ns}"

    local sidecar_count
    sidecar_count=$(count_sidecars "${ns}")
    success "  ${ns}: ${sidecar_count} pods with 2/2 containers (app + istio-proxy)"
    echo ""
  done
}

# ─── acceptance criteria verification ─────────────────────────────────────────

verify() {
  echo ""
  echo -e "${CYAN}════════════════════════════════════════════════════════${NC}"
  echo -e "${CYAN}  Acceptance Criteria Verification                      ${NC}"
  echo -e "${CYAN}════════════════════════════════════════════════════════${NC}"
  echo ""
  local pass=0 fail=0

  # AC-1: istioctl verify-install
  echo -e "[ AC-1 ] istioctl verify-install"
  if istioctl verify-install &>/dev/null; then
    success "  istioctl verify-install: no errors"
    ((pass++))
  else
    fail "  istioctl verify-install reported errors — run manually for details"
    ((fail++))
  fi

  # AC-2: All pods 2/2 per namespace
  echo -e "\n[ AC-2 ] Pods show 2/2 containers (app + istio-proxy)"
  for ns in "${NAMESPACES[@]}"; do
    if ! kubectl get namespace "${ns}" &>/dev/null; then
      warn "  ${ns}: namespace not found — skipping"
      continue
    fi
    local total
    total=$(kubectl get pods -n "${ns}" --no-headers 2>/dev/null | wc -l)
    local sidecars
    sidecars=$(count_sidecars "${ns}")
    if [[ "$total" -gt 0 && "$sidecars" -eq "$total" ]]; then
      success "  ${ns}: ${sidecars}/${total} pods have sidecar ✓"
      ((pass++))
    else
      fail "  ${ns}: only ${sidecars}/${total} pods have sidecar"
      ((fail++))
    fi
  done

  # AC-3: Non-sidecar pod cannot reach a svc in a transit-* namespace
  echo -e "\n[ AC-3 ] Non-sidecar pod cannot reach transit-platform services"
  echo "  Launching test pod in 'default' namespace (no injection)..."
  local test_pod="mtls-rejection-test"
  kubectl run "${test_pod}" \
    --image=curlimages/curl:8.5.0 \
    --restart=Never \
    --namespace=default \
    --labels="sidecar.istio.io/inject=false" \
    --command -- sleep 30 &>/dev/null || true
  sleep 5

  local http_code
  http_code=$(kubectl exec "${test_pod}" -n default -- \
    curl -s -o /dev/null -w "%{http_code}" \
    --max-time 5 \
    http://kong-proxy.transit-platform.svc.cluster.local:80/health \
    2>/dev/null || echo "000")
  kubectl delete pod "${test_pod}" -n default --ignore-not-found &>/dev/null

  if [[ "$http_code" == "000" || "$http_code" == "56" ]]; then
    success "  Connection from non-sidecar pod refused (HTTP ${http_code}) ✓"
    ((pass++))
  else
    fail "  Non-sidecar pod got HTTP ${http_code} — STRICT mTLS may not be blocking plaintext"
    ((fail++))
  fi

  # AC-4: PeerAuthentication is STRICT
  echo -e "\n[ AC-4 ] Mesh-wide PeerAuthentication mode=STRICT"
  local pa_mode
  pa_mode=$(kubectl get peerauthentication mesh-wide-strict-mtls \
    -n istio-system \
    -o jsonpath='{.spec.mtls.mode}' 2>/dev/null || echo "NOT_FOUND")
  if [[ "$pa_mode" == "STRICT" ]]; then
    success "  PeerAuthentication mesh-wide-strict-mtls mode=STRICT ✓"
    ((pass++))
  else
    fail "  PeerAuthentication mode=${pa_mode} (expected STRICT)"
    ((fail++))
  fi

  # AC-5: Kiali running
  echo -e "\n[ AC-5 ] Kiali dashboard reachable"
  local kiali_ready
  kiali_ready=$(kubectl get pods -n istio-system -l app=kiali \
    --no-headers 2>/dev/null | grep Running | wc -l)
  if [[ "$kiali_ready" -ge 1 ]]; then
    success "  Kiali pod running ✓"
    success "  Access: kubectl port-forward svc/kiali 20001:20001 -n istio-system"
    success "          then open http://localhost:20001/kiali"
    ((pass++))
  else
    fail "  Kiali pod not running"
    ((fail++))
  fi

  echo ""
  echo -e "${CYAN}════════════════════════════════════════════════════════${NC}"
  echo -e "  Results: ${GREEN}${pass} passed${NC} / ${RED}${fail} failed${NC}"
  echo -e "${CYAN}════════════════════════════════════════════════════════${NC}"
  echo ""
  [[ $fail -eq 0 ]]
}

open_kiali() {
  info "Opening Kiali dashboard..."
  echo "  URL: http://localhost:20001/kiali"
  echo "  Press Ctrl+C to stop the port-forward."
  kubectl port-forward svc/kiali 20001:20001 -n istio-system
}

# ─── entry point ──────────────────────────────────────────────────────────────

case "${1:-install}" in
  install)
    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║  ontime-g4 / epic-02-security                        ║${NC}"
    echo -e "${CYAN}║  Istio ${ISTIO_VERSION} — STRICT mTLS Installation          ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════╝${NC}"
    echo ""
    install_istioctl
    install_istio_control_plane
    label_namespaces
    apply_mtls_policies
    deploy_kiali
    rolling_restart_namespaces
    verify
    ;;
  verify)
    verify
    ;;
  kiali)
    open_kiali
    ;;
  *)
    echo "Usage: $0 [install|verify|kiali]"
    exit 1
    ;;
esac