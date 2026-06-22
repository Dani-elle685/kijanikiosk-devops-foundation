Setup: Create the Lab Environment
Run the following setup script on your Ubuntu VM to create the directory and file structure you will be working with. Read through it before running so you understand what state you are inheriting.

#!/bin/bash
# KijaniKiosk Lab Setup Script
# Run as: sudo bash lab-setup.sh

set -e

echo "[+] Creating directory structure..."
mkdir -p /opt/kijanikiosk/{api,payments,logs,config,scripts,shared/logs}

echo "[+] Creating placeholder application files..."
echo "console.log('KijaniKiosk API running as: ' + process.getuid());" \
  > /opt/kijanikiosk/api/server.js
echo "# Payment processor" > /opt/kijanikiosk/payments/processor.py
echo "# Log aggregator" > /opt/kijanikiosk/logs/aggregator.py

echo "[+] Writing sensitive config files..."
cat > /opt/kijanikiosk/config/db.env << 'EOF'
DB_HOST=internal-postgres.kijanikiosk.internal
DB_PORT=5432
DB_NAME=kijanikiosk_prod
DB_USER=kk_app
DB_PASSWORD=s3cr3t-pr0d-p@ssword
EOF

cat > /opt/kijanikiosk/config/payments-api.env << 'EOF'
PAYMENTS_API_KEY=pk_live_AbCdEfGhIjKlMnOpQrStUvWxYz
PAYMENTS_WEBHOOK_SECRET=whsec_XyZaBcDeFgHiJkLmNoPqRsTuV
EOF

echo "[+] Creating deploy script with dangerous permissions..."
cat > /opt/kijanikiosk/scripts/deploy.sh << 'EOF'
#!/bin/bash
echo "Deploying KijaniKiosk..."
EOF
chmod 4777 /opt/kijanikiosk/scripts/deploy.sh

echo "[+] Setting world-readable permissions on config..."
chmod -R 777 /opt/kijanikiosk/config/
chmod -R 777 /opt/kijanikiosk/

echo "[setup complete] Confirm the broken state before proceeding:"
ls -la /opt/kijanikiosk/config/
stat /opt/kijanikiosk/scripts/deploy.sh

-> nano lab-setup.sh ->create file for working space creation
-> sudo bash lab-setup.sh -> run the file to create the working space




# Task 1: Create Service Accounts

sudo useradd \
  --system \
  --no-create-home \
  --home-dir /nonexistent \
  --shell /usr/sbin/nologin \
  --comment "KijaniKiosk API Service" \
  kk-api

sudo useradd \
  --system \
  --no-create-home \
  --home-dir /nonexistent \
  --shell /usr/sbin/nologin \
  --comment "KijaniKiosk API Service" \
  kk-payments

  sudo useradd \
  --system \
  --no-create-home \
  --home-dir /nonexistent \
  --shell /usr/sbin/nologin \
  --comment "KijaniKiosk API Service" \
  kk-logs

  sudo useradd -m kim - creating regular account


 --system assigns a UID below 1000
 --no-create-home prevents home directory creation
 --shell /usr/sbin/nologin blocks interactive login attempts


 sudo groupadd kijanikiosk
 # Add service accounts to their respective groups
sudo usermod -aG kijanikiosk kk-api
sudo usermod -aG kijanikiosk kk-payments
sudo usermod -aG kijanikiosk kk-logs
sudo usermod -aG kijanikiosk kim --> add user to a group

getent group kijanikiosk - check users in group
id kk-api - check suid and guid


# Task 2: Restructure Directory Ownership and Permissions
sudo chown kk-payments:kk-payments /opt/kijanikioskpayments/
sudo chown kk-logs:kk-logs /opt/kijanikiosk/logs/
sudo chgrp kijanikiosk /opt/kijanikiosk/config/
sudo chown kk-logs:kk-logs /opt/kijanikiosk/logs/

sudo chmod 750 /opt/kijanikiosk/{payments,logs,config}
sudo chmod 750 /opt/kijanikiosk/shared/logs/

## use ACLs to grant:
sudo setfacl -m u:kk-api:rwx /opt/kijanikiosk/shared/logs/
getfacl /opt/kijanikiosk/shared/logs/
sudo setfacl -m u:amina:r-x /opt/kijanikiosk/shared/logs/


sudo visudo - to access sudoers file
sudo visudo -f /etc/sudoers.d/kim - to create sudoers file
 
# Task 3: Remediate the SUID Misconfiguration
# Task 4: Write a Restricted Sudoers Policy



# Task 5: Full Audit and Evidence Collection
# 1. Service account verification
echo "=== Service Accounts ===" && id kk-api && id kk-payments && id kk-logs
getent group kijanikiosk

# 2. Directory permissions
echo "=== Directory Structure ===" && ls -la /opt/kijanikiosk/
echo "=== Config Files ===" && ls -la /opt/kijanikiosk/config/
echo "=== Shared Logs ===" && ls -la /opt/kijanikiosk/shared/

# 3. ACL verification
echo "=== ACLs: shared/logs ===" && getfacl /opt/kijanikiosk/shared/logs/
echo "=== ACLs: config ===" && getfacl /opt/kijanikiosk/config/

# 4. SUID scan (should return empty for /opt/kijanikiosk)
echo "=== SUID Files in /opt ===" && find /opt/kijanikiosk -perm /4000 -type f 2>/dev/null
echo "(empty result = PASS)"

# 5. Sudoers verification
echo "=== Sudo Policy for amina ===" && sudo -l -U amina

# 6. Access isolation tests
echo "=== Cross-service isolation ===" 
sudo -u kk-api ls /opt/kijanikiosk/payments/ 2>&1 || echo "PASS: kk-api cannot access payments/"
sudo -u kk-payments ls /opt/kijanikiosk/api/ 2>&1 || echo "PASS: kk-payments cannot access api/"
sudo -u kk-api cat /opt/kijanikiosk/config/db.env && echo "PASS: kk-api can read config"


Results are in audit-report.txt