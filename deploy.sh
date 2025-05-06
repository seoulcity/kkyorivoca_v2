#!/bin/bash

# Install Vercel CLI if not installed
if ! command -v vercel &> /dev/null
then
    echo "Installing Vercel CLI..."
    npm install -g vercel
fi

# Login to Vercel if not logged in
echo "Checking Vercel login status..."
vercel whoami > /dev/null 2>&1 || vercel login

# Set environment variables
echo "Setting up environment variables..."
if [ -f .env ]; then
    # Read all environment variables from .env
    source <(grep -v '^#' .env | grep -E 'PG_|VITE_' | sed 's/^/export /')
    echo "Environment variables loaded from .env"
else
    echo "No .env file found. You'll need to set environment variables manually in the Vercel dashboard."
fi

# Build and deploy
echo "Building and deploying to Vercel..."
vercel --prod 