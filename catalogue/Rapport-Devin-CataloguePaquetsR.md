# R package catalogue: summary of the work (2026-10-21)

Deliverable: `PaquetsR-packaging-CataloguePaquetsR-complete.tsv`. It has the same 127 lines (header + 126 packages) as your file, UTF-8, CRLF, with 2 columns added (Y, Z).

## 1. What I did

**Sources used.** For every package I queried the official sources programmatically, not by hand:
- the CRAN package index;
- Bioconductor 3.23 (current release, for R 4.6). I also checked the devel branch (3.24) and the older 3.19 release (only needed for ensemblVEP);
- the anaconda.org API for conda-forge and bioconda: all versions, platforms, `r-base` constraints and upload dates;
- the GitHub API: releases, tags, and the `DESCRIPTION` file of the default branch.

**Versions, columns J–L (126 packages).**
- **K:** the CRAN or Bioconductor release version.
- **L:** the highest version actually published on conda-forge or bioconda. I don't use the "latest" field anaconda.org displays, because it is wrong for 7 packages (see section 2).
- **J:** the latest GitHub release when one exists. Otherwise it is the version in the development `DESCRIPTION`, marked "(devel)" (45 packages). It is "N/A + reason" when there is no official GitHub repository (24 packages, mostly Bioconductor packages hosted only on git.bioconductor.org, or CRAN packages with only the read-only `github.com/cran` mirror).
- I also updated 3 values you had already filled (rmarkdown, knitr, Rcpp), which were out of date.

**Descriptors, columns C–H (lines 97–127, 31 packages).**
- **Priorité / Type:** for each package I computed which catalogue packages depend on it, directly or indirectly (CRAN/Bioconductor `Depends/Imports/LinkingTo`). Priority is inherited from the most important dependent package. This dependency list is written in column Q when Q was empty.
- **Description:** written in French.
- **Classes / Fonctions principales:** I checked these against the namespace exports of the installed package, which led me to fix 4 functions that did not exist (see section 2).
- **Type de problème:** based on what the package compiles or links (C/C++/Fortran, OpenSSL, sockets, subprocesses, external CLIs) and on WASM/emscripten-forge limitations.

**Test commands.**
- **Column M:** R code to paste into a Jupyter R cell. It loads the package, runs a small real use of its main functionality, then prints `<pkg> <version> : test OK`.
- **Column Y (new):** the same test as an `Rscript -e '…'` command for a terminal.
- **Column Z (new):** the result I obtained.

**Validation.**
- I built a micromamba environment (R 4.5.3, conda-forge + bioconda) containing all the packages in column I. rehh came from CRAN because it is not on conda.
- I ran all 126 tests through `micromamba run`, which is equivalent to an activated environment.
- Result: **124 OK, 1 network failure (biomaRt), 1 not installable (ensemblVEP).**
- I also checked the generated file automatically: 26 columns on every line, no empty cell in J–L or M, nothing empty in C–H for lines 97–127, and no single quote inside the commands (which would break `Rscript -e '…'`).

## 2. What went wrong, and why

### a) Problems in the table or in the upstream sources (need a decision from you)

| Problem | Why it happens | What I did |
|---|---|---|
| **ensemblVEP** can't be installed | Removed from Bioconductor in release 3.20 (last version 1.46.0, Bioc 3.19). The bioconda build 1.44.0 requires `r-base >=4.3,<4.4`. | Versions filled with an explanation; no test possible with R ≥ 4.4. Suggest dropping it or replacing it (calling the `vep` CLI directly). |
| **biomaRt**: test fails | The Ensembl servers return HTTP 403 to my VM (network restriction). The package itself installs and loads. | Marked "network failure" in Z. Please rerun from a normal connection. |
| **rehh** missing from conda | No recipe on conda-forge or bioconda: column I (`conda-forge::r-rehh`) points to something that doesn't exist. | Tested the CRAN version (3.2.3, compiled). A conda-forge recipe is needed. |
| `r-kernelsmooth` (line 121) | Wrong name: the conda package is `r-kernsmooth`. | Fixed in I. Line 20 (readxl): I was empty, now filled. |
| Misspelled package names in E | knitR, Rcolorbrewer, purr, ClusterProfiler, ComplexHeatMap, factominer, rppcor, BiomaRt, seurat, DADA2. `library()` is case-sensitive. | E left unchanged; commands use the correct names (knitr, RColorBrewer, purrr, clusterProfiler, ComplexHeatmap, FactoMineR, ppcor, biomaRt, Seurat, dada2). |
| GitHub links that return 404 (column X) | Repositories that don't exist under that account: org.Hs.eg.db, org.Mm.eg.db, FactoMineR, statmod, edgeR, SingleCellExperiment, scater, DiffBind. | Not changed; to fix. |
| Links that point to another package | Probably copy-paste mistakes: Gviz → ComplexHeatmap (X); limma → DESeq2 (Q and X); randomForest → qqman (Q); corrplot → pwr (W). | Not changed; to fix. |
| Version lag | bioconda mostly publishes the Bioconductor 3.22 builds while 3.23 is current. Some CRAN packages are ahead of conda-forge (e.g. Seurat, tidymodels). 34 packages have K ≠ L. | Versions shown as they are. This is the main reliability point for your packaging work. |
| Wrong "latest version" on anaconda.org | The `latest_version` field is outdated for r-mvtnorm, r-rcpparmadillo, r-survival, r-lme4, r-nnet, r-ipred, r-kernsmooth (e.g. 3.2_9 shown for r-survival when 3.8_12 exists). | L uses the maximum over all published versions. |
| "Version Github" is ambiguous | Many projects publish no GitHub release; the `DESCRIPTION` on GitHub is a development version (`.9000`, odd Bioconductor numbers). | Marked "(devel)" or "N/A + reason". |
| WASM limitations | httpuv (sockets), processx (subprocesses), quarto (external CLI), ensemblVEP (Perl) can't work as-is in emscripten-forge. | Noted in H / "Type de problème". |

### b) Problems in my own process (all fixed before delivery)

- **Missing tools:** R and conda were not installed on my machine. I installed micromamba and built the full environment, which was the longest step.
- **GitHub token:** the `Token_for_Devin` secret is not a valid GitHub token (401 "Bad credentials"). I used the already-configured GitHub CLI instead. No impact on the results.
- **Non-existent functions in my first descriptors:** `eigen_version()` (RcppEigen), `predict.nnet()` (nnet, not exported), `dmax()` (DiceDesign, really `dmaxDesign()`), and `endsWith/trimws/lengths` (backports, not exported in recent versions). The check against the namespace exports caught these, and they are fixed.
- **Wrong tests on the first run:**
  - **DiffBind:** the dataset is called `tamoxifen`, not `tamoxifen_counts`.
  - **quarto:** failed when only `PATH` was modified, because it needs the variables set when the environment is activated.
  - Both were fixed and rerun.
- **Table assembly:** my script crashed on 2 rows whose package name couldn't be resolved automatically (KernSmooth, because of the wrong conda name, and ensemblVEP, because it is missing from Bioconductor). I fixed the script and reran all the checks.

### c) Remaining limitations
- The tests use R 4.5.3 (the newest R on conda-forge with all packages available). Bioconductor 3.23 officially targets R 4.6.
- The descriptors and Priorité values for lines 97–127 are my proposal, based on the dependency graph; please review them.
- The versions reflect the state of the repositories on 2026-10-21.
