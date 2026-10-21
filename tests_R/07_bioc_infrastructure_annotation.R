#!/usr/bin/env Rscript
#===============================================================================
# Tests d'installation des paquets R — Bioconductor : infrastructure et annotations
# Usage : Classes S4 de base, séquences, intervalles génomiques, bases d'annotation, import/export de formats génomiques
#
# Chaque test charge le paquet puis exécute un petit calcul réel avec ses fonctions principales.
# - Terminal          : Rscript tests_R/07_bioc_infrastructure_annotation.R
# - Jupyter / RStudio : source("tests_R/07_bioc_infrastructure_annotation.R")  (ou copier un bloc test_pkg() dans une cellule)
# - Tous les groupes  : Rscript tests_R/run_all.R
# Environnement de référence : binder/environment.yml (conda-forge + bioconda, R 4.5)
#
# Paquets (spécification conda) :
#   BiocGenerics                         bioconda::bioconductor-biocgenerics
#   S4Vectors                            bioconda::bioconductor-s4vectors
#   IRanges                              bioconda::bioconductor-iranges
#   GenomicRanges                        bioconda::bioconductor-genomicranges
#   Biostrings                           bioconda::bioconductor-biostrings
#   Biobase                              bioconda::bioconductor-biobase
#   SummarizedExperiment                 bioconda::bioconductor-summarizedexperiment
#   AnnotationDbi                        bioconda::bioconductor-annotationdbi
#   org.Hs.eg.db                         bioconda::bioconductor-org.hs.eg.db
#   org.Mm.eg.db                         bioconda::bioconductor-org.mm.eg.db
#   GO.db                                bioconda::bioconductor-go.db
#   TxDb.Hsapiens.UCSC.hg38.knownGene    bioconda::bioconductor-txdb.hsapiens.ucsc.hg38.knowngene
#   TxDb.Mmusculus.UCSC.mm10.knownGene   bioconda::bioconductor-txdb.mmusculus.ucsc.mm10.knowngene
#   EnsDb.Hsapiens.v86                   bioconda::bioconductor-ensdb.hsapiens.v86
#   GenomicFeatures                      bioconda::bioconductor-genomicfeatures
#   rtracklayer                          bioconda::bioconductor-rtracklayer
#   Rsamtools                            bioconda::bioconductor-rsamtools
#   biomaRt                              bioconda::bioconductor-biomart
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

debut_groupe("07_bioc_infrastructure_annotation", "Bioconductor : infrastructure et annotations")

test_pkg("BiocGenerics", {
  print(BiocGenerics::union(1:3, 2:5))
})

test_pkg("S4Vectors", {
  print(DataFrame(a=1:3, b=letters[1:3]))
})

test_pkg("IRanges", {
  print(reduce(IRanges(start=c(1, 5, 20), width=10)))
})

test_pkg("GenomicRanges", {
  print(GRanges("chr1", IRanges::IRanges(1, 100)))
})

test_pkg("Biostrings", {
  print(reverseComplement(DNAString("ATGCGT")))
})

test_pkg("Biobase", {
  print(ExpressionSet(matrix(rnorm(20), 4)))
})

test_pkg("SummarizedExperiment", {
  print(SummarizedExperiment(assays=list(counts=matrix(1:12, 3))))
})

test_pkg("AnnotationDbi", {
  if (requireNamespace("org.Hs.eg.db", quietly=TRUE)) print(keytypes(org.Hs.eg.db::org.Hs.eg.db))
})

test_pkg("org.Hs.eg.db", {
  print(AnnotationDbi::select(org.Hs.eg.db, keys="7157", columns="SYMBOL", keytype="ENTREZID"))
})

test_pkg("org.Mm.eg.db", {
  print(AnnotationDbi::select(org.Mm.eg.db, keys="22059", columns="SYMBOL", keytype="ENTREZID"))
})

test_pkg("GO.db", {
  print(AnnotationDbi::select(GO.db, keys="GO:0008150", columns="TERM", keytype="GOID"))
})

test_pkg("TxDb.Hsapiens.UCSC.hg38.knownGene", {
  print(head(GenomicFeatures::transcripts(TxDb.Hsapiens.UCSC.hg38.knownGene), 3))
})

test_pkg("TxDb.Mmusculus.UCSC.mm10.knownGene", {
  print(head(GenomicFeatures::transcripts(TxDb.Mmusculus.UCSC.mm10.knownGene), 3))
})

test_pkg("EnsDb.Hsapiens.v86", {
  print(ensembldb::genes(EnsDb.Hsapiens.v86, filter=AnnotationFilter::GeneNameFilter("TP53")))
})

test_pkg("GenomicFeatures", {
  if (requireNamespace("TxDb.Hsapiens.UCSC.hg38.knownGene", quietly=TRUE)) print(exonsBy(TxDb.Hsapiens.UCSC.hg38.knownGene::TxDb.Hsapiens.UCSC.hg38.knownGene, by="gene")[1:2])
})

test_pkg("rtracklayer", {
  f <- tempfile(fileext=".bed")
  export(GenomicRanges::GRanges("chr1", IRanges::IRanges(1, 100)), f)
  print(import(f))
})

test_pkg("Rsamtools", {
  print(countBam(system.file("extdata", "ex1.bam", package="Rsamtools")))
})

test_pkg("biomaRt", {
  print(head(listEnsembl()))
}, network = "accès aux serveurs Ensembl")

resume_tests("07_bioc_infrastructure_annotation")
if (!interactive() && !isTRUE(getOption("tests.run_all")))
  quit(status = as.integer(any(grepl("^ECHEC|^ABSENT", .tests$res$statut[.tests$res$groupe == "07_bioc_infrastructure_annotation"]))))
