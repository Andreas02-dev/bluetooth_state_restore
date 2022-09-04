# Introduction
As `Ubuntu 22.04` does not restore the bluetooth state on the `Dell XPS 13 Plus (9320)` by default as it does for Wi-Fi, create a `systemd service` to store the state on shutdown and restore the state on startup.

# Setup

- Clone the repo or download the files.
- Make the script executable using `chmod +x setup_bluetooth_state_restore_service.sh`.

# Usage

- Installation: `./setup_bluetooth_state_restore_service.sh --install`.
- Removal: `./setup_bluetooth_state_restore_service.sh --uninstall`.
- Help: `./setup_bluetooth_state_restore_service.sh --help`.

# Improvements / suggestions?

Feel free to open a GitHub Issue and/or a PR.