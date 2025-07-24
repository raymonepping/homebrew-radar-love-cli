## 🧭 What Is This?

radar-love-cli is a Homebrew-installable, wizard-powered CLI for simulating secret leaks and triggering GitHub PR scans with HashiCorp Vault Radar. Perfect for:

- Security teams or DevOps wanting to test and demo secret-scanning pipelines
- Developers who need to safely simulate credential leaks without real risk
- Anyone who wants to visualize the impact of secrets in code—before it’s a real problem

---

## 🔑 Key Features

- ✅ One CLI to orchestrate your entire Radar demo  
- 🧪 Includes leak builders, commit triggers, PR scans  
- 📎 Built-in GitHub automation (via `gh`)  
- 🔍 Environment validator with `--validate`  
- 🧼 CI-ready with `--quiet`, `--debug`, and `--status`  

---

## 🧰 How to Use

```bash
brew install raymonepping/tap/radar_love_cli
radar_love --create true --build true --commit true --request true
```

All flags are optional. This CLI wraps and coordinates a set of deeply integrated scripts.

---

## ✨ Example Scenarios

```bash
# Minimal demo run with default values
radar_love

# Full cycle with debug and fresh rebuild
radar_love --fresh true --build true --commit true --request true --debug compact

# Validate dependencies only
radar_love --validate
```

---

## 🚧 Flags Reference

All supported flags can be viewed with:

```bash
radar_love --help
```

---

### ✨ Other CLI tooling available

✅ **brew-brain-cli**  
CLI toolkit to audit, document, and manage your Homebrew CLI arsenal with one meta-tool

✅ **bump-version-cli**  
CLI toolkit to bump semantic versions in Bash scripts and update changelogs

✅ **commit-gh-cli**  
CLI toolkit to commit, tag, and push changes to GitHub

✅ **folder-tree-cli**  
CLI toolkit to visualize folder structures with Markdown reports

✅ **radar-love-cli**  
CLI toolkit to simulate secret leaks and trigger GitHub PR scans

✅ **repository-audit-cli**  
CLI toolkit to audit Git repositories and folders, outputting Markdown/CSV/JSON reports

✅ **repository-backup-cli**  
CLI toolkit to back up GitHub repositories with tagging, ignore rules, and recovery

✅ **repository-export-cli**  
CLI toolkit to export, document, and manage your GitHub repositories from the CLI

✅ **self-doc-gen-cli**  
CLI toolkit for self-documenting CLI generation with Markdown templates and folder visualization

---

