#!/usr/bin/env Rscript
#===============================================================================
# Tests d'installation des paquets R — Bioconductor : RNA-seq, analyse différentielle et enrichissement
# Usage : Import de quantifications, DESeq2/edgeR/limma, GO/KEGG/GSEA
#
# Chaque test charge le paquet puis exécute un petit calcul réel avec ses fonctions principales.
# - Terminal          : Rscript tests_R/08_bioc_rnaseq_enrichissement.R
# - Jupyter / RStudio : source("tests_R/08_bioc_rnaseq_enrichissement.R")  (ou copier un bloc test_pkg() dans une cellule)
# - Tous les groupes  : Rscript tests_R/run_all.R
# Environnement de référence : binder/environment.yml (conda-forge + bioconda, R 4.5)
#
# Paquets (spécification conda) :
#   tximport                             bioconda::bioconductor-tximport
#   DESeq2                               bioconda::bioconductor-deseq2
#   edgeR                                bioconda::bioconductor-edger
#   limma                                bioconda::bioconductor-limma
#   clusterProfiler                      bioconda::bioconductor-clusterprofiler
#   fgsea                                bioconda::bioconductor-fgsea
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

debut_groupe("08_bioc_rnaseq_enrichissement", "Bioconductor : RNA-seq, analyse différentielle et enrichissement")

test_pkg("tximport", {
  f <- tempfile(fileext=".sf")
  write.table(data.frame(Name=c("t1", "t2"), Length=1000, EffectiveLength=900, TPM=c(10, 20), NumReads=c(5, 10)), f, sep="\t", quote=FALSE, row.names=FALSE)
  print(tximport(f, type="salmon", txOut=TRUE)$counts)
})

test_pkg("DESeq2", {
  dds <- makeExampleDESeqDataSet(n=100, m=4)
  dds <- DESeq(dds, quiet=TRUE)
  print(head(results(dds)))
})

test_pkg("edgeR", {
  y <- DGEList(counts=matrix(rpois(400, 20), 100), group=rep(1:2, each=2))
  y <- calcNormFactors(y)
  print(y$samples)
})

test_pkg("limma", {
  fit <- lmFit(matrix(rnorm(400), 100), cbind(1, rep(0:1, each=2)))
  print(head(topTable(eBayes(fit), coef=2)))
})

test_pkg("clusterProfiler", {
  t2g <- data.frame(term=rep(c("A", "B"), each=5), gene=as.character(1:10))
  print(enricher(as.character(1:5), TERM2GENE=t2g, pvalueCutoff=1, minGSSize=1))
})

test_pkg("fgsea", {
  data(examplePathways)
  data(exampleRanks)
  set.seed(1)
  print(head(fgsea(examplePathways, exampleRanks, maxSize=500)))
})

resume_tests("08_bioc_rnaseq_enrichissement")
if (!interactive() && !isTRUE(getOption("tests.run_all")))
  quit(status = as.integer(any(grepl("^ECHEC|^ABSENT", .tests$res$statut[.tests$res$groupe == "08_bioc_rnaseq_enrichissement"]))))
