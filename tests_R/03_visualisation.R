#!/usr/bin/env Rscript
#===============================================================================
# Tests d'installation des paquets R — Visualisation
# Usage : Graphiques statiques et interactifs, palettes, heatmaps
#
# Chaque test charge le paquet puis exécute un petit calcul réel avec ses fonctions principales.
# - Terminal          : Rscript tests_R/03_visualisation.R
# - Jupyter / RStudio : source("tests_R/03_visualisation.R")  (ou copier un bloc test_pkg() dans une cellule)
# - Tous les groupes  : Rscript tests_R/run_all.R
# Environnement de référence : binder/environment.yml (conda-forge + bioconda, R 4.5)
#
# Paquets (spécification conda) :
#   ggplot2                              conda-forge::r-ggplot2
#   patchwork                            conda-forge::r-patchwork
#   ggrepel                              conda-forge::r-ggrepel
#   ggtext                               conda-forge::r-ggtext
#   ggfortify                            conda-forge::r-ggfortify
#   ggpmisc                              conda-forge::r-ggpmisc
#   ggpubr                               conda-forge::r-ggpubr
#   plotly                               conda-forge::r-plotly
#   gplots                               conda-forge::r-gplots
#   RColorBrewer                         conda-forge::r-rcolorbrewer
#   corrplot                             conda-forge::r-corrplot
#   pheatmap                             conda-forge::r-pheatmap
#   ComplexHeatmap                       bioconda::bioconductor-complexheatmap
#   EnhancedVolcano                      bioconda::bioconductor-enhancedvolcano
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

debut_groupe("03_visualisation", "Visualisation")

test_pkg("ggplot2", {
  p <- ggplot(mtcars, aes(wt, mpg)) + geom_point()
  ggsave(tempfile(fileext=".png"), p, width=4, height=3)
})

test_pkg("patchwork", {
  library(ggplot2)
  p <- ggplot(mtcars, aes(wt, mpg)) + geom_point()
  png(tempfile(fileext=".png"))
  print(p + p)
  invisible(dev.off())
})

test_pkg("ggrepel", {
  library(ggplot2)
  png(tempfile(fileext=".png"))
  print(ggplot(mtcars, aes(wt, mpg, label=rownames(mtcars))) + geom_text_repel())
  invisible(dev.off())
})

test_pkg("ggtext", {
  library(ggplot2)
  png(tempfile(fileext=".png"))
  print(ggplot(mtcars, aes(wt, mpg)) + geom_point() + labs(title="**gras** et *italique*") + theme(plot.title=element_markdown()))
  invisible(dev.off())
})

test_pkg("ggfortify", {
  png(tempfile(fileext=".png"))
  print(autoplot(prcomp(iris[, 1:4])))
  invisible(dev.off())
})

test_pkg("ggpmisc", {
  png(tempfile(fileext=".png"))
  print(ggplot(mtcars, aes(wt, mpg)) + geom_point() + stat_poly_line() + stat_poly_eq())
  invisible(dev.off())
})

test_pkg("ggpubr", {
  png(tempfile(fileext=".png"))
  print(ggscatter(mtcars, x="wt", y="mpg", add="reg.line") + stat_cor())
  invisible(dev.off())
})

test_pkg("plotly", {
  p <- plotly::plot_ly(mtcars, x=~wt, y=~mpg, type="scatter", mode="markers")
  stopifnot(inherits(p, "plotly"))
})

test_pkg("gplots", {
  png(tempfile(fileext=".png"))
  gplots::heatmap.2(as.matrix(mtcars), trace="none")
  invisible(dev.off())
})

test_pkg("RColorBrewer", {
  print(RColorBrewer::brewer.pal(5, "Set1"))
})

test_pkg("corrplot", {
  png(tempfile(fileext=".png"))
  corrplot(cor(mtcars))
  invisible(dev.off())
})

test_pkg("pheatmap", {
  png(tempfile(fileext=".png"))
  pheatmap(matrix(rnorm(100), 10))
  invisible(dev.off())
})

test_pkg("ComplexHeatmap", {
  png(tempfile(fileext=".png"))
  draw(Heatmap(matrix(rnorm(100), 10)))
  invisible(dev.off())
})

test_pkg("EnhancedVolcano", {
  res <- data.frame(log2FoldChange=rnorm(100), pvalue=runif(100), row.names=paste0("g", 1:100))
  png(tempfile(fileext=".png"))
  print(EnhancedVolcano(res, lab=rownames(res), x="log2FoldChange", y="pvalue"))
  invisible(dev.off())
})

resume_tests("03_visualisation")
if (!interactive() && !isTRUE(getOption("tests.run_all")))
  quit(status = as.integer(any(grepl("^ECHEC|^ABSENT", .tests$res$statut[.tests$res$groupe == "03_visualisation"]))))
