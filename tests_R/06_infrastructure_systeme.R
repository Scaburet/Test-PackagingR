#!/usr/bin/env Rscript
#===============================================================================
# Tests d'installation des paquets R — Infrastructure, code compilé et système
# Usage : C++ (Rcpp/Armadillo/Eigen), compatibilité, chiffrement, bibliographie, serveur HTTP, sous-processus
#
# Chaque test charge le paquet puis exécute un petit calcul réel avec ses fonctions principales.
# - Terminal          : Rscript tests_R/06_infrastructure_systeme.R
# - Jupyter / RStudio : source("tests_R/06_infrastructure_systeme.R")  (ou copier un bloc test_pkg() dans une cellule)
# - Tous les groupes  : Rscript tests_R/run_all.R
# Environnement de référence : binder/environment.yml (conda-forge + bioconda, R 4.5)
#
# Paquets (spécification conda) :
#   Rcpp                                 conda-forge::r-rcpp
#   RcppArmadillo                        conda-forge::r-rcpparmadillo
#   RcppEigen                            conda-forge::r-rcppeigen
#   backports                            conda-forge::r-backports
#   gtools                               conda-forge::r-gtools
#   rbibutils                            conda-forge::r-rbibutils
#   openssl                              conda-forge::r-openssl
#   httpuv                               conda-forge::r-httpuv
#   processx                             conda-forge::r-processx
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

debut_groupe("06_infrastructure_systeme", "Infrastructure, code compilé et système")

test_pkg("Rcpp", {
  stopifnot(Rcpp::evalCpp("2 + 2") == 4)
})

test_pkg("RcppArmadillo", {
  print(coef(fastLm(mpg ~ wt, data=mtcars)))
})

test_pkg("RcppEigen", {
  print(coef(fastLm(mpg ~ wt, data=mtcars)))
})

test_pkg("backports", {
  stopifnot(is.function(backports::import))
})

test_pkg("gtools", {
  print(mixedsort(c("a10", "a2", "a1")))
})

test_pkg("rbibutils", {
  f <- tempfile(fileext=".bib")
  writeLines("@article{a, title={Titre}, author={Doe, J.}, year={2020}, journal={J}}", f)
  print(readBib(f))
})

test_pkg("openssl", {
  print(sha256("packaging"))
  print(openssl_config()$version)
})

test_pkg("httpuv", {
  s <- startServer("127.0.0.1", randomPort(), list(call=function(req) list(status=200L, headers=list("Content-Type"="text/plain"), body="ok")))
  print(s$isRunning())
  s$stop()
})

test_pkg("processx", {
  print(run("echo", "ok")$stdout)
})

resume_tests("06_infrastructure_systeme")
if (!interactive() && !isTRUE(getOption("tests.run_all")))
  quit(status = as.integer(any(grepl("^ECHEC|^ABSENT", .tests$res$statut[.tests$res$groupe == "06_infrastructure_systeme"]))))
