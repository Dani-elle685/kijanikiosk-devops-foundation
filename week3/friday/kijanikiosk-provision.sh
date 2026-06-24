#!/bin/bash
# kijanikiosk-provision.sh
# Idempotent provisioning for KijaniKiosk application servers.
# Usage: sudo bash kijanikiosk-provision.sh

set -euo pipefail
# -e   exit on any command failure
# -u   unset variables are errors (catches typos like $NIGNX_VERSION)
# -o pipefail   failures inside pipes are visible

readonly NGINX_VERSION="1.24.0-2ubuntu7.12"
readonly NODE_MAJOR_VERSION="20"
readonly APP_GROUP="kijanikiosk"
readonly APP_BASE="/opt/kijanikiosk"

readonly API_PORT=3000
readonly PAYMENTS_PORT=3001
readonly LOGS_PORT=3002

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
  curl gnupg acl ufw logrotate

  # TODO: Download and store the NodeSource GPG key (signed-by pattern) in the trusted keyring directory
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key \
    | sudo gpg --dearmor --yes -o /usr/share/keyrings/nodesource.gpg

  # TODO: Write the NodeSource repo entry referencing NODE_MAJOR_VERSION
    echo "deb [signed-by=/usr/share/keyrings/nodesource.gpg] \
    https://deb.nodesource.com/node_${NODE_MAJOR_VERSION}.x nodistro main" \
    > /etc/apt/sources.list.d/nodesource.list

  # TODO: apt-get update again, then install pinned nginx and nodejs
    apt-get update -qq

    if ! apt-mark showhold | grep -qx nginx; then
        apt-get install -y --no-install-recommends \
            "nginx=${NGINX_VERSION}"
        apt-mark hold nginx
    fi

    if ! apt-mark showhold | grep -qx nodejs; then
        apt-get install -y --no-install-recommends nodejs
        apt-mark hold nodejs
    fi

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
  chown -R kk-api:kk-api "${APP_BASE}/api"
  chmod 750 "${APP_BASE}/api"

  chown -R kk-payments:kk-payments "${APP_BASE}/payments"
  chmod 750 "${APP_BASE}/payments"

  chown -R kk-logs:kk-logs "${APP_BASE}/logs"
  chmod 750 "${APP_BASE}/logs"

  chown root:"${APP_GROUP}" "${APP_BASE}/config"
  chmod 750 "${APP_BASE}/config"
  find "${APP_BASE}/config" -type f -exec chmod 640 {} +

  # TODO: Set permissions (including 2770 for shared/logs)
  chmod 2770 "${APP_BASE}/shared/logs"
  chown kk-logs:kk-logs "${APP_BASE}/shared/logs"

  # TODO: Apply ACLs for kk-api (rwx) on shared/logs
  sudo setfacl -m u:kk-api:rwx "${APP_BASE}/shared/logs"

  # TODO: Apply ACLs for kk-payments (r-x) on shared/logs
  sudo setfacl -m u:kk-payments:r-x "${APP_BASE}/shared/logs"

  # TODO: Apply default ACLs (-d flag) for both accounts so new files inherit them
  sudo setfacl -d -m u:kk-api:rwx "${APP_BASE}/shared/logs"
  sudo setfacl -d -m u:kk-payments:r-x "${APP_BASE}/shared/logs"

  if id amina >/dev/null 2>&1; then
    setfacl -d -m u:amina:r-x "${APP_BASE}/shared/logs"
    setfacl -m u:amina:r-x "${APP_BASE}/shared/logs"
    setfacl -m u:amina:r-x "${APP_BASE}/config"
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

  #kk-api.service -> /etc/systemd/system/kk-api.service
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
        Environment="NODE_ENV=production"
        Environment="PORT=${API_PORT}"
        EnvironmentFile=-/opt/kijanikiosk/config/db.env
        EnvironmentFile=-/opt/kijanikiosk/config/payments-api.env

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
        AmbientCapabilities=

        PrivateDevices=true

        ProtectClock=true
        ProtectHostname=true
        ProtectKernelLogs=true
        ProtectKernelModules=true
        ProtectKernelTunables=true
        ProtectControlGroups=true

        ProtectProc=invisible
        ProcSubset=pid

        RestrictNamespaces=true
        RestrictAddressFamilies=AF_UNIX AF_INET AF_INET6

        RestrictSUIDSGID=true
        RestrictRealtime=true
        LockPersonality=true

        SystemCallFilter=@system-service
        SystemCallArchitectures=native

        RemoveIPC=true

        [Install]
        WantedBy=multi-user.target
EOF

#kk-payments.service.service -> /etc/systemd/system/kk-payments.service
    cat > /etc/systemd/system/kk-payments.service <<'EOF'
        [Unit]
        Description=KijaniKiosk Payment Service
        Documentation=https://github.com/kijanikiosk/payments/blob/main/README.md
        After=network-online.target 
        Wants=network-online.target kk-api.service

        [Service]
        Type=simple
        User=kk-payments
        Group=kk-payments
        WorkingDirectory=/opt/kijanikiosk/payments
        ExecStart=/usr/bin/node /opt/kijanikiosk/payments/processor.py
        ExecReload=/bin/kill -HUP $MAINPID
        Restart=on-failure
        RestartSec=5s
        # TODO: Add two directives that cap restart attempts to 3 within a 60-second window
        TimeoutStartSec=30s
        TimeoutStopSec=30s

        # Environment
        Environment="NODE_ENV=production"
        Environment="PORT=${PAYMENTS_PORT}"
        EnvironmentFile=-/opt/kijanikiosk/config/db.env
        EnvironmentFile=-/opt/kijanikiosk/config/payments-api.env

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

        PrivateDevices=true
        PrivateUsers=true
        PrivateMounts=true

        ProtectClock=true
        ProtectHostname=true
        ProtectKernelLogs=true
        ProtectKernelModules=true
        ProtectKernelTunables=true
        ProtectControlGroups=true

        ProtectProc=invisible
        ProcSubset=pid

        RestrictSUIDSGID=true
        RestrictRealtime=true
        LockPersonality=true
        SystemCallArchitectures=native

        RestrictNamespaces=true
        RestrictAddressFamilies=AF_UNIX AF_INET AF_INET6

        SystemCallFilter=@system-service
        SystemCallFilter=~@clock @cpu-emulation @debug @module \
                        @mount @obsolete @privileged \
                        @raw-io @reboot @resources @swap

        RemoveIPC=true


        [Install]
        WantedBy=multi-user.target
EOF

   #kk-logs.service.service -> /etc/systemd/system/kk-logs.service
    cat > /etc/systemd/system/kk-logs.service <<'EOF'
        [Unit]
        Description=KijaniKiosk Logs Service
        Documentation=https://github.com/kijanikiosk/logs/blob/main/README.md
        After=network-online.target
        Wants=network-online.target

        [Service]
        Type=simple
        User=kk-logs
        Group=kk-logs
        WorkingDirectory=/opt/kijanikiosk/logs
        ExecStart=/usr/bin/node /opt/kijanikiosk/logs/aggregator.py
        ExecReload=/bin/kill -HUP $MAINPID
        Restart=on-failure
        RestartSec=5s
        TimeoutStartSec=30s
        TimeoutStopSec=30s

        # Environment
        Environment="NODE_ENV=production"
        Environment="PORT=${LOGS_PORT}"

        # Logging
        StandardOutput=journal
        StandardError=journal
        SyslogIdentifier=kk-logs

        # Hardening
        NoNewPrivileges=true
        PrivateTmp=true
        ProtectSystem=strict
        ProtectHome=true

        CapabilityBoundingSet=
        AmbientCapabilities=

        PrivateDevices=true

        ProtectClock=true
        ProtectHostname=true
        ProtectKernelLogs=true
        ProtectKernelModules=true
        ProtectKernelTunables=true
        ProtectControlGroups=true

        ProtectProc=invisible
        ProcSubset=pid

        RestrictNamespaces=true
        RestrictAddressFamilies=AF_UNIX AF_INET AF_INET6

        RestrictSUIDSGID=true
        RestrictRealtime=true
        LockPersonality=true

        SystemCallFilter=@system-service
        SystemCallArchitectures=native

        RemoveIPC=true

        [Install]
        WantedBy=multi-user.target
EOF
 
    # Reload the daemon
    sudo systemctl daemon-reload

    # TODO: Enable service 
    for svcaserv in kk-api kk-payments kk-logs; do
        sudo systemctl enable "${svcaserv}.service"
    done

   # TODO: Log success
    success "Provisioned kk-api.service Successfully."

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

provision_logging() {
    log "=== Phase 7: Journal Persistence and Log Rotation ==="

    # Persistent journal
    mkdir -p /var/log/journal
    mkdir -p /etc/systemd/journald.conf.d

    cat > /etc/systemd/journald.conf.d/kijanikiosk.conf <<'CONF'
[Journal]
Storage=persistent
Compress=yes
SystemMaxUse=500M
SystemMaxFileSize=50M
CONF

    systemd-tmpfiles --create --prefix /var/log/journal
    #if ubuntu version doesnt support reload fallback to restart
    if systemctl reload systemd-journald >/dev/null 2>&1; then
        success "Reloaded systemd-journald"
    else
        log "Reload unsupported; restarting systemd-journald"
        systemctl restart systemd-journald
    fi
    success "Persistent journal configured (500MB cap)"

    # logrotate
    cat > /etc/logrotate.d/kijanikiosk <<'ROTATE'
/opt/kijanikiosk/shared/logs/kk-api*.log \
/opt/kijanikiosk/shared/logs/kk-payments*.log \
/opt/kijanikiosk/shared/logs/kk-logs*.log {
    su kk-logs kijanikiosk

    daily
    missingok
    rotate 14
    compress
    delaycompress
    notifempty

    create 640 kk-logs kijanikiosk
    sharedscripts

    postrotate
        systemctl reload kk-api.service 2>/dev/null || true
        systemctl reload kk-payments.service 2>/dev/null || true
        systemctl reload kk-logs.service 2>/dev/null || true
    endscript
}
ROTATE

    # Verification
    logrotate_output=$(logrotate --debug /etc/logrotate.d/kijanikiosk 2>&1)
    if echo "$logrotate_output" | grep -qi '^error:'; then
        echo "$logrotate_output"
        error "logrotate validation failed"
    else
        success "logrotate configuration validated"
    fi

    success "Logging configuration completed"
}


provision_health_checks() {
    log "=== Phase 8: Monitoring Health Checks ==="

    local health_dir="${APP_BASE}/health"
    local health_file="${health_dir}/last-provision.json"

    mkdir -p "${health_dir}"

    # Check service ports.
    # Services may legitimately be down if application code
    # has not yet been deployed.
    local api_status
    local payments_status
    local logs_status

    api_status=$(timeout 2 bash -c "echo >/dev/tcp/localhost/${API_PORT}" 2>/dev/null && echo '"ok"' || echo '"down"')

    payments_status=$(timeout 2 bash -c "echo >/dev/tcp/localhost/${PAYMENTS_PORT}" 2>/dev/null && echo '"ok"' || echo '"down"')

    logs_status=$(timeout 2 bash -c "echo >/dev/tcp/localhost/${LOGS_PORT}" 2>/dev/null && echo '"ok"' || echo '"down"')

    # Structured JSON health report
    printf '{"timestamp":"%s","kk-api":%s,"kk-payments":%s,"kk-logs":%s}\n' "$(date -Is)" \
        "${api_status}" "${payments_status}" "${logs_status}" > "${health_file}"

    # Ownership and permissions
    chown kk-logs:"${APP_GROUP}" "${health_file}"
    chmod 640 "${health_file}"

    # Log the observed state
    success "Health report written to ${health_file}"

    [[ "${api_status}" == '"ok"' ]] \
        && success "kk-api port ${API_PORT} reachable" \
        || log "kk-api port ${API_PORT} not listening (expected if not deployed)"

    [[ "${payments_status}" == '"ok"' ]] \
        && success "kk-payments port ${PAYMENTS_PORT} reachable" \
        || log "kk-payments port ${PAYMENTS_PORT} not listening (expected if not deployed)"

    [[ "${logs_status}" == '"ok"' ]] \
        && success "kk-logs port ${LOGS_PORT} reachable" \
        || log "kk-logs port ${LOGS_PORT} not listening (expected if not deployed)"
}

main() {
  provision_packages
  provision_users
  provision_dirs
  provision_services
  provision_firewall
  verify_state
  provision_logging
  provision_health_checks
  
  success "Provisioning complete. Server is in known state."
}

main "$@"