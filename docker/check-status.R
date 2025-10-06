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
url <- sprintf("https://cran.r-project.org/web/checks/check_results_%s.html", pkg)

# 3. Tests -----
cat("Testing package:", pkg, "\n-----\n")

# Getting database
options(repos = c(CRAN = "https://cloud.r-project.org"))
pkg_db <- tools::CRAN_package_db() %>%
  as_tibble() %>%
  filter(Package == pkg)


## a. Not in database ----

if (nrow(pkg_db) == 0) {
  cat(
    paste0("::warning::Package ", pkg, " not found on CRAN.")
  )

  cran_status(
    paste0(":x: **Package ", pkg, " not found on CRAN**:\n\n")
  )

  cran_status(paste0("Check url:\n", url))

  # Copy to issue
  file.copy("cran-status.md", "issue.md")
}

## b. Found on CRAN, check deadline ----

if (!file.exists("cran-status.md")) {
  deadline <- pkg_db %>% pull(Deadline)

  scrap <- url %>%
    read_html()

  cranchecks <- scrap %>%
    html_element("table") %>%
    html_table()

  additional <- grepl("Additional", html_text(scrap), ignore.case = TRUE)

  # Is on deadline?
  is_deadline <- !is.na(deadline)

  if (is_deadline) {
    # Notify
    cran_status(sprintf(
      ":x: **Package %s at risk for removal by `%s`**:\n\n",
      pkg,
      deadline
    ))

    cat("::warning::Package at risk for removal")
  } else {
    cran_status(sprintf(
      ":white_check_mark: **Package %s is not at risk for removal",
      pkg
    ))

    cat("Package is not at risk for removal")
  }

  # Additional info

  # Add checks
  cran_status("\nSee the table below for a summary of the checks run by CRAN:\n\n")
  cran_status(knitr::kable(cranchecks))
  cran_status(sprintf(
    "\n\nAll details and logs are available here: %s", url
  ))

  # Additional issues

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


  # Prepare the issue
  if (is_deadline) file.copy("cran-status.md", "issue.md")
}
