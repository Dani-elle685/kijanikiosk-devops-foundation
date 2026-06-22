#!/bin/bash
# kijanikiosk-provision.sh
# Idempotent provisioning for KijaniKiosk application servers.
# Usage: sudo bash kijanikiosk-provision.sh

set -euo pipefail
# -e   exit on any command failure
# -u   unset variables are errors (catches typos like $NIGNX_VERSION)
# -o pipefail   failures inside pipes are visible

readonly NGINX_VERSION="1.24.0-1ubuntu2"
readonly NODE_MAJOR_VERSION="20"
readonly APP_GROUP="kijanikiosk"
readonly APP_BASE="/opt/kijanikiosk"

log()     { echo "[$(date +%FT%T)] INFO  $*"; }
success() { echo "[$(date +%FT%T)] OK    $*"; }
error()   { echo "[$(date +%FT%T)] ERROR $*" >&2; exit 1; }

#Refuse to run without root and refuse to run on non-Ubuntu systems
[[ $EUID -ne 0 ]] && error "Must run as root or with sudo"
grep -qi ubuntu /etc/os-release || error "Designed for Ubuntu only"

log "Starting KijaniKiosk provisioning..."

provision_packages() {
  log "=== Phase 1: Package Installation ==="
  # TODO: apt-get update
  apt-get update

  # TODO: Install prerequisite packages (non-interactive, no recommended packages)
  DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
  curl gnupg acl ufw

  # TODO: Download and store the NodeSource GPG key (signed-by pattern) in the trusted keyring directory
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key \
    | sudo gpg --dearmor --yes -o /usr/share/keyrings/nodesource.gpg

  # TODO: Write the NodeSource repo entry referencing NODE_MAJOR_VERSION
    echo "deb [signed-by=/usr/share/keyrings/nodesource.gpg] \
    https://deb.nodesource.com/node_${NODE_MAJOR_VERSION}.x nodistro main" \
    > /etc/apt/sources.list.d/nodesource.list

  # TODO: apt-get update again, then install pinned nginx and nodejs
    apt-get update -qq

    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      nginx="${NGINX_VERSION}" \
      nodejs

  # TODO: Hold nginx and nodejs
    apt-mark hold nginx nodejs

  # TODO: Log installed versions as success
    success "Installed nginx $(nginx -v 2>&1 | cut -d/ -f2) \
    and Node $(node --version)"
}


provision_users() {
  log "=== Phase 2: Service Accounts ==="
  # TODO: Create kijanikiosk group (idempotent)
  getent group "${APP_GROUP}" >/dev/null 2>&1 || groupadd --system "${APP_GROUP}"

  # TODO: Loop over kk-api, kk-payments, kk-logs
  #         - Create as system account with nologin shell if absent
  #         - Add to APP_GROUP regardless (usermod -aG is safe to run multiple times)

    #   id kk-api &> /dev/null || useradd --system --no-create-home --shell /usr/sbin/nologin kk-api
    #   id kk-payments &> /dev/null || useradd --system --no-create-home --shell /usr/sbin/nologin kk-payments
    #   id kk-logs &> /dev/null || useradd --system --no-create-home --shell /usr/sbin/nologin kk-logs
    #   usermod -aG "${APP_GROUP}" kk-api
    #   usermod -aG "${APP_GROUP}" kk-payments
    #   usermod -aG "${APP_GROUP}" kk-logs

  for svcacct in kk-api kk-payments kk-logs; do
        id "${svcacct}" &> /dev/null || useradd --system --no-create-home --shell /usr/sbin/nologin "${svcacct}"

        usermod -aG "${APP_GROUP}" "${svcacct}"
  done
 
  # TODO: Add amina to the group if her account exists (handle missing account gracefully)
  if id amina >/dev/null 2>&1; then
        usermod -aG "${APP_GROUP}" amina
  fi

  # TODO: Log success
  success "Provisioned ${APP_GROUP} group and service accounts"
}


provision_dirs() {
  log "=== Phase 3: Directory Structure ==="
  # TODO: Create all directories with mkdir -p
  mkdir -p "${APP_BASE}"/{api,payments,logs,config,scripts,shared/logs}

  # TODO: Set ownership for each directory
  chown -R kk-api:kk-api "${APP_BASE}/api
  chmod 750 "${APP_BASE}/api

  chown -R kk-payments:kk-payments "${APP_BASE}/payments
  chmod 750 "${APP_BASE}/payments

  chown -R kk-logs:kk-logs "${APP_BASE}/logs
  chmod 750 "${APP_BASE}/logs

  chown root:"${APP_GROUP}" "${APP_BASE}/config
  chmod 750 "${APP_BASE}/config"
  find "${APP_BASE}/config" -type f -exec chmod 640 {} +

  # TODO: Set permissions (including 2770 for shared/logs)
  chmod 2770 "${APP_BASE}/shared/logs
  chown kk-logs:kk-logs "${APP_BASE}/shared/logs

  # TODO: Apply ACLs for kk-api (rwx) on shared/logs
  sudo setfacl -m u:kk-api:rwx "${APP_BASE}/shared/logs

  # TODO: Apply ACLs for kk-payments (r-x) on shared/logs
  sudo setfacl -m u:kk-payments:r-x "${APP_BASE}/shared/logs

  # TODO: Apply default ACLs (-d flag) for both accounts so new files inherit them
  sudo setfacl -d -m u:kk-api:rwx "${APP_BASE}/shared/logs
  sudo setfacl -d -m u:kk-payments:r-x "${APP_BASE}/shared/logs

  if id amina >/dev/null 2>&1; then
    sudo setfacl -d -m u:amina:r-x "${APP_BASE}/shared/logs
    sudo setfacl -m u:amina:r-- "${APP_BASE}/shared/logs
    sudo setfacl -m u:amina:r-- "${APP_BASE}/config
  fi
  # TODO: Log success
  success "Provisioned directory ownership, permissions, and ACLs"
}

provision_services() {
  log "=== Phase 4: systemd Unit Files ==="
  # TODO: Write /etc/systemd/system/kk-api.service using a heredoc
  #       Include: [Unit] with After= and Wants= dependencies
  #                [Service] with User, Group, WorkingDirectory, ExecStart
  #                Restart policy (on-failure, RestartSec, StartLimitBurst, StartLimitIntervalSec)
  #                EnvironmentFile lines, StandardOutput/StandardError, SyslogIdentifier
  #                All five hardening directives from Page 3
  #                [Install] WantedBy=multi-user.target
  # TODO: Run systemctl daemon-reload
  # TODO: Enable kk-api.service (do not start — application code may not be deployed yet)
  # TODO: Log success
  # /etc/systemd/system/kk-api.service

    cat > /etc/systemd/system/kk-api.service <<'EOF'
        [Unit]
        Description=KijaniKiosk API Service
        Documentation=https://github.com/kijanikiosk/api/blob/main/README.md
        After=network-online.target kk-payments.service
        Wants=network-online.target
        # TODO: Add the ordering dependency so this service starts after kk-payments.service

        [Service]
        Type=simple
        User=kk-api
        Group=kk-api
        WorkingDirectory=/opt/kijanikiosk/api
        ExecStart=/usr/bin/node /opt/kijanikiosk/api/server.js
        ExecReload=/bin/kill -HUP $MAINPID
        Restart=on-failure
        RestartSec=5s
        # TODO: Add two directives that cap restart attempts to 3 within a 60-second window
        TimeoutStartSec=30s
        TimeoutStopSec=30s

        # Environment
        # TODO: Add two EnvironmentFile lines pointing to db.env and api.env under /opt/kijanikiosk/config/
        Environment="NODE_ENV=production"
        Environment="PORT=3000"
        EnvironmentFile=-/opt/kijanikiosk/config/db.env
        EnvironmentFile=-/opt/kijanikiosk/config/api.env

        # Logging
        StandardOutput=journal
        StandardError=journal
        SyslogIdentifier=kk-api

        # Hardening

        NoNewPrivileges=true
        PrivateTmp=true
        ProtectSystem=strict
        ProtectHome=true
        CapabilityBoundingSet=

        [Install]
        WantedBy=multi-user.target
EOF
 
    # Reload the daemon
    sudo systemctl daemon-reload

    # TODO: Enable kk-api.service 
    sudo systemctl enable kk-api.service

   # TODO: Log success
    success "Provisioned kk-api.service Successfully."

}

provision_firewall() {
  log "=== Phase 5: Firewall Configuration ==="
  # Your implementation here.
  # Hint: ufw --force reset; ufw default deny incoming; ...
  # Critical: always allow 22 BEFORE enabling ufw
  #Reset ufw to a clean state (but handle the case where ufw is not yet installed)
  
  #Set default policy: deny incoming, allow outgoing
  #Allow SSH (port 22) — must do this before enabling ufw or you will lock yourself out
  #Allow HTTP (port 80)
  #Enable ufw non-interactively (--force flag)
  #Verify the resulting ruleset
}

provision_firewall() {
    log "=== Phase 5: Firewall Configuration ==="
    # Hint: ufw --force reset; ufw default deny incoming; ... 
    # Critical: always allow 22 BEFORE enabling ufw 
    #Reset ufw to a clean state (but handle the case where ufw is not yet installed) 
    #Set default policy: deny incoming, allow outgoing 
    #Allow SSH (port 22) — must do this before enabling ufw or you will lock yourself out 
    #Allow HTTP (port 80) 
    #Enable ufw non-interactively (--force flag) 
    #Verify the resulting ruleset
    # Ensure UFW exists before attempting configuration
    command -v ufw >/dev/null 2>&1 || error "ufw is not installed"
    # Start from a known state
    sudo ufw --force reset
    # Default policies
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    # Always allow SSH first
    sudo ufw allow 22/tcp
    # Allow HTTP traffic
    sudo ufw allow 80/tcp
    # Enable non-interactively
    sudo ufw --force enable
    # Verify resulting ruleset
    if sudo ufw status | grep -q "Status: active"; then
        success "UFW enabled successfully"
    else
        error "UFW failed to activate"
    fi
    log "Current firewall rules:"
    sudo ufw status verbose

    success "Firewall configuration completed"
}

verify_state() {
    log "=== Phase 6: Post-Provisioning Verification ==="
    local failed=0

  # TODO: Check kk-api, kk-payments and kk-logs accounts
  # TODO: Check all expected directories
  # TODO: SUID scan on APP_BASE
  # TODO: Check nginx and nodejs are held
  # TODO: Check kk-api.service is enabled
  # TODO: Exit: success if failed=0, error if failed>0 (include count in message)

    # Service accounts
    for user in kk-api kk-payments kk-logs; do
        if id "${user}" >/dev/null 2>&1; then
            success "Account exists: ${user}"
        else
            echo "[$(date +%FT%T)] FAIL  Account missing: ${user}"
            ((failed++))
        fi
    done

    # Expected directories
    for dir in api payments logs config scripts shared/logs
    do
        if [[ -d "${APP_BASE}/${dir}" ]]; then
            success "Directory exists: ${APP_BASE}/${dir}"
        else
            echo "[$(date +%FT%T)] FAIL  Missing directory: ${APP_BASE}/${dir}"
            ((failed++))
        fi
    done

    # SUID scan
    if find "${APP_BASE}" -perm /4000 -print -quit | grep -q .; then
        echo "[$(date +%FT%T)] FAIL  SUID files found under ${APP_BASE}"
        find "${APP_BASE}" -perm /4000
        ((failed++))
    else
        success "No SUID files found under ${APP_BASE}"
    fi

    # Package holds
    if apt-mark showhold | grep -qx nginx; then
        success "nginx package hold active"
    else
        echo "[$(date +%FT%T)] FAIL  nginx package not held"
        ((failed++))
    fi

    if apt-mark showhold | grep -qx nodejs; then
        success "nodejs package hold active"
    else
        echo "[$(date +%FT%T)] FAIL  nodejs package not held"
        ((failed++))
    fi

    # Service enablement
    if systemctl is-enabled kk-api.service >/dev/null 2>&1; then
        success "kk-api.service enabled"
    else
        echo "[$(date +%FT%T)] FAIL  kk-api.service not enabled"
        ((failed++))
    fi

    # Final result
    if (( failed == 0 )); then
        success "Verification completed successfully"
    else
        error "Verification failed with ${failed} error(s)"
    fi
}

main() {
  provision_packages
  provision_users
  provision_dirs
  provision_services
  provision_firewall
  verify_state
  success "Provisioning complete. Server is in known state."
}

main "$@"