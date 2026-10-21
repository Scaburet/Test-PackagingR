#!/usr/bin/env Rscript
#===============================================================================
# Tests d'installation des paquets R — Rapports, documents et widgets HTML
# Usage : Génération de documents (Rmd, Quarto, LaTeX, livres, tableaux de bord) et contenus HTML interactifs
#
# Chaque test charge le paquet puis exécute un petit calcul réel avec ses fonctions principales.
# - Terminal          : Rscript tests_R/01_rapports_documents.R
# - Jupyter / RStudio : source("tests_R/01_rapports_documents.R")  (ou copier un bloc test_pkg() dans une cellule)
# - Tous les groupes  : Rscript tests_R/run_all.R
# Environnement de référence : binder/environment.yml (conda-forge + bioconda, R 4.5)
#
# Paquets (spécification conda) :
#   rmarkdown                            conda-forge::r-rmarkdown
#   knitr                                conda-forge::r-knitr
#   quarto                               conda-forge::r-quarto
#   tinytex                              conda-forge::r-tinytex
#   bookdown                             conda-forge::r-bookdown
#   flexdashboard                        conda-forge::r-flexdashboard
#   htmltools                            conda-forge::r-htmltools
#   htmlwidgets                          conda-forge::r-htmlwidgets
#   DT                                   conda-forge::r-dt
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

debut_groupe("01_rapports_documents", "Rapports, documents et widgets HTML")

test_pkg("rmarkdown", {
  f <- tempfile(fileext=".Rmd")
  writeLines(c("# Test", "", "Calcul : `r 1+1`"), f)
  out <- rmarkdown::render(f, output_format="html_document", quiet=TRUE)
  stopifnot(file.exists(out))
})

test_pkg("knitr", {
  print(knitr::kable(head(mtcars, 3)))
})

test_pkg("quarto", {
  stopifnot(quarto::quarto_available())
  print(quarto::quarto_version())
})

test_pkg("tinytex", {
  cat("LaTeX disponible :", tinytex::is_tinytex() || nzchar(Sys.which("pdflatex")), "\n")
})

test_pkg("bookdown", {
  stopifnot(inherits(html_document2(), "rmarkdown_output_format"))
})

test_pkg("flexdashboard", {
  stopifnot(inherits(flex_dashboard(), "rmarkdown_output_format"))
})

test_pkg("htmltools", {
  print(htmltools::tags$div(class="test", "ok"))
})

test_pkg("htmlwidgets", {
  w <- htmlwidgets::createWidget("test", list(a=1))
  stopifnot(inherits(w, "htmlwidget"))
})

test_pkg("DT", {
  w <- DT::datatable(head(iris))
  stopifnot(inherits(w, "datatables"))
})

resume_tests("01_rapports_documents")
if (!interactive() && !isTRUE(getOption("tests.run_all")))
  quit(status = as.integer(any(grepl("^ECHEC|^ABSENT", .tests$res$statut[.tests$res$groupe == "01_rapports_documents"]))))
