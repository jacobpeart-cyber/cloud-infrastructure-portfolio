@echo off
REM Batch script to add AWS_ROLE_ARN secret to GitHub repository
REM This opens the GitHub settings page where you can manually add the secret

echo ============================================================
echo GitHub Actions Secret Setup
echo ============================================================
echo.
echo Repository: jacobpeart-cyber/cloud-infrastructure-portfolio
echo Secret Name: AWS_ROLE_ARN
echo Secret Value: arn:aws:iam::298393324887:role/cloud-portfolio-github-actions-role
echo.
echo ============================================================
echo.
echo Opening GitHub repository secrets page...
echo.
start https://github.com/jacobpeart-cyber/cloud-infrastructure-portfolio/settings/secrets/actions/new
echo.
echo Instructions:
echo 1. The GitHub secrets page should open in your browser
echo 2. In the "Name" field, enter: AWS_ROLE_ARN
echo 3. In the "Secret" field, paste: arn:aws:iam::298393324887:role/cloud-portfolio-github-actions-role
echo 4. Click "Add secret"
echo.
echo Press any key to copy the secret value to your clipboard...
pause >nul
echo arn:aws:iam::298393324887:role/cloud-portfolio-github-actions-role | clip
echo.
echo ✓ Secret value copied to clipboard!
echo   You can now paste it into the GitHub secrets page.
echo.
pause
