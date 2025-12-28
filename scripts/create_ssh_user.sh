#!/bin/bash

set -e

# -----------------------------
# Validate input
# -----------------------------
if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <username> '<ssh-public-key>'"
  exit 1
fi

USERNAME="$1"
PUBLIC_KEY="$2"

# -----------------------------
# Ensure script is run as root
# -----------------------------
if [ "$(id -u)" -ne 0 ]; then
  echo "Error: This script must be run as root or with sudo"
  exit 1
fi

# -----------------------------
# Create user if not exists
# -----------------------------
if id "$USERNAME" &>/dev/null; then
  echo "User '$USERNAME' already exists"
else
  useradd -m -s /bin/bash "$USERNAME"
  echo "User '$USERNAME' created"
fi

HOME_DIR="/home/$USERNAME"
SSH_DIR="$HOME_DIR/.ssh"
AUTHORIZED_KEYS="$SSH_DIR/authorized_keys"

# -----------------------------
# Setup SSH directory and key
# -----------------------------
mkdir -p "$SSH_DIR"
echo "$PUBLIC_KEY" > "$AUTHORIZED_KEYS"

# -----------------------------
# Set correct permissions
# -----------------------------
chmod 700 "$SSH_DIR"
chmod 600 "$AUTHORIZED_KEYS"
chown -R "$USERNAME:$USERNAME" "$SSH_DIR"

echo "SSH key installed for user '$USERNAME'"

# -----------------------------
# Optional: Grant sudo access
# Uncomment if required
# -----------------------------
usermod -aG sudo "$USERNAME"
echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/$USERNAME"
chmod 440 "/etc/sudoers.d/$USERNAME"
echo "Passwordless sudo access granted to '$USERNAME'"

echo "User setup completed successfully"
