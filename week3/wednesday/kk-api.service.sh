# /etc/systemd/system/kk-api.service

[Unit]
Description=KijaniKiosk API Service
Documentation=https://github.com/kijanikiosk/api/blob/main/README.md
After=network-online.target
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

# Reload the daemon
sudo systemctl daemon-reload

# TODO: Enable kk-api.service 
sudo systemctl enable kk-api.service




