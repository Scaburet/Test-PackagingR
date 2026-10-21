#!/usr/bin/env Rscript
#===============================================================================
# Tests d'installation des paquets R — Épigénomique (ChIP/ATAC-seq) et visualisation de tracks génomiques
# Usage : Régions différentielles, annotation de pics, QC ATAC-seq, tracks génomiques
#
# Chaque test charge le paquet puis exécute un petit calcul réel avec ses fonctions principales.
# - Terminal          : Rscript tests_R/10_epigenomique_tracks.R
# - Jupyter / RStudio : source("tests_R/10_epigenomique_tracks.R")  (ou copier un bloc test_pkg() dans une cellule)
# - Tous les groupes  : Rscript tests_R/run_all.R
# Environnement de référence : binder/environment.yml (conda-forge + bioconda, R 4.5)
#
# Paquets (spécification conda) :
#   csaw                                 bioconda::bioconductor-csaw
#   DiffBind                             bioconda::bioconductor-diffbind
#   ChIPseeker                           bioconda::bioconductor-chipseeker
#   ATACseqQC                            bioconda::bioconductor-atacseqqc
#   Gviz                                 bioconda::bioconductor-gviz
#   ggbio                                bioconda::bioconductor-ggbio
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

debut_groupe("10_epigenomique_tracks", "Épigénomique (ChIP/ATAC-seq) et visualisation de tracks génomiques")

test_pkg("csaw", {
  print(readParam(minq=20))
})

test_pkg("DiffBind", {
  data(tamoxifen_counts)
  print(tamoxifen)
})

test_pkg("ChIPseeker", {
  print(readPeakFile(getSampleFiles()[[4]]))
})

test_pkg("ATACseqQC", {
  bam <- system.file("extdata", "GL1.bam", package="ATACseqQC")
  print(head(readsDupFreq(bam)))
})

test_pkg("Gviz", {
  png(tempfile(fileext=".png"))
  plotTracks(list(GenomeAxisTrack(), AnnotationTrack(GenomicRanges::GRanges("chr1", IRanges::IRanges(100, 500)), name="test")), from=1, to=1000)
  invisible(dev.off())
})

test_pkg("ggbio", {
  png(tempfile(fileext=".png"))
  print(autoplot(GenomicRanges::GRanges("chr1", IRanges::IRanges(c(1, 50), width=30))))
  invisible(dev.off())
})

resume_tests("10_epigenomique_tracks")
if (!interactive() && !isTRUE(getOption("tests.run_all")))
  quit(status = as.integer(any(grepl("^ECHEC|^ABSENT", .tests$res$statut[.tests$res$groupe == "10_epigenomique_tracks"]))))
