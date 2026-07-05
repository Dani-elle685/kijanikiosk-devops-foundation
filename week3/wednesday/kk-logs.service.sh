# /etc/systemd/system/kk-logs.service

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
ExecStart=/usr/bin/node /opt/kijanikiosk/logs/server.js
ExecReload=/bin/kill -HUP $MAINPID
Restart=on-failure
RestartSec=5s
TimeoutStartSec=30s
TimeoutStopSec=30s

# Environment
Environment="NODE_ENV=production"
Environment="PORT=3000"

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

[Install]
WantedBy=multi-user.target

# Reload the daemon
sudo systemctl daemon-reload

# TODO: Enable kk-logs.service 
sudo systemctl enable kk-logs.service




