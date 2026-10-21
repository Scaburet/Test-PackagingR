#!/usr/bin/env Rscript
#===============================================================================
# Tests d'installation des paquets R — Statistiques et modélisation
# Usage : Analyses multivariées, tests, modèles (mixtes, survie, quantile), optimisation, séries temporelles, graphes
#
# Chaque test charge le paquet puis exécute un petit calcul réel avec ses fonctions principales.
# - Terminal          : Rscript tests_R/04_statistiques_modelisation.R
# - Jupyter / RStudio : source("tests_R/04_statistiques_modelisation.R")  (ou copier un bloc test_pkg() dans une cellule)
# - Tous les groupes  : Rscript tests_R/run_all.R
# Environnement de référence : binder/environment.yml (conda-forge + bioconda, R 4.5)
#
# Paquets (spécification conda) :
#   FactoMineR                           conda-forge::r-factominer
#   factoextra                           conda-forge::r-factoextra
#   statmod                              conda-forge::r-statmod
#   pwr                                  conda-forge::r-pwr
#   ppcor                                conda-forge::r-ppcor
#   mvtnorm                              conda-forge::r-mvtnorm
#   KernSmooth                           conda-forge::r-kernsmooth
#   lmtest                               conda-forge::r-lmtest
#   quantreg                             conda-forge::r-quantreg
#   survival                             conda-forge::r-survival
#   prodlim                              conda-forge::r-prodlim
#   lme4                                 conda-forge::r-lme4
#   nloptr                               conda-forge::r-nloptr
#   minqa                                conda-forge::r-minqa
#   SparseM                              conda-forge::r-sparsem
#   DiceDesign                           conda-forge::r-dicedesign
#   forecast                             conda-forge::r-forecast
#   fracdiff                             conda-forge::r-fracdiff
#   urca                                 conda-forge::r-urca
#   igraph                               conda-forge::r-igraph
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

debut_groupe("04_statistiques_modelisation", "Statistiques et modélisation")

test_pkg("FactoMineR", {
  res <- PCA(iris[, 1:4], graph=FALSE)
  print(res$eig[1:2, ])
})

test_pkg("factoextra", {
  res <- FactoMineR::PCA(iris[, 1:4], graph=FALSE)
  png(tempfile(fileext=".png"))
  print(fviz_eig(res))
  invisible(dev.off())
})

test_pkg("statmod", {
  print(gauss.quad(5))
})

test_pkg("pwr", {
  print(pwr.t.test(d=0.5, power=0.8, sig.level=0.05))
})

test_pkg("ppcor", {
  print(pcor(mtcars[, 1:4])$estimate)
})

test_pkg("mvtnorm", {
  print(pmvnorm(upper=c(1, 1), sigma=diag(2)))
})

test_pkg("KernSmooth", {
  print(head(bkde(faithful$eruptions)$y))
})

test_pkg("lmtest", {
  print(bptest(lm(mpg ~ wt, data=mtcars)))
})

test_pkg("quantreg", {
  print(rq(mpg ~ wt, tau=0.5, data=mtcars))
})

test_pkg("survival", {
  print(survfit(Surv(time, status) ~ sex, data=lung))
})

test_pkg("prodlim", {
  print(prodlim(Hist(time, status) ~ 1, data=survival::lung))
})

test_pkg("lme4", {
  print(lmer(Reaction ~ Days + (Days | Subject), data=sleepstudy))
})

test_pkg("nloptr", {
  print(nloptr(x0=1, eval_f=function(x) (x - 2)^2, opts=list(algorithm="NLOPT_LN_BOBYQA", xtol_rel=1e-8))$solution)
})

test_pkg("minqa", {
  print(bobyqa(c(1, 1), function(x) sum((x - 3)^2))$par)
})

test_pkg("SparseM", {
  print(as.matrix.csr(diag(3)))
})

test_pkg("DiceDesign", {
  print(head(lhsDesign(10, 2)$design))
})

test_pkg("forecast", {
  print(forecast(auto.arima(AirPassengers), h=3))
})

test_pkg("fracdiff", {
  print(fracdiff(as.numeric(lh), nar=1))
})

test_pkg("urca", {
  print(summary(ur.df(as.numeric(lh))))
})

test_pkg("igraph", {
  print(make_ring(5))
})

resume_tests("04_statistiques_modelisation")
if (!interactive() && !isTRUE(getOption("tests.run_all")))
  quit(status = as.integer(any(grepl("^ECHEC|^ABSENT", .tests$res$statut[.tests$res$groupe == "04_statistiques_modelisation"]))))
