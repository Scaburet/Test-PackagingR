#!/usr/bin/env Rscript
#===============================================================================
# Lance tous les scripts de test tests_R/NN_*.R et écrit resultats_tests_R.csv
# - Terminal : Rscript tests_R/run_all.R          (code retour 1 si un test échoue)
# - Jupyter  : source("tests_R/run_all.R")        (depuis la racine du dépôt)
# Les échecs « réseau ? » (biomaRt, httr) et « NON INSTALLABLE » (ensemblVEP) ne
# font pas échouer le code retour.
#===============================================================================
options(tests.run_all = TRUE)
f <- sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE))
dir <- if (length(f)) dirname(normalizePath(f)) else if (dir.exists("tests_R")) "tests_R" else "."
for (s in sort(list.files(dir, pattern = "^[0-9]{2}_.*\\.R$", full.names = TRUE))) source(s, local = FALSE)
res <- .tests$res
cat("\n================ RÉSUMÉ GLOBAL ================\n")
print(table(res$groupe, res$statut))
pb <- res[res$statut != "OK", ]
if (nrow(pb)) { cat("\nPaquets non OK :\n"); print(pb[, c("groupe", "paquet", "version", "statut", "message")], row.names = FALSE) }
utils::write.csv(res, "resultats_tests_R.csv", row.names = FALSE)
cat("\nRésultats écrits dans", normalizePath("resultats_tests_R.csv"), "\n")
if (!interactive()) quit(status = as.integer(any(res$statut %in% c("ECHEC", "ABSENT"))))
