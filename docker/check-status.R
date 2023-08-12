# Modified version from pharmaverse/admiralci
# See https://github.com/pharmaverse/admiralci/tree/61347fe11955297818b3ca7814fc7328f2ad7840/.github/actions/cran-status-extract


# 0. Setup ----
if (!requireNamespace("optparse", quietly = TRUE)) {
  suppressMessages(install.packages("optparse",
    repos = "https://cloud.r-project.org",
    verbose = FALSE,
    quiet = TRUE
  ))
}
suppressPackageStartupMessages(library(dplyr))
suppressPackageStartupMessages(library(rvest))
suppressPackageStartupMessages(library(stringr))
suppressPackageStartupMessages(library(digest))

# clean files
if (file.exists("cran-status.md")) unlink("cran-status.md")
if (file.exists("issue.md")) unlink("issue.md")

# check if needed : package name and working dir path as input arguments :
library(optparse)
option_list <- list(
  make_option(c("-p", "--package"),
    type = "character",
    help = "package name (REQUIRED)",
    metavar = "character"
  ),
  make_option(c("-s", "--statuses"),
    type = "character", default = "ERROR,WARN,NOTE",
    help = "status types (comma separated list, e.g. ERROR,WARN,NOTE",
    metavar = "character"
  )
)
opt_parser <- OptionParser(option_list = option_list)
opt <- parse_args(opt_parser)

# 1. Fun helpers ----
cran_status <- function(x) {
  cat(x, file = "cran-status.md", append = TRUE, sep = "\n")
}

# 2. Get Inputs ----
pkg <- opt$package # paste(desc::desc_get(keys = "Package"))
# Get input status
status_types <- opt$statuses
statuses <- unlist(strsplit(status_types, split = ","))

url <- sprintf("https://cran.r-project.org/web/checks/check_results_%s.html", pkg)

# 3. Tests -----
cat("Testing package:", pkg, "\n-----\n")
## a. Url not reachable ----

if (httr::http_error(url)) {
  cat(
    paste0("::warning::Package ", pkg, " not found on CRAN.")
  )

  cran_status(
    paste0(":x: **Package ", pkg, " not found on CRAN**:\n\n")
  )

  cran_status(paste0("Error accessing url:\n", url))

  # Copy to issue
  file.copy("cran-status.md", "issue.md")
}

## b. Found on CRAN, check issues ----

if (!file.exists("cran-status.md")) {
  scrap <- url %>%
    read_html()

  cranchecks <- scrap %>%
    html_element("table") %>%
    html_table()

  any_error <- any(cranchecks$Status %in% statuses)
  additional <- grepl("Additional", html_text(scrap), ignore.case = TRUE)

  ### i. Has issues ----
  if (any_error) {
    cran_status(sprintf(
      ":x: **CRAN checks for %s resulted in one or more (`%s`)s**:\n\n",
      pkg,
      status_types
    ))
    cran_status("\nSee the table below for a summary of the checks run by CRAN:\n\n")
    cran_status(knitr::kable(cranchecks))
    cran_status(sprintf(
      "\n\nAll details and logs are available here: %s\n\n", url
    ))
    cat("::warning::One or more CRAN checks resulted in an invalid status\n")
  }

  ### ii. Has additional issues ----

  if (additional) {
    cran_status(sprintf(
      ":x: **%s has `Additional Issues`**:\n",
      pkg
    ))
    cran_status(sprintf(
      "\nCheck the url: %s\n", url
    ))
    cat(paste0("::warning::", pkg, " has Additional issues\n"))
  }

  ## So far if cran-status.md exists, generate issue
  if (file.exists("cran-status.md")) file.copy("cran-status.md", "issue.md")

  ### iii. All OK ----
  # If no issue has been generated

  if (!file.exists("cran-status.md")) {
    cat(
      sprintf("None of this status found in the CRAN table. (status=%s)", status_types)
    )

    cran_status(sprintf(
      ":white_check_mark: **CRAN error for %s not found with (`%s`)s**:\n\n",
      pkg,
      status_types
    ))

    cran_status("\nSee the table below for a summary of the checks run by CRAN:\n\n")
    cran_status(knitr::kable(cranchecks))
    cran_status(sprintf(
      "\n\nAll details and logs are available here: %s", url
    ))
  }
}
