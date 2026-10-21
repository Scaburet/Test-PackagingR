#!/usr/bin/env Rscript
#===============================================================================
# Tests d'installation des paquets R — Apprentissage automatique
# Usage : Forêts aléatoires, modèles pénalisés, réseaux de neurones, framework tidymodels
#
# Chaque test charge le paquet puis exécute un petit calcul réel avec ses fonctions principales.
# - Terminal          : Rscript tests_R/05_machine_learning.R
# - Jupyter / RStudio : source("tests_R/05_machine_learning.R")  (ou copier un bloc test_pkg() dans une cellule)
# - Tous les groupes  : Rscript tests_R/run_all.R
# Environnement de référence : binder/environment.yml (conda-forge + bioconda, R 4.5)
#
# Paquets (spécification conda) :
#   randomForest                         conda-forge::r-randomforest
#   ranger                               conda-forge::r-ranger
#   glmnet                               conda-forge::r-glmnet
#   nnet                                 conda-forge::r-nnet
#   ipred                                conda-forge::r-ipred
#   sparsevctrs                          conda-forge::r-sparsevctrs
#   yardstick                            conda-forge::r-yardstick
#   tidymodels                           conda-forge::r-tidymodels
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

debut_groupe("05_machine_learning", "Apprentissage automatique")

test_pkg("randomForest", {
  print(randomForest(Species ~ ., data=iris, ntree=50))
})

test_pkg("ranger", {
  print(ranger(Species ~ ., data=iris, num.trees=50))
})

test_pkg("glmnet", {
  fit <- glmnet(as.matrix(mtcars[, -1]), mtcars$mpg)
  print(dim(coef(fit)))
})

test_pkg("nnet", {
  print(multinom(Species ~ ., data=iris, trace=FALSE))
})

test_pkg("ipred", {
  print(bagging(Species ~ ., data=iris, nbagg=10))
})

test_pkg("sparsevctrs", {
  print(sparse_double(c(5, 1), c(2, 9), 10))
})

test_pkg("yardstick", {
  df <- data.frame(truth=factor(c("a", "b", "a")), estimate=factor(c("a", "b", "b")))
  print(accuracy(df, truth, estimate))
})

test_pkg("tidymodels", {
  print(fit(linear_reg(), mpg ~ wt, data=mtcars))
})

resume_tests("05_machine_learning")
if (!interactive() && !isTRUE(getOption("tests.run_all")))
  quit(status = as.integer(any(grepl("^ECHEC|^ABSENT", .tests$res$statut[.tests$res$groupe == "05_machine_learning"]))))
