# Vault Radar Scenarios

[![](https://img.shields.io/badge/High-3-red)](##high) [![](https://img.shields.io/badge/Medium-1-yellow)](##medium) [![](https://img.shields.io/badge/Low-2-lightgrey)](##low)  
[![](https://img.shields.io/badge/Non_inclusive-2-green)](##non_inclusive) [![](https://img.shields.io/badge/Pii-2-orange)](##pii) [![](https://img.shields.io/badge/Secret-2-purple)](##secret)   

**Total scenarios:** 6

---
## Table of Contents
 - [AWS Access Key](#aws-access-key)
 - [GitHub Token](#github-token)
 - [Email](#email)
 - [SSN](#ssn)
 - [Blacklist](#blacklist)
 - [Master branch](#master-branch)

---

### SSN (pii / PII)

- **Value:** `123-45-6789`
- **Languages:** python, terraform, bash
- **Severity:** high
- **Author:** test
- **Source:** fake db

US social security number

---
### AWS Access Key (secret / AWS)

- **Value:** `AWS_ACCESS_KEY_ID=AKIA1234567890FAKE`
- **Languages:** bash, python, docker, terraform, node
- **Severity:** high
- **Author:** raymon.epping
- **Source:** test suite

Classic AWS secret pattern

---
### GitHub Token (secret / github)

- **Value:** `GITHUB_TOKEN=ghp_1234567890abcdefghijklmnopqrstuvwxyz`
- **Languages:** bash, python, node, docker
- **Severity:** high
- **Author:** test
- **Source:** examples

GitHub personal access token format

---
### Email (pii / PII)

- **Value:** `john.doe@example.com`
- **Languages:** bash, python, node
- **Severity:** medium
- **Author:** test
- **Source:** public db

Sample email leak

---
### Blacklist (non_inclusive / inclusivity)

- **Value:** `blacklist`
- **Languages:** bash, python, docker, terraform, node
- **Severity:** low
- **Author:** test
- **Source:** old code

Non-inclusive legacy term

---
### Master branch (non_inclusive / inclusivity)

- **Value:** `master branch`
- **Languages:** bash, python, docker, terraform, node
- **Severity:** low
- **Author:** test
- **Source:** legacy vcs

Legacy VCS term

---
