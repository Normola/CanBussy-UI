# Git Hooks for CanBussy UI

This directory contains git hooks to maintain code quality and consistency across the CanBussy UI project.

## 🎯 Available Hooks

### Pre-commit Hook
Automatically formats Dart code before commits to ensure consistent code style.

**Features:**
- ✅ Automatically runs `dart format` on staged Dart files
- ✅ Re-stages formatted files for commit
- ✅ Prevents commits with unformatted code
- ✅ Cross-platform support (Windows, macOS, Linux)
- ✅ Works with Git Bash, PowerShell, WSL, and native terminals

## 🚀 Quick Setup

### Option 1: PowerShell (Windows - Recommended)
```powershell
.\\.githooks\\setup.ps1
```

### Option 2: Bash (macOS/Linux/WSL/Git Bash)
```bash
chmod +x .githooks/setup.sh
./.githooks/setup.sh
```

### Option 3: Manual Setup
```bash
# Copy the appropriate hook to .git/hooks/
cp .githooks/pre-commit .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
```

## 📋 How It Works

1. **When you commit:** `git commit -m "your message"`
2. **Hook triggers:** Pre-commit hook runs automatically
3. **Formats code:** Runs `dart format` on staged Dart files
4. **Re-stages files:** Adds formatted files back to the commit
5. **Commit proceeds:** Your commit includes properly formatted code

### Example Output
```
🔍 Running pre-commit checks...
📝 Formatting Dart files...
  Formatting: lib/main.dart
  Formatting: lib/core/android_wifi_service.dart
✅ Formatted and re-staged files: lib/main.dart lib/core/android_wifi_service.dart
📝 Files have been automatically formatted and added to the commit
🎉 Pre-commit checks completed successfully!
```

## 🔧 Configuration

### Temporarily Disable Hook
If you need to commit without running the hook:
```bash
git commit --no-verify -m "your message"
```

### Permanently Disable Hook
Remove the hook file:
```bash
rm .git/hooks/pre-commit
```

### Re-enable Hook
Run the setup script again:
```bash
./.githooks/setup.ps1  # Windows
./.githooks/setup.sh   # Unix/macOS/Linux
```

## 📁 File Structure

```
.githooks/
├── pre-commit         # Unix/Linux/macOS hook script
├── pre-commit.bat     # Windows batch script hook
├── setup.sh           # Unix setup script
├── setup.ps1          # PowerShell setup script
└── README.md          # This file
```

## 🛠️ Troubleshooting

### Hook Not Running
1. Ensure the hook is executable:
   ```bash
   chmod +x .git/hooks/pre-commit
   ```

2. Check if Dart/Flutter is in your PATH:
   ```bash
   dart --version
   flutter --version
   ```

### Permission Errors (Windows)
1. Run PowerShell as Administrator
2. Enable script execution if needed:
   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```

### WSL/Git Bash Issues
1. Ensure you're using the correct line endings:
   ```bash
   git config core.autocrlf false
   ```

2. Convert line endings if needed:
   ```bash
   dos2unix .git/hooks/pre-commit
   ```

## ✅ Verification

To test if the hook is working:

1. Make a change to a Dart file with poor formatting
2. Stage the file: `git add filename.dart`
3. Commit: `git commit -m "test commit"`
4. The hook should automatically format the file

## 🎨 Benefits

- **Consistent Code Style:** All committed code follows Dart formatting standards
- **Reduced Review Time:** No need to request formatting changes in PRs
- **Automatic Enforcement:** Developers can't accidentally commit unformatted code
- **Team Productivity:** Focus on logic, not formatting

## 🔄 Integration with CI/CD

The pre-commit hook works alongside your GitHub Actions workflows:

- **Local:** Pre-commit hook formats code before commit
- **CI/CD:** GitHub Actions verify formatting in pull requests
- **Double Protection:** Ensures no unformatted code reaches the repository

## 📚 Related

- [Dart Code Style Guide](https://dart.dev/guides/language/effective-dart/style)
- [Flutter Formatting Guide](https://docs.flutter.dev/development/tools/formatting)
- [Git Hooks Documentation](https://git-scm.com/book/en/v2/Customizing-Git-Git-Hooks)

---

**Happy coding with consistent, beautiful Dart code! 🎉**
