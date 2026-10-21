#!/usr/bin/env Rscript
#===============================================================================
# Tests d'installation des paquets R — Import, export et manipulation de données (tidyverse & co)
# Usage : Lecture/écriture de fichiers, manipulation de tableaux, chaînes, dates, JSON, SQL, web
#
# Chaque test charge le paquet puis exécute un petit calcul réel avec ses fonctions principales.
# - Terminal          : Rscript tests_R/02_import_manipulation_donnees.R
# - Jupyter / RStudio : source("tests_R/02_import_manipulation_donnees.R")  (ou copier un bloc test_pkg() dans une cellule)
# - Tous les groupes  : Rscript tests_R/run_all.R
# Environnement de référence : binder/environment.yml (conda-forge + bioconda, R 4.5)
#
# Paquets (spécification conda) :
#   tibble                               conda-forge::r-tibble
#   dplyr                                conda-forge::r-dplyr
#   tidyr                                conda-forge::r-tidyr
#   purrr                                conda-forge::r-purrr
#   stringr                              conda-forge::r-stringr
#   forcats                              conda-forge::r-forcats
#   lubridate                            conda-forge::r-lubridate
#   clock                                conda-forge::r-clock
#   warp                                 conda-forge::r-warp
#   slider                               conda-forge::r-slider
#   readr                                conda-forge::r-readr
#   readxl                               conda-forge::r-readxl
#   writexl                              conda-forge::r-writexl
#   haven                                conda-forge::r-haven
#   jsonlite                             conda-forge::r-jsonlite
#   RSQLite                              conda-forge::r-rsqlite
#   rvest                                conda-forge::r-rvest
#   httr                                 conda-forge::r-httr
#===============================================================================

## ---- Fonctions de test (identiques dans chaque script ; non redéfinies si déjà chargées) ----
## options(tests.verbose = TRUE)  : affiche la sortie de chaque test
## options(tests.isolate = FALSE) : exécute les tests dans la session courante (par défaut :
##                                  un processus R séparé par paquet via callr, comme Rscript -e)
if (!exists("test_pkg", mode = "function")) {
  .tests <- new.env()
  .tests$groupe <- NA_character_
  .tests$res <- data.frame(groupe = character(), paquet = character(), version = character(),
                           statut = character(), secondes = numeric(), message = character())
  debut_groupe <- function(id, titre) {
    .tests$groupe <- id
    cat("\n==== ", id, " : ", titre, " ====\n", sep = "")
  }
  test_pkg <- function(pkg, code, network = NULL, not_installable = NULL) {
    code <- substitute(code)
    t0 <- proc.time()[["elapsed"]]
    out <- character()
    if (!requireNamespace(pkg, quietly = TRUE)) {
      version <- NA_character_
      statut <- if (is.null(not_installable)) "ABSENT" else "NON INSTALLABLE"
      msg <- if (is.null(not_installable)) "paquet non installé" else not_installable
    } else {
      version <- format(utils::packageVersion(pkg))
      run <- function(pkg, code) {
        suppressPackageStartupMessages(library(pkg, character.only = TRUE))
        utils::capture.output(eval(code, new.env(parent = globalenv())))
      }
      out <- tryCatch({
        if (isTRUE(getOption("tests.isolate", TRUE)) && requireNamespace("callr", quietly = TRUE))
          callr::r(run, list(pkg, code)) else run(pkg, code)
      }, error = function(e) {
        while (!is.null(e$parent)) e <- e$parent
        structure(conditionMessage(e), class = "test_error")
      })
      if (inherits(out, "test_error")) {
        statut <- if (is.null(network)) "ECHEC" else "ECHEC (réseau ?)"
        msg <- gsub("\\s+", " ", trimws(paste(unclass(out), if (!is.null(network)) paste0("[nécessite ", network, "]"))))
        out <- character()
      } else {
        statut <- "OK"; msg <- ""
      }
    }
    sec <- round(proc.time()[["elapsed"]] - t0, 1)
    .tests$res[nrow(.tests$res) + 1, ] <- list(.tests$groupe, pkg, version, statut, sec, msg)
    cat(sprintf("%-36s %-12s %-16s %6.1fs  %s\n", pkg, ifelse(is.na(version), "-", version), statut, sec, substr(msg, 1, 150)))
    if (isTRUE(getOption("tests.verbose", FALSE)) && length(out)) cat(paste0("    ", out), sep = "\n")
    invisible(statut == "OK")
  }
  resume_tests <- function(groupe = NULL) {
    r <- .tests$res
    if (!is.null(groupe)) r <- r[r$groupe == groupe, ]
    cat("\nRésumé", if (!is.null(groupe)) groupe, ":", paste(names(table(r$statut)), table(r$statut), sep = " = ", collapse = " ; "), "\n")
    invisible(r)
  }
}

debut_groupe("02_import_manipulation_donnees", "Import, export et manipulation de données (tidyverse & co)")

test_pkg("tibble", {
  print(tibble(x=1:3, y=letters[1:3]))
})

test_pkg("dplyr", {
  print(mtcars |> group_by(cyl) |> summarise(mpg=mean(mpg)))
})

test_pkg("tidyr", {
  print(pivot_longer(head(iris, 2), -Species))
})

test_pkg("purrr", {
  stopifnot(identical(map_dbl(1:3, ~ .x * 2), c(2, 4, 6)))
})

test_pkg("stringr", {
  stopifnot(str_detect("packaging", "pack"))
})

test_pkg("forcats", {
  print(fct_infreq(factor(c("a", "b", "b"))))
})

test_pkg("lubridate", {
  print(ymd("2026-10-21") + days(1))
})

test_pkg("clock", {
  print(add_months(year_month_day(2026, 10, 21), 3))
})

test_pkg("warp", {
  print(warp_distance(as.Date("2026-01-01") + 0:5, period="day", every=2))
})

test_pkg("slider", {
  print(slide_dbl(1:5, mean, .before=1))
})

test_pkg("readr", {
  f <- tempfile(fileext=".csv")
  write_csv(mtcars, f)
  print(dim(read_csv(f, show_col_types=FALSE)))
})

test_pkg("readxl", {
  print(head(read_excel(readxl_example("datasets.xlsx"))))
})

test_pkg("writexl", {
  f <- tempfile(fileext=".xlsx")
  write_xlsx(mtcars, f)
  stopifnot(file.exists(f))
})

test_pkg("haven", {
  f <- tempfile(fileext=".sav")
  write_sav(mtcars, f)
  print(dim(read_sav(f)))
})

test_pkg("jsonlite", {
  print(toJSON(head(mtcars, 2)))
})

test_pkg("RSQLite", {
  con <- DBI::dbConnect(SQLite(), ":memory:")
  DBI::dbWriteTable(con, "mtcars", mtcars)
  print(DBI::dbGetQuery(con, "SELECT COUNT(*) AS n FROM mtcars"))
  DBI::dbDisconnect(con)
})

test_pkg("rvest", {
  print(html_text2(html_elements(minimal_html("<p>ok</p>"), "p")))
})

test_pkg("httr", {
  print(parse_url("https://cran.r-project.org/web/packages/")$hostname)
  print(status_code(HEAD("https://cloud.r-project.org")))
}, network = "accès à cloud.r-project.org")

resume_tests("02_import_manipulation_donnees")
if (!interactive() && !isTRUE(getOption("tests.run_all")))
  quit(status = as.integer(any(grepl("^ECHEC|^ABSENT", .tests$res$statut[.tests$res$groupe == "02_import_manipulation_donnees"]))))
