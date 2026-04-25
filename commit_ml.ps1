$ErrorActionPreference = "Stop"

# Try to checkout mihai branch, create it if it doesn't exist
git checkout mihai
if ($LASTEXITCODE -ne 0) {
    git checkout -b mihai
}

# Add only the modified files from the ML integration
git add backend/services/fixture_service.py
git add backend/services/xi_service.py
git add lib/data/models/match_preview.dart
git add lib/features/dashboard/presentation/dashboard_screen.dart
git add lib/features/team/presentation/match_preview_screen.dart

# Commit the changes
git commit -m "feat: integrate starting XI predictor and opponent stats into dashboard"

# Push to origin
git push -u origin mihai

Write-Host "Successfully committed and pushed the ML integration changes to branch 'mihai'."
