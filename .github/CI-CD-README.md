# CanBussy UI - CI/CD Documentation

## GitHub Actions Workflows

This repository includes comprehensive GitHub Actions workflows for continuous integration and deployment.

### 🔄 Main CI/CD Pipeline (`ci-cd.yml`)

**Triggers:**
- Push to `main` or `develop` branches
- Pull requests to `main`

**Jobs:**
1. **Test** - Runs tests, formatting checks, and code analysis
2. **Build Android** - Creates release APK for Android
3. **Build Windows** - Creates Windows desktop application
4. **Build Web** - Creates web application
5. **Security Scan** - Checks for dependency vulnerabilities
6. **Deploy Staging** - Deploys to staging environment (on `develop` branch)
7. **Create Release** - Creates GitHub release with artifacts (on `main` branch)

### 🔍 Pull Request Checks (`pr-checks.yml`)

**Triggers:**
- Pull requests to `main` or `develop`

**Jobs:**
1. **Code Quality** - Format, analyze, and test code
2. **Build Check** - Verify Android and Web builds work
3. **Dependency Check** - Check for outdated dependencies
4. **Size Check** - Ensure APK size is reasonable (<50MB)

### 📦 Dependency Updates (`dependency-updates.yml`)

**Triggers:**
- Scheduled: Every Monday at 9 AM UTC
- Manual trigger via GitHub UI

**Jobs:**
1. **Update Dependencies** - Automatically updates Flutter dependencies
2. **Check Flutter Version** - Checks for newer Flutter versions

### 🌐 GitHub Pages Deployment (`deploy-pages.yml`)

**Triggers:**
- Push to `main` branch
- Manual trigger via GitHub UI

**Jobs:**
1. **Build and Deploy** - Builds web app and deploys to GitHub Pages

## 🚀 Getting Started

### Prerequisites

1. **Enable GitHub Pages** in your repository settings:
   - Go to Settings → Pages
   - Set Source to "GitHub Actions"

2. **Set up branch protection** (recommended):
   - Go to Settings → Branches
   - Add rule for `main` branch
   - Require status checks to pass before merging
   - Require up-to-date branches before merging

### Workflow Features

#### ✅ Automated Testing
- Runs all Flutter tests with coverage
- Uploads coverage reports to Codecov
- Checks code formatting with `dart format`
- Performs static analysis with `flutter analyze`

#### 📱 Multi-Platform Builds
- **Android**: Builds release APK
- **Windows**: Builds desktop application
- **Web**: Builds progressive web app

#### 🔒 Security & Quality
- Dependency vulnerability scanning
- Code quality checks
- APK size monitoring
- Automated dependency updates

#### 🎯 Deployment
- **Staging**: Automatic deployment on develop branch
- **Production**: Manual approval for main branch deployments
- **GitHub Pages**: Automatic web app deployment

## 📋 Status Badges

Add these badges to your main README:

```markdown
![CI/CD Pipeline](https://github.com/Normola/CanBussy-UI/workflows/CI/CD%20Pipeline/badge.svg)
![Pull Request Checks](https://github.com/Normola/CanBussy-UI/workflows/Pull%20Request%20Checks/badge.svg)
![Deploy to GitHub Pages](https://github.com/Normola/CanBussy-UI/workflows/Deploy%20to%20GitHub%20Pages/badge.svg)
```

## 🔧 Configuration

### Environment Variables

You may need to set these secrets in your repository settings:

- `GITHUB_TOKEN` - Automatically provided by GitHub
- Additional secrets for staging/production deployments (if needed)

### Customization

#### Changing Flutter Version
Update the `flutter-version` in all workflow files:
```yaml
- name: Setup Flutter
  uses: subosito/flutter-action@v2
  with:
    flutter-version: '3.27.0'  # Change this version
```

#### Adding Deployment Targets
Edit the `ci-cd.yml` file to add your deployment commands in the staging/production jobs.

#### Modifying Build Targets
Add or remove platforms by editing the build jobs in `ci-cd.yml`.

## 📊 Workflow Artifacts

Each successful build produces downloadable artifacts:

- **Android APK** - Ready for distribution or testing
- **Windows ZIP** - Desktop application package
- **Web Build** - Static files for web hosting

Artifacts are available for 30 days after the workflow run.

## 🐛 Troubleshooting

### Common Issues

1. **Build Failures**
   - Check Flutter version compatibility
   - Verify all dependencies are available
   - Check platform-specific requirements

2. **Test Failures**
   - Ensure all tests pass locally
   - Check for environment-specific issues
   - Verify test dependencies

3. **Deployment Issues**
   - Check GitHub Pages settings
   - Verify repository permissions
   - Check base-href configuration for web builds

### Getting Help

- Check the Actions tab for detailed logs
- Review failed job outputs
- Check Flutter and GitHub Actions documentation

## 🎉 Success!

Once set up, your repository will have:
- ✅ Automated testing on every PR
- ✅ Multi-platform builds
- ✅ Automatic releases
- ✅ Web app deployment
- ✅ Dependency management
- ✅ Security scanning

Your CanBussy UI app is now ready for professional development with full CI/CD automation!
