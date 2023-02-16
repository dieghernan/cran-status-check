if (!requireNamespace("optparse", quietly = TRUE)) {
  suppressMessages(install.packages("optparse",
    repos = "https://cloud.r-project.org",
    verbose = FALSE,
    quiet = TRUE
  ))
}

if (file.exists("cran-status.md")) unlink("cran-status.md")
if (file.exists("issue.md")) unlink("issue.md")

suppressPackageStartupMessages(library(dplyr))
suppressPackageStartupMessages(library(rvest))
suppressPackageStartupMessages(library(stringr))
suppressPackageStartupMessages(library(digest))

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
    help = "status types (comma separated list, for exemple ERROR,WARN,NOTE",
    metavar = "character"
  )
)

opt_parser <- OptionParser(option_list = option_list)
opt <- parse_args(opt_parser)

parse_errors <- function(url) {
  return(
    tryCatch(url %>% read_html() %>% html_text(), error = function(e) "URL Not Found")
  )
}

build_md5_codes <- function(pkg, errors, step) {
  # Build current step links
  errors[[sprintf("%sLinks", step)]] <-
    str_c(
      "https://www.r-project.org/nosvn/R.check/",
      errors$Flavor, "/", pkg, sprintf("-00%s.html", tolower(step))
    )


  # Get details as text for current step
  errors[[sprintf("%sDetails", step)]] <- lapply(errors[[sprintf("%sLinks", step)]],
    FUN = parse_errors
  )

  # Create md5 codes for each step
  errors[[sprintf("%sId", step)]] <- lapply(
    errors[[sprintf("%sDetails", step)]],
    digest
  )

  # Unlist results
  errors[[sprintf("%sId", step)]] <- unlist(errors[[sprintf("%sId", step)]])

  return(errors)
}

cran_status <- function(x) {
      cat(x, file = "cran-status.md", append = TRUE, sep = "\n")
}

pkg <- opt$package # paste(desc::desc_get(keys = "Package"))

cat("Testing package:", pkg, "\n-----\n")

url <- sprintf("https://cran.r-project.org/web/checks/check_results_%s.html", pkg)

if (!httr::http_error(url)) {
  # Get input status
  status_types <- opt$statuses
  statuses <- unlist(strsplit(status_types, split = ","))

  # Parse html table into dataframe
  checks <- url %>%
    read_html() %>%
    html_element("table") %>%
    html_table()

  # filter statuses and get their details links (and convert it to md5 unique code)
  errors <- filter(checks, Status %in% statuses)

  # If errors table is empty: just get out !
  if (dim(errors)[1] == 0) {
    cat(
      sprintf("None of this status found in the CRAN table. (status=%s)", status_types)
    )
    
    cran_status(sprintf(
        "**:white_check_mark: CRAN error for %s not found with (`%s`)s**:\n\n",
        pkg,
        status_types
      ))
    
      cran_status("\nSee the table below for a summary of the checks run by CRAN:\n\n")
      cran_status(knitr::kable(checks))
      cran_status(sprintf(
        "\n\nAll details and logs are available here: %s", url
      ))
    
  } else {
    # Build each step md5 code
    errors <- build_md5_codes(pkg, errors, "Build")
    errors <- build_md5_codes(pkg, errors, "Check")
    errors <- build_md5_codes(pkg, errors, "Install")

    # Alphanumeric order on Flavor (for cran status comparison)
    errors <- errors[order(errors$Flavor), ]

    # Save into CSV:
    errors %>%
      select(Flavor, CheckId, InstallId, BuildId) %>%
      write.csv("cran_errors.csv", row.names = FALSE)
    if (any(checks$Status %in% statuses)) {
      cran_status(sprintf(
        "**:x: CRAN checks for %s resulted in one or more (`%s`)s**:\n\n",
        pkg,
        status_types
      ))
      cran_status("\nSee the table below for a summary of the checks run by CRAN:\n\n")
      cran_status(knitr::kable(checks))
      cran_status(sprintf(
        "\n\nAll details and logs are available here: %s", url
      ))

      # Copy
      file.copy("cran-status.md", "issue.md")

      cat("::warning::One or more CRAN checks resulted in an invalid status\n")
    }
  }
} else {
  cat(paste0("::warning::Package ", pkg,
  " not found on CRAN."
  ))
  
  cran_status(paste0("**:x: Package ", pkg,
  " not found on CRAN.\n\n"))
  cran_status(paste0("Error accessing url:\n", url))
  
  # Copy
  file.copy("cran-status.md", "issue.md")
}
