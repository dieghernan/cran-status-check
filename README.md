# cran-status-check

![latest-version](https://img.shields.io/github/v/release/dieghernan/cran-status-check)

This action checks the CRAN status of a **R** package and optionally creates an
issue or make the action fail. Combined with CRON (see [how to set periodic runs
on GH
Actions](https://docs.github.com/en/actions/using-workflows/events-that-trigger-workflows#schedule)),
a **R** package developer can verify regularly if the package needs attention.

## Basic configuration

Create a file named `cran-status-check.yml` on a repo in the usual path for GH
actions (`.github/workflows`) with the following content:

``` yaml
name: check-cran-status

on:
  push:
    branches: [main, master]
  schedule:
    - cron: '0 6 * * 1,4' # Runs at 06:00 on Monday and Thursday, check https://crontab.guru/
jobs:
  check:
    runs-on: ubuntu-latest
    permissions:
      issues: write
    env:
      GITHUB_PAT: ${{ secrets.GITHUB_TOKEN }}

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Check
        uses: dieghernan/cran-status-check@v2
```

## Inputs available

### Package inputs

-   `path`: Default value `'.'` (root of the repo). Path to the **R** package
    root, if the package is not at the top level of the repository.

    ``` yaml
      - name: Check
        uses: dieghernan/cran-status-check@v2
        with:
          path: "Rpackage"
    ```

-   `package`: Default value `''`. Name of the package to check. If provided, it
    would have priority over the package on the repo defined on `path`. It is
    useful for creating workflows than can check several packages

    ``` yaml

      - name: Check dplyr
        uses: dieghernan/cran-status-check@v2
        with:
          package: "dplyr"

      - name: Check ggplot2
        uses: dieghernan/cran-status-check@v2
        with:
          package: "ggplot2"    
    ```

-   `statuses`: Default value `'WARN,ERROR'`. CRAN status to check. This is a
    comma-separated string of statuses. Allowed statuses are `'NOTE'`, `'WARN'`,
    and `'ERROR'`.

    ``` yaml

      - name: Check dplyr
        uses: dieghernan/cran-status-check@v2
        with:
          package: "dplyr"

      - name: Check ggplot2
        uses: dieghernan/cran-status-check@v2
        with:
          package: "ggplot2"    
    ```

### Result reports

-   `fail-on-error`: Default value `'false'`. Logical, should the action errors
    if CRAN checks are not OK? This is useful for ensuring that subsequent steps
    would be performed even if any of the packages to check throws an error.

    ``` yaml

      - name: Check a package not in CRAN
        uses: dieghernan/cran-status-check@v2
        with:
          package: "iamnotincran"
          fail-on-error: "false"

      - name: Check igoR even if the previous step has failed but stop here
        uses: dieghernan/cran-status-check@v2
        with:
          package: "igoR"
          statuses: "NOTE,WARN,ERROR"
          fail-on-error: "true"
    ```

-   `create-issue`: Default value `true` Logical, create an issue on CRAN failed
    checks using
    [create-issue-from-file](https://github.com/peter-evans/create-issue-from-file)
    action.

-   `issue-assignees`: Default value `''`. Whom should the issue be assigned to
    if errors are encountered in the CRAN status checks? This is a
    comma-separated string of GitHub usernames. If undefined or empty, no
    assignments are made. Check also
    [create-issue-from-file](https://github.com/peter-evans/create-issue-from-file)
    action.

    ``` yaml

    -  name: Check igoR and create issue 
       uses: dieghernan/cran-status-check@v2
       with: 
         package: "igoR" 
         statuses: "NOTE,WARN,ERROR" 
         fail-on-error: "true"
         create-issue: "true" 
         issue-assignees: "dieghernan,johndoe"
    ```

## Outputs

-   The action would produce a report with a summary of the check

-   If `create-issue: "true"` (the default value) and the action found an error,
    it would create an issue on the repo and (if provided) it would assign it to
    the users specified on `issue-assignees`.

-   if `fail-on-error: "true"` (not activated by default) the action would fail,
    and GitHub would send a notification to the repo owner following the
    standard process of GH Actions.

## Derived Work Notice

This workflow is derived from
[cran-status.yml](https://github.com/pharmaverse/admiralci/blob/61347fe11955297818b3ca7814fc7328f2ad7840/.github/workflows/cran-status.yml)
by [pharmaverse/admiralci
contributors](https://github.com/pharmaverse/admiralci/graphs/contributors):

> Copyright 2021 F. Hoffmann-La Roche AG and GlaxoSmithKline LLC
>
> Licensed under the Apache License, Version 2.0 (the "License"); you may not
> use this file except in compliance with the License. You may obtain a copy of
> the License at
>
> <http://www.apache.org/licenses/LICENSE-2.0>
>
> Unless required by applicable law or agreed to in writing, software
> distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
> WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
> License for the specific language governing permissions and limitations under
> the License.
