# /etc/systemd/system/kk-payment.service

[Unit]
Description=KijaniKiosk Payment Service
Documentation=https://github.com/kijanikiosk/payments/blob/main/README.md
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=kk-payments
Group=kk-payments
WorkingDirectory=/opt/kijanikiosk/payments
ExecStart=/usr/bin/node /opt/kijanikiosk/payments/server.js
ExecReload=/bin/kill -HUP $MAINPID
Restart=on-failure
RestartSec=5s
# TODO: Add two directives that cap restart attempts to 3 within a 60-second window
TimeoutStartSec=30s
TimeoutStopSec=30s

# Environment
# TODO: Add two EnvironmentFile lines pointing to db.env and api.env under /opt/kijanikiosk/config/
Environment="NODE_ENV=production"
Environment="PORT=3001"
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

[Install]
WantedBy=multi-user.target

# Reload the daemon
sudo systemctl daemon-reload

# TODO: Enable kk-payment.service 
sudo systemctl enable kk-payments.service




