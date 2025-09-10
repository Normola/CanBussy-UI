# Local Dependency Management

While Dependabot runs automatically on GitHub, you can manage dependencies locally using several approaches.

## Quick Commands

### Flutter/Dart Dependencies

```bash
# Check for outdated packages
flutter pub outdated

# Preview updates without applying
flutter pub upgrade --dry-run

# Apply safe updates (minor/patch versions)
flutter pub upgrade

# Apply major version updates (breaking changes)
flutter pub upgrade --major-versions

# Get dependency tree
flutter pub deps
```

### Using the Local Script

We've provided a PowerShell script for comprehensive dependency checking:

```powershell
# Preview what would be updated
.\scripts\check-dependencies.ps1 -DryRun

# Apply safe updates automatically
.\scripts\check-dependencies.ps1 -AutoUpdate

# Check for major updates (breaking changes)
.\scripts\check-dependencies.ps1 -MajorUpdates

# Apply all updates including major versions
.\scripts\check-dependencies.ps1 -MajorUpdates -AutoUpdate
```

## Manual Dependency Management

### 1. Flutter/Dart Packages

**Check outdated packages:**
```bash
flutter pub outdated
```

**Update specific package:**
```yaml
# In pubspec.yaml, change version constraint
dependencies:
  file_picker: ^10.3.2  # Update from ^8.3.7
```

Then run:
```bash
flutter pub get
```

### 2. GitHub Actions

**Check for action updates:**
- Visit [GitHub Marketplace](https://github.com/marketplace/actions)
- Search for actions used in `.github/workflows/`
- Update version tags in workflow files

**Current actions to monitor:**
- `actions/checkout`
- `actions/setup-java`
- `subosito/flutter-action`
- `actions/upload-artifact`
- `actions/deploy-pages`

### 3. Android Gradle Dependencies

**Add Gradle Versions Plugin:**

In `android/build.gradle`:
```gradle
plugins {
    id 'com.github.ben-manes.versions' version '0.47.0'
}
```

**Check for updates:**
```bash
cd android
./gradlew dependencyUpdates
```

### 4. iOS CocoaPods

**Update CocoaPods:**
```bash
cd ios
pod update
```

**Check for outdated pods:**
```bash
pod outdated
```

## Automated Local Workflow

### Daily/Weekly Routine

1. **Run dependency check:**
   ```powershell
   .\scripts\check-dependencies.ps1 -DryRun
   ```

2. **Apply safe updates:**
   ```powershell
   .\scripts\check-dependencies.ps1 -AutoUpdate
   ```

3. **Test the application:**
   ```bash
   flutter test
   flutter build apk --debug
   ```

4. **Commit updates:**
   ```bash
   git add .
   git commit -m "deps: update dependencies"
   git push
   ```

### Before Major Releases

1. **Check for major updates:**
   ```powershell
   .\scripts\check-dependencies.ps1 -MajorUpdates
   ```

2. **Review breaking changes:**
   - Check package changelogs
   - Review migration guides
   - Test thoroughly

3. **Apply major updates selectively:**
   ```bash
   flutter pub upgrade --major-versions package_name
   ```

## Integration with Dependabot

### Local vs GitHub Automation

| Aspect | Local Management | Dependabot |
|--------|------------------|------------|
| **Timing** | On-demand | Scheduled |
| **Control** | Full manual control | Automated PRs |
| **Testing** | Immediate local testing | CI/CD testing |
| **Batch Updates** | Custom grouping | Configured groups |
| **Breaking Changes** | Manual review | Automatic detection |

### Best Practice Workflow

1. **Use local tools for:**
   - Quick dependency checks
   - Urgent security updates
   - Development dependencies
   - Testing updates before commits

2. **Let Dependabot handle:**
   - Regular maintenance updates
   - Security patches
   - Consistent update schedule
   - Automated testing via CI/CD

## Troubleshooting

### Common Issues

**Dependency conflicts:**
```bash
flutter pub deps --style=compact
flutter pub downgrade  # If needed
```

**Cache issues:**
```bash
flutter clean
flutter pub cache clean
flutter pub get
```

**Version constraints:**
```bash
# Check what's preventing updates
flutter pub outdated --verbose
```

## Security Considerations

### Vulnerability Scanning

**Check for security advisories:**
```bash
flutter pub audit  # When available
```

**Monitor security databases:**
- [Dart Security Advisories](https://github.com/dart-lang/advisories)
- [Flutter Security](https://flutter.dev/security)
- [Android Security Bulletins](https://source.android.com/security/bulletin)

### Update Priority

1. **Security patches** - Apply immediately
2. **Critical bug fixes** - Apply within 1-2 days  
3. **Feature updates** - Apply weekly/bi-weekly
4. **Major version updates** - Plan and test thoroughly

---

**Note:** While local dependency management gives you immediate control, Dependabot provides consistent automation. Use both approaches complementarily for the best maintenance workflow.
