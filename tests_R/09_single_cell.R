#!/usr/bin/env Rscript
#===============================================================================
# Tests d'installation des paquets R — Single-cell
# Usage : Structures single-cell, QC, normalisation, annotation de types cellulaires, Seurat, exploration interactive
#
# Chaque test charge le paquet puis exécute un petit calcul réel avec ses fonctions principales.
# - Terminal          : Rscript tests_R/09_single_cell.R
# - Jupyter / RStudio : source("tests_R/09_single_cell.R")  (ou copier un bloc test_pkg() dans une cellule)
# - Tous les groupes  : Rscript tests_R/run_all.R
# Environnement de référence : binder/environment.yml (conda-forge + bioconda, R 4.5)
#
# Paquets (spécification conda) :
#   SingleCellExperiment                 bioconda::bioconductor-singlecellexperiment
#   scuttle                              bioconda::bioconductor-scuttle
#   scater                               bioconda::bioconductor-scater
#   scran                                bioconda::bioconductor-scran
#   celldex                              bioconda::bioconductor-celldex
#   SingleR                              bioconda::bioconductor-singler
#   Seurat                               conda-forge::r-seurat
#   iSEE                                 bioconda::bioconductor-isee
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

debut_groupe("09_single_cell", "Single-cell")

test_pkg("SingleCellExperiment", {
  print(SingleCellExperiment(assays=list(counts=matrix(rpois(200, 5), 20))))
})

test_pkg("scuttle", {
  print(head(perCellQCMetrics(mockSCE())))
})

test_pkg("scater", {
  sce <- scuttle::logNormCounts(scuttle::mockSCE())
  sce <- runPCA(sce)
  print(dim(SingleCellExperiment::reducedDim(sce, "PCA")))
})

test_pkg("scran", {
  sce <- scuttle::logNormCounts(scuttle::mockSCE())
  print(head(modelGeneVar(sce)))
})

test_pkg("celldex", {
  stopifnot(is.function(HumanPrimaryCellAtlasData))
})

test_pkg("SingleR", {
  set.seed(1)
  ref <- scuttle::logNormCounts(scuttle::mockSCE())
  ref$label <- sample(c("A", "B"), ncol(ref), TRUE)
  tst <- scuttle::logNormCounts(scuttle::mockSCE())
  print(table(SingleR(tst, ref, labels=ref$label)$labels))
})

test_pkg("Seurat", {
  m <- matrix(rpois(2000, 1), 100, 20, dimnames=list(paste0("g", 1:100), paste0("c", 1:20)))
  obj <- NormalizeData(CreateSeuratObject(counts=m), verbose=FALSE)
  print(obj)
})

test_pkg("iSEE", {
  sce <- SingleCellExperiment::SingleCellExperiment(assays=list(counts=matrix(rpois(200, 5), 20, dimnames=list(paste0("g", 1:20), paste0("c", 1:10)))))
  app <- iSEE(sce)
  stopifnot(inherits(app, "shiny.appobj"))
})

resume_tests("09_single_cell")
if (!interactive() && !isTRUE(getOption("tests.run_all")))
  quit(status = as.integer(any(grepl("^ECHEC|^ABSENT", .tests$res$statut[.tests$res$groupe == "09_single_cell"]))))
