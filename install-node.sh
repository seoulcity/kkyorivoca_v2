#!/bin/bash

# Install nvm (Node Version Manager)
echo "Installing nvm..."
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash

# Source nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# Install Node.js 20 LTS
echo "Installing Node.js 20 LTS..."
nvm install 20

# Use Node.js 20 as default
nvm alias default 20
nvm use 20

# Verify installation
node -v
npm -v

echo "Installation complete! Please restart your terminal or run:"
echo "source ~/.bashrc"
echo "or"
echo "source ~/.zshrc"
echo "Then run 'nvm use 20' to use Node.js 20" 