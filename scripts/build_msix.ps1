$ErrorActionPreference = "Stop"

Write-Host "Cleaning..."
flutter clean
flutter pub get

Write-Host "Building Windows Release..."
flutter build windows --release

Write-Host "Creating MSIX package..."
flutter pub run msix:create

Write-Host "Done! MSIX package built."
