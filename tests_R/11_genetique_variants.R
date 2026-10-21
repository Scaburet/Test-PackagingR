#!/usr/bin/env Rscript
#===============================================================================
# Tests d'installation des paquets R — Génétique : variants, GWAS et génétique des populations
# Usage : VCF, filtrage/annotation de variants, Manhattan plots, génétique des populations, sélection
#
# Chaque test charge le paquet puis exécute un petit calcul réel avec ses fonctions principales.
# - Terminal          : Rscript tests_R/11_genetique_variants.R
# - Jupyter / RStudio : source("tests_R/11_genetique_variants.R")  (ou copier un bloc test_pkg() dans une cellule)
# - Tous les groupes  : Rscript tests_R/run_all.R
# Environnement de référence : binder/environment.yml (conda-forge + bioconda, R 4.5)
#
# Paquets (spécification conda) :
#   VariantAnnotation                    bioconda::bioconductor-variantannotation
#   VariantFiltering                     bioconda::bioconductor-variantfiltering
#   ensemblVEP                           bioconda::bioconductor-ensemblvep   [NON INSTALLABLE : retiré de Bioconductor 3.20 ; bioconda 1.44.0 exige R < 4.4]
#   qqman                                conda-forge::r-qqman
#   poppr                                conda-forge::r-poppr
#   rehh                                 conda-forge::r-rehh   [CRAN, installé par postBuild : absent de conda]
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

debut_groupe("11_genetique_variants", "Génétique : variants, GWAS et génétique des populations")

test_pkg("VariantAnnotation", {
  print(readVcf(system.file("extdata", "chr22.vcf.gz", package="VariantAnnotation"), "hg19"))
})

test_pkg("VariantFiltering", {
  stopifnot(is.function(VariantFilteringParam))
})

test_pkg("ensemblVEP", {
  print(VEPFlags())
  cat("Script Perl VEP trouvé :", nzchar(Sys.which("vep")), "\n")
}, not_installable = "retiré de Bioconductor 3.20 ; bioconda 1.44.0 exige R < 4.4")

test_pkg("qqman", {
  png(tempfile(fileext=".png"))
  manhattan(gwasResults)
  invisible(dev.off())
})

test_pkg("poppr", {
  data(monpop)
  print(poppr(monpop))
})

test_pkg("rehh", {
  data(haplohh_cgu_bta12)
  print(head(scan_hh(haplohh_cgu_bta12)))
})

resume_tests("11_genetique_variants")
if (!interactive() && !isTRUE(getOption("tests.run_all")))
  quit(status = as.integer(any(grepl("^ECHEC|^ABSENT", .tests$res$statut[.tests$res$groupe == "11_genetique_variants"]))))
