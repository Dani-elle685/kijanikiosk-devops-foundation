# Integration Challenges

## Challenge A: ProtectSystem=strict vs EnvironmentFile

**Conflict:** `ProtectSystem=strict` could prevent the service from accessing its environment files if they were stored in protected locations.

**Options Considered:**

* Move configuration files to a service-accessible location.
* Add systemd exceptions using `ReadOnlyPaths=` or `ReadWritePaths=`.

**Decision:** Standardized all environment files under `/opt/kijanikiosk/config/` and retained `ProtectSystem=strict`.

**Justification:** The service only required read access to configuration files. Testing confirmed that the selected path remained accessible, preserving both security and functionality without introducing additional exceptions.

---

## Challenge B: Monitoring User and Health Check Permissions

**Conflict:** The provisioning script created `last-provision.json` as root-owned, preventing monitoring users and Amina from reading it.

**Options Considered:**

* Apply ACLs to the health directory.
* Extend the existing `kijanikiosk` group access model.

**Decision:** Created `/opt/kijanikiosk/health` with ownership `kk-logs:kijanikiosk` (750) and `last-provision.json` as `kk-logs:kijanikiosk` (640).

If amina is in `usermod -aG kijanikiosk amina` will definitelly have access.

**Justification:** Reusing the existing group-based model avoided unnecessary ACL complexity while allowing monitoring systems and Amina to access health reports consistently.

---

## Challenge C: logrotate Postrotate vs PrivateTmp

**Conflict:** The standard `systemctl reload kk-logs.service` pattern would fail because `kk-logs.service` did not implement `ExecReload`.

**Options Considered:**

* Add an `ExecReload` directive to the service.
* Use `systemctl reload`.
* Use `systemctl try-restart`.

**Decision:** Replaced reload with `systemctl try-restart kk-logs.service`.

**Justification:** `try-restart` safely restarts the service only when active, reopens log handles after rotation, and avoids failures when reload support is unavailable.

---

## Challenge D: Dirty VM and Package Holds

**Conflict:** Previously installed packages might differ from pinned versions, causing unintended upgrades or downgrades.

There appeared a comflict between the previously installed `nginx version` which was upgraded first before hold happened.

**Options Considered:**

* Automatically upgraded packages to pinned versions.
* Fail and require manual intervention.

**Decision:** Compared installed versions against the pinned versions and terminated the script if a mismatch was detected.

**Justification:** Automatic downgrades/upgrades on an unknown system state can introduce instability and unexpected changes. Failing loudly preserves auditability and ensures administrators consciously resolve configuration drift.

