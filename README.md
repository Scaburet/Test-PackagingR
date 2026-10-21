# Test-PackagingR

Fiabilisation du packaging des paquets R (conda-forge / bioconda / emscripten-forge) : catalogue complété, environnement Binder (repo2docker) et scripts de tests d'installation.

- `catalogue/` : catalogue TSV complété, rapport (ce qui a été fait / ce qui n'a pas marché), log des tests dans l'image repo2docker


## Contenu
- `binder/environment.yml` : env MEG-M1-A2B-2026 (CVandiedonck/MEG-M1-A2B) + tous les paquets du catalogue, **tous via conda** (conda-forge + bioconda), `r-base=4.5`.
- `binder/postBuild` : config Jupyter et IRkernel (identique à l'original), installation CRAN de `swirl` et `rehh` (absents de conda) avec vérification explicite, contrôle final de chargement. **Plus aucun `BiocManager::install()`** : DESeq2, limma, clusterProfiler, org.Mm.eg.db, etc. viennent de bioconda.
- `binder/apt.txt` : inchangé.
- `tests_R/NN_*.R` : 12 scripts de tests groupés par usage (mêmes groupes que les sections du `environment.yml`) ; `tests_R/run_all.R` les lance tous.

## Lancer les tests
- Terminal : `Rscript tests_R/run_all.R` ou `Rscript tests_R/03_visualisation.R`
- Jupyter (noyau R) / RStudio, depuis la racine du dépôt : `source("tests_R/run_all.R")` ou `source("tests_R/09_single_cell.R")`. On peut aussi copier un bloc `test_pkg("…", { … })` dans une cellule, après avoir exécuté le bloc « Fonctions de test » du script.
- Options : `options(tests.verbose = TRUE)` affiche la sortie de chaque test ; `options(tests.isolate = FALSE)` exécute les tests dans la session courante (par défaut, chaque paquet est testé dans un processus R séparé via callr, ce qui évite les masquages entre paquets).
- Sortie : une ligne par paquet (version, statut, durée), un résumé par groupe, `resultats_tests_R.csv`. Code retour 1 si un test est `ECHEC`/`ABSENT` (les statuts `ECHEC (réseau ?)` et `NON INSTALLABLE` ne comptent pas).

## Statuts attendus
- 124 OK.
- `biomaRt` : `ECHEC (réseau ?)` si les serveurs Ensembl ne sont pas joignables.
- `ensemblVEP` : `NON INSTALLABLE` (retiré de Bioconductor 3.20 ; le paquet bioconda exige R < 4.4).

## Validation effectuée (21/10/2026)
1. Résolution conda (`micromamba create --dry-run`) : OK, 939 paquets, R 4.5.3.
2. Env micromamba réel + `postBuild` + `Rscript tests_R/run_all.R` : 124 OK, biomaRt échec réseau, ensemblVEP non installable.
3. Image repo2docker (comme Binder), construite depuis `binder/` : build OK. `run_all.R` dans le conteneur donne les mêmes résultats. Exécution dans un notebook Jupyter (noyau `ir`) via `jupyter nbconvert --execute` de `source("tests_R/01_…R")` et `source("tests_R/09_…R")` : OK. Noyaux disponibles : bash, ir, python3. rstudio-server est présent.
4. Taille de l'image : environ 14 Go décompressée (3,5 Go compressée), à cause des annotations (TxDb, EnsDb, org.*.eg.db, GO.db), de Seurat et de la pile single-cell. Si c'est trop lourd pour Binder, scinder en deux environnements : un « cours » (groupes 01–08) et un « spécialisé » (groupes 09–12).

## Points d'attention
- Dans repo2docker, `env update` part de l'environnement de base de repo2docker. Sans épinglage, le solveur choisissait des versions plus anciennes (R 4.5.2, textshaping 1.0.4), et R affichait alors l'avertissement « systemfonts and textshaping have been compiled with different versions of Freetype ». Avec `r-textshaping>=1.0.5`, l'image est en R 4.5.3, l'avertissement disparaît et les tests ont été refaits : mêmes résultats. jupyterlab reste en 4.4.9 dans l'image.
- `biomaRt` exige un accès réseau à Ensembl.
- `phyloseq` est inclus. Retirez-le de `environment.yml` si le TP R7 doit le faire installer par les étudiants.
