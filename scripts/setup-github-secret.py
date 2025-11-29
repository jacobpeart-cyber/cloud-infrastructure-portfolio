#!/usr/bin/env python3
"""
Script to add AWS_ROLE_ARN secret to GitHub repository.
Requires a GitHub Personal Access Token with 'repo' scope.
"""

import sys
import base64
import json
from nacl import encoding, public
import requests

# Configuration
REPO_OWNER = "jacobpeart-cyber"
REPO_NAME = "cloud-infrastructure-portfolio"
SECRET_NAME = "AWS_ROLE_ARN"
SECRET_VALUE = "arn:aws:iam::298393324887:role/cloud-portfolio-github-actions-role"


def encrypt_secret(public_key: str, secret_value: str) -> str:
    """Encrypt a secret using the repository's public key."""
    public_key_obj = public.PublicKey(public_key.encode("utf-8"), encoding.Base64Encoder())
    sealed_box = public.SealedBox(public_key_obj)
    encrypted = sealed_box.encrypt(secret_value.encode("utf-8"))
    return base64.b64encode(encrypted).decode("utf-8")


def get_public_key(token: str) -> tuple:
    """Get the repository's public key for encrypting secrets."""
    url = f"https://api.github.com/repos/{REPO_OWNER}/{REPO_NAME}/actions/secrets/public-key"
    headers = {
        "Authorization": f"Bearer {token}",
        "Accept": "application/vnd.github+json",
        "X-GitHub-Api-Version": "2022-11-28"
    }

    response = requests.get(url, headers=headers)
    response.raise_for_status()
    data = response.json()
    return data["key"], data["key_id"]


def create_or_update_secret(token: str, encrypted_value: str, key_id: str) -> None:
    """Create or update a repository secret."""
    url = f"https://api.github.com/repos/{REPO_OWNER}/{REPO_NAME}/actions/secrets/{SECRET_NAME}"
    headers = {
        "Authorization": f"Bearer {token}",
        "Accept": "application/vnd.github+json",
        "X-GitHub-Api-Version": "2022-11-28"
    }

    data = {
        "encrypted_value": encrypted_value,
        "key_id": key_id
    }

    response = requests.put(url, headers=headers, json=data)
    response.raise_for_status()


def main():
    """Main function to set up the GitHub secret."""
    print("GitHub Actions Secret Setup")
    print("=" * 50)
    print(f"Repository: {REPO_OWNER}/{REPO_NAME}")
    print(f"Secret Name: {SECRET_NAME}")
    print(f"Secret Value: {SECRET_VALUE}")
    print("=" * 50)
    print()

    # Check if PyNaCl is installed
    try:
        import nacl
    except ImportError:
        print("ERROR: PyNaCl library is not installed.")
        print("Please install it with: pip install PyNaCl")
        print()
        print("Alternative: Add the secret manually via GitHub Web UI:")
        print(f"1. Go to: https://github.com/{REPO_OWNER}/{REPO_NAME}/settings/secrets/actions")
        print(f"2. Click 'New repository secret'")
        print(f"3. Name: {SECRET_NAME}")
        print(f"4. Value: {SECRET_VALUE}")
        print(f"5. Click 'Add secret'")
        sys.exit(1)

    # Get GitHub token from environment or prompt
    import os
    token = os.environ.get("GITHUB_TOKEN")

    if not token:
        print("GitHub Personal Access Token required.")
        print()
        print("To create a token:")
        print("1. Go to: https://github.com/settings/tokens/new")
        print("2. Note: 'Terraform CI/CD Setup'")
        print("3. Expiration: Choose appropriate duration")
        print("4. Select scopes: 'repo' (all repo permissions)")
        print("5. Click 'Generate token'")
        print("6. Copy the token")
        print()
        token = input("Enter your GitHub Personal Access Token: ").strip()

    if not token:
        print("ERROR: No token provided.")
        sys.exit(1)

    try:
        # Get repository public key
        print("Fetching repository public key...")
        public_key, key_id = get_public_key(token)

        # Encrypt the secret
        print("Encrypting secret value...")
        encrypted_value = encrypt_secret(public_key, SECRET_VALUE)

        # Create/update the secret
        print(f"Setting secret '{SECRET_NAME}'...")
        create_or_update_secret(token, encrypted_value, key_id)

        print()
        print("✓ Secret successfully added to GitHub repository!")
        print()
        print("Next steps:")
        print("1. Create 'production' environment in GitHub (optional)")
        print("2. Test the workflow by making a change and pushing")

    except requests.exceptions.HTTPError as e:
        print(f"ERROR: HTTP {e.response.status_code}")
        print(f"Response: {e.response.text}")
        sys.exit(1)
    except Exception as e:
        print(f"ERROR: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
