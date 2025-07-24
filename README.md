# radar_love 🌳

> "Structure isn't boring – it's your first line of clarity." — *You (probably during a cleanup)*

[![brew install](https://img.shields.io/badge/brew--install-success-green?logo=homebrew)](https://github.com/raymonepping/homebrew-radar_love)
[![version](https://img.shields.io/badge/version-2.9.1-blue)](https://github.com/raymonepping/homebrew-radar_love)

---

## 🧭 What Is This?

radar_love is a Homebrew-installable, wizard-powered CLI.

---

## 🚀 Quickstart

```bash
brew tap 
brew install /radar_love
radar_love
```

---

Want to customize?

```bash
export FOLDER_TREE_HOME=/opt/homebrew/opt/..
```

---

## 📂 Project Structure

```
./
├── bin/
│   ├── CHANGELOG_radar_love.md
│   └── radar_love*
├── core/
│   ├── bump_version.sh*
│   ├── commit_gh.sh*
│   ├── folder_tree.sh*
│   ├── footer.tpl
│   ├── generate_documentation.sh*
│   ├── header.tpl
│   ├── README.tpl
│   ├── sanity_check.sh*
│   ├── top10_validator.sh*
│   ├── trigger_git_scan.sh*
│   ├── validate_env.sh*
│   ├── vault_generate_scenarios_md.sh*
│   ├── vault_radar_builder.sh*
│   ├── vault_radar_decision_tree.sh*
│   ├── vault_radar_destruction.sh*
│   ├── vault_radar_input.json
│   ├── vault_radar_quotes_helper.sh*
│   ├── vault_radar_quotes.json
│   ├── vault_radar_scenarios.tpl
│   └── vault_radar_validator.sh*
├── Formula/
│   └── radar-love-cli.rb
├── templates/
│   ├── .keep
│   ├── footer.tpl
│   ├── header.tpl
│   └── README.tpl
├── test/
│   ├── .backup.json
│   ├── .gitkeep
│   ├── .keep
│   ├── backup_log.tpl
│   ├── README.md
│   ├── test_sanity.sh
│   └── vault-scenarios.md
├── tpl/
│   ├── readme_01_header.tpl
│   ├── readme_02_project.tpl
│   ├── readme_03_structure.tpl
│   ├── readme_04_body.tpl
│   ├── readme_05_quote.tpl
│   ├── readme_06_article.tpl
│   └── readme_07_footer.tpl
├── .backup.yaml
├── .backupignore
├── .brewinfo
├── .version
├── FOLDER_TREE.md
├── LICENSE
├── README.md.old
├── reload_version.sh*
├── repos_report.md
├── update_formula.sh*
└── vault-scenarios.md

7 directories, 52 files
```

---

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

## 🧠 Philosophy

radar_love 

> Some might say that sunshine follows thunder
> Go and tell it to the man who cannot shine

> Some might say that we should never ponder
> On our thoughts today ‘cos they hold sway over time

---

## 📘 Read the Full Medium.com article

📖 [Article](..) 

---

© 2025 Your Name  
🧠 Powered by self_docs.sh — 🌐 Works locally, CI/CD, and via Brew
