# cran-status-check

![latest-version](https://img.shields.io/github/v/release/dieghernan/cran-status-check)

This action checks the CRAN status of a **R** package and optionally creates an issue or make the action 
fail. Combined with CRON (see [how to set periodic runs on GH Actions](https://docs.github.com/en/actions/using-workflows/events-that-trigger-workflows#schedule)), a **R** package developer can verify regularly 
if the package needs attention.

## Basic configuration

Create a file named `cran-status-check.yml` on a repo in the usual path for GH actions 
(`.github/workflows`) with the following content:

```yaml
name: check-cran-status

on:
  push:
    branches: [main, master]
  schedule:
    - cron: '0 6 * * 1,4' # Runs at 06:00 on Monday and Thursday, check https://crontab.guru/
jobs:
  check:
    runs-on: ubuntu-latest
    permissions: write-all
    env:
      GITHUB_PAT: ${{ secrets.GITHUB_TOKEN }}

    steps:
      - name: Checkout
        uses: actions/checkout@v3
        
      - name: Check
        uses: dieghernan/cran-status-check@main

```

The action...

## Inputs available

- `path`: ...
