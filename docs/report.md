# Viability Analysis of SAES (`saesV2`) for the *Journal of Statistical Software* (JSS)

> [!IMPORTANT]
> **Executive verdict:**
>
> - **In its baseline state (`saesV2 v0.3.1`):** **NOT ready for JSS**, with a very high risk of **editorial rejection (*decline*) or review rejection (*reject*)**, due to **verifiable statistical defects in the codebase**, gaps between recommended and implemented tests, lack of cross-validation against reference implementations, and absence of formal package documentation. Since **JSS explicitly prohibits resubmitting rejected manuscripts**, submitting before addressing these gaps would be strategically counterproductive.
> - **In the medium term (after statistical hardening and positioning toward `v1.0.0`):** **YES — it has the architectural foundation and realistic prospects in JSS**, provided mathematical rigor is fixed, methodological and extensibility gaps are closed, and the submission is positioned under the **unified statistical infrastructure + reproducible reporting archetype** (analogous to `marginaleffects`, `texreg`, or `RESI`) centered on the pure Python package.

---

## 1. Corpus Analyzed Directly from `jstatsoft.org`

To ensure an evidence-based assessment rather than generalities, `https://www.jstatsoft.org/` was inspected directly, downloading and analyzing:

1. **Complete official JSS editorial policies:**
   - *Information on Mission* (`/index.php/jss/mission`)
   - *Information for Authors* (`/authors`)
   - *Style Guide* (`/style`) and *Submissions Checklist* (`/about/submissions`)
2. **8 full articles published in JSS as PDFs (2013–2026)** plus an official Python replication script (`v117i03`, 516 lines), selected to cover the three archetypes most relevant to SAES: recent Python packages (2022–2026), unified inference/effect-size/table infrastructure, and non-parametric multiple comparisons.

| Article (Vol./Issue)                                                                                          | Year | Language   | Pages | Figs / Tabs | JSS Archetype                                                | Direct Benchmark Relevance for SAES                                                                                                                                                                                                                                                                                                                                |
| :------------------------------------------------------------------------------------------------------------ | :--: | :--------- | :---: | :---------: | :----------------------------------------------------------- | :----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **`asgl`** ([v117i03](https://www.jstatsoft.org/article/view/v117i03)) — Mendez-Civieta et al.                | 2026 | Python     |  26   |    4 / 3    | Statistical modeling in Python                               | Current (2026) JSS standard for Python: formal theory, Python/R comparison table, `scikit-learn` integration, timing benchmarks, *Limitations* section, *Computational details*, and a single deterministic replication script (~4 min).                                                                                                                             |
| **`OGBoost`** ([v117i05](https://www.jstatsoft.org/article/view/v117i05)) — Sharabiani et al.                 | 2026 | Python     |  38   |   1 / 18    | Statistical/ML algorithm in Python                           | Thorough review of prior software (Python and R), modular/extensible architecture, empirical evaluation with formal statistical tests across 17 public datasets, and exact environment/dependency table.                                                                                                                                                           |
| **`NUBO`** ([v114i01](https://www.jstatsoft.org/article/view/v114i01)) — Diessner et al.                      | 2025 | Python     |  28   |    5 / 3    | Bayesian optimization in Python                              | Shows how to justify a "transparent and compact" Python package (1,322 LOC) against large frameworks (`BoTorch`, `SMAC3`) via capability + LOC tables, honest empirical benchmarks, and notebook/script reproducibility.                                                                                                                                             |
| **`RESI`** ([v112i03](https://www.jstatsoft.org/article/view/v112i03)) — Jones et al.                         | 2025 | R          |  27   |    2 / 2    | Effect sizes & inference                                     | Direct benchmark for *effect sizes*: explains why classic analytic CIs fail, provides robust bootstrap CIs, cross-index conversions, and detailed comparisons against SAS, SPSS, Stata, and 9 R packages.                                                                                                                                                          |
| **`marginaleffects`** ([v111i09](https://www.jstatsoft.org/article/view/v111i09)) — Arel-Bundock et al.       | 2024 | R & Python |  32   |    4 / 2    | **Unified analysis/contrasts infrastructure**                | **Best strategic mirror for SAES:** does not invent a new estimator; proposes a **unifying conceptual framework** (5 design decisions), minimal consistent API, extensibility via 4 methods, *tidy* outputs, online book (25+ chapters), and **thousands of numerical cross-checks** against `emmeans` and Stata.                                                    |
| **`Bambi`** ([v103i15](https://www.jstatsoft.org/article/view/v103i15)) — Capretto et al.                     | 2022 | Python     |  29   |   10 / 4    | High-level Python interface                                  | Shows when JSS accepts a high-level wrapper (`PyMC`/`ArviZ`): requires idiomatic syntax, theoretically justified defaults (weakly informative priors), access to underlying objects, and complete documentation (ReadTheDocs + notebooks).                                                                                                                         |
| **`nparcomp`** ([v064i09](https://www.jstatsoft.org/article/view/v064i09)) — Konietschke et al.               | 2015 | R          |  17   |    3 / 0    | **Non-parametric multiple comparisons**                      | Same mathematical neighborhood as SAES: relative effects $p = P(X<Y) + \frac{1}{2}P(X=Y)$ (identical to Vargha–Delaney $A_{12}$), non-parametric Behrens–Fisher, multiple contrasts with compatible simultaneous confidence intervals (SCIs). Sets the theoretical rigor expected by JSS editors (Hothorn is coauthor and on the JSS editorial board).             |
| **`texreg`** ([v055i08](https://www.jstatsoft.org/article/view/v055i08)) — Leifeld                            | 2013 | R          |  24   |    1 / 7    | **LaTeX/HTML table export**                                  | Direct mirror for SAES's table engine: defines 6 explicit design requirements, compares point-by-point against `xtable`/`stargazer`/`apsrtable`/`memisc`, exposes internal architecture, and shows users how to extend the package with new output formats.                                                                                                          |

---

## 2. What JSS Actually Requires (Common Patterns Across All 8 Articles)

Cross-referencing JSS official policies with the 8 published PDFs highlights **7 non-negotiable criteria**:

1. **Inseparable *Software + Article* unity (without requiring novel pure-methodology invention):**
   - JSS explicitly expects statistical methodologies to be **already published** in the literature, while the paper contributes a **comprehensive implementation of a broad class of procedures** or **reusable computational infrastructure** featuring **substantial software innovation**.
   - It does not publish "supplementary code" or thin wrappers lacking clear architectural value.
2. **Line-by-line statistical scrutiny:**
   - JSS reviewers are leading computational statisticians (several editors are foundational authors in non-parametric inference, multiple testing, and statistical software). They inspect **both the manuscript equations and the actual source code** for errors in formulas, assumptions, degrees of freedom, tie corrections, or random seeds.
3. **Systematic and honest ecosystem comparison (Python and R):**
   - All recent articles (`asgl` Table 1, `NUBO` Tables 1–2, `marginaleffects` Sec. 2, `RESI` Sec. 1, `texreg` Sec. 3, `OGBoost` Sec. 1.2–1.3) include a thorough comparison—typically a feature matrix—against competitors across **all relevant languages**, explicitly discussing **strengths and limitations** (including runtime behavior).
4. **Idiomatic, extensible, lightweight software design:**
   - In Python (`asgl`, `OGBoost`, `NUBO`, `Bambi`, `marginaleffects`), packages follow scientific ecosystem conventions (PEP 8, result objects with `summary`/`plot`/tidy DataFrames, `scikit-learn`/`pandas`/`numpy` interop, documented extension mechanisms for custom tests, contrasts, or renderers without editing core internals).
5. **Exhaustive numerical validation against reference implementations:**
   - `marginaleffects` checks numerical outputs against `emmeans` and Stata via thousands of assertions; `asgl`, `NUBO`, and `OGBoost` validate against `scikit-learn`, `BoTorch`, `SMAC3`, etc. Testing that a thin wrapper around `scipy.stats` matches `scipy.stats` is not enough.
6. **Strict reproducibility and professional packaging:**
   - **GPL-2, GPL-3, or GPL-compatible license** (hard requirement).
   - Distribution on a standard package index (**PyPI**, not GitHub only) and **complete formatted documentation** (API reference manual, tutorials, reproducible examples).
   - Manuscript formatted strictly in **LaTeX with `jss.cls`** (`\proglang{}`, `\pkg{}`, `\code{}`, title styling, BibTeX citations) plus a **single deterministic replication script** reproducing *every* number, table, and figure in under ~1 hour on a standard desktop.
7. **No-resubmission rule and long review timelines:**
   - Submission-to-acceptance times in the analyzed corpus typically range from **1 to 2 years** (though `OGBoost` 2025–2026 was faster).
   - **Manuscripts rejected by JSS can never be resubmitted.** Therefore, submission should only occur once the package is thoroughly hardened both statistically and technically.

---

## 3. Technical & Statistical Audit of `saesV2` (`v0.3.1` Baseline)

The audit examined the entire core of [`saesV2`](file:///Users/emiliorodrigocarreiravillalta/Desktop/SAES/saesV2) (~13,000 lines across `src/` and `tests/`, 50 `pytest` tests, 85% coverage) as well as companion repositories [`saes-ai`](file:///Users/emiliorodrigocarreiravillalta/Desktop/SAES/saes-ai), [`saes-ui`](file:///Users/emiliorodrigocarreiravillalta/Desktop/SAES/saes-ui), and [`saes-plugins`](file:///Users/emiliorodrigocarreiravillalta/Desktop/SAES/saes-plugins).

### 3.1. Genuine Structural Strengths (What Already Aligns Well with JSS)

| Dimension                                 | Repository Evidence                                                                                                                                                                                                                                                                                                                                                    |        JSS Assessment         |
| :---------------------------------------- | :--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | :---------------------------: |
| **Open-source license**                   | GNU **GPL v3.0** across all 5 repositories ([LICENSE](file:///Users/emiliorodrigocarreiravillalta/Desktop/SAES/saesV2/LICENSE)).                                                                                                                                                                                                                                       |     ✅ 100% compliant         |
| **Layered architecture & strict typing**  | Clean separation (`domain`, `io`, `validation`, `stats`, `app`, `reports`, `visualization`, `server`), immutable Pydantic V2 models ([models.py](file:///Users/emiliorodrigocarreiravillalta/Desktop/SAES/saesV2/src/saesV2/domain/models.py)), `mypy --strict`, `py.typed`, optional extras `[viz]` and `[api]`.                                                       |   ✅ Strong foundation        |
| **End-to-end workflow coverage**          | Covers the full stochastic algorithm evaluation pipeline: *tidy* schema + validation → assumption exploration → parametric/non-parametric testing → effect sizes → multi-problem rankings (Friedman–Nemenyi & Bayesian) → Dolan–Moré profiles → power analysis → LaTeX/PDF/DOCX/HTML/MD export and FAIR artifacts.                                                       |    ✅ Clear topical fit       |
| **Alignment with JSS mission**            | Implements established benchmark methodologies from the literature (Demšar 2006, García & Herrera 2008, Dolan & Moré 2002, Benavoli et al. 2017, Vargha & Delaney 2000)—precisely the kind of corpus JSS seeks to unify in reproducible software.                                                                                                                     |        ✅ In scope            |
| **Initial extensibility**                 | Abstract interfaces `StatisticalTest` ([base.py](file:///Users/emiliorodrigocarreiravillalta/Desktop/SAES/saesV2/src/saesV2/stats/base.py)) and `PlotterRegistry` ([registry.py](file:///Users/emiliorodrigocarreiravillalta/Desktop/SAES/saesV2/src/saesV2/visualization/registry.py)).                                                                                 | ⚠️ Good start, under-utilized |

---

### 3.2. Critical JSS-Blocking Findings (8 Verified Code Defects at `v0.3.1`)

> [!CAUTION]
> The findings below were **concrete defects verified in the `v0.3.1` baseline codebase**. In a JSS review, any of items 1 through 5 would trigger rejection on grounds of statistical incorrectness.

#### 1. Broken/Inconsistent Decision Engine & Spurious Pairing Inference (`paired`)

- In [decision.py](file:///Users/emiliorodrigocarreiravillalta/Desktop/SAES/saesV2/src/saesV2/stats/decision.py#L31-L59), `TestDecisionEngine.select_test()` (used by `saesV2.analyze()`) **never checked normality (Shapiro–Wilk) or selected non-parametric tests** (`MannWhitneyUTest`, `WilcoxonSignedRankTest`, `KruskalWallisTest`): it always selected parametric tests (`t`-test or ANOVA). Meanwhile, `_run_omnibus_for_groups(..., test_type="auto")` in [tables.py](file:///Users/emiliorodrigocarreiravillalta/Desktop/SAES/saesV2/src/saesV2/stats/tables.py#L196-L222) did route by normality, and the methodology guide ([SKILL.md](file:///Users/emiliorodrigocarreiravillalta/Desktop/SAES/saes-plugins/plugins/saes/skills/saes-methodology/SKILL.md#L27-L37)) claimed automatic routing chose non-parametric tests.
- Moreover, `is_paired_data()` ([decision.py](file:///Users/emiliorodrigocarreiravillalta/Desktop/SAES/saesV2/src/saesV2/stats/decision.py#L14-L20)) declared two algorithms **statistically paired** merely because they shared `run_id = 0, 1, ..., 29`. In metaheuristic benchmarking (e.g., NSGA-II vs. MOEA/D on ZDT1 across 30 independent runs), `run_id` is an **independent** replicate index, not paired observations (unless Common Random Numbers or identical cross-validation folds are used). The same issue occurred in [profiles.py](file:///Users/emiliorodrigocarreiravillalta/Desktop/SAES/saesV2/src/saesV2/stats/profiles.py#L199-L200) and [power.py](file:///Users/emiliorodrigocarreiravillalta/Desktop/SAES/saesV2/src/saesV2/stats/power.py#L209) by assuming pairing whenever `len(v1) == len(v2)`.
- **Additional methodological note (pre-testing bias):** JSS statisticians are rightly critical of "automatic routing via preliminary normality/Levene tests" (see Zimmerman 2004; Rochon et al. 2012), as conditioning the primary test on Shapiro–Wilk/Levene distorts nominal Type I error rates. Any automated selector must be **transparent, optional, and explicitly caveated** in documentation and the manuscript (never silently enforced).

#### 2. Non-Faithful (Heuristic) Implementation of Benavoli et al. (2017)

- In [ranking.py](file:///Users/emiliorodrigocarreiravillalta/Desktop/SAES/saesV2/src/saesV2/stats/ranking.py#L403-L434), `BayesianRankingTest` explicitly cited *Benavoli et al. (2017)* while introducing unjustified mathematical alterations:
  - **Artificial effective sample size cap ([ranking.py](file:///Users/emiliorodrigocarreiravillalta/Desktop/SAES/saesV2/src/saesV2/stats/ranking.py#L404)):** `eff_weight = 1.0 if n_blocks <= 12 else (12.0 / float(n_blocks))` down-weighted observations when $N > 12$ "to keep informative scatter in the posterior cloud". This **invalidated Bayesian posterior inference** (freezing posterior concentration as if there were never more than 12 instances).
  - **Altered prior in Bayesian Signed-Rank ([ranking.py](file:///Users/emiliorodrigocarreiravillalta/Desktop/SAES/saesV2/src/saesV2/stats/ranking.py#L419-L428)):** In Benavoli et al. (2017), the Dirichlet Process $\mathrm{DP}(s, \delta_{z_0})$ adds a **single** pseudo-observation $z_0 = 0$ with strength $s$ (e.g., $s = 1$ or $0.5$). The baseline code injected **three** fabricated pseudo-observations `[-spread, 0.0, spread]` with weights `[0.5, 0.5, 0.5]`.
  - **ROPE forced to relative differences:** Computed relative differences $(a-b)/((|a|+|b|)/2)$ without allowing an exact absolute `rope` in metric units (as in `baycomp` / Benavoli et al. 2017, e.g., $\pm 0.01$ in accuracy).
  - **Rank bootstrap vs. Plackett–Luce:** `prob_best` probabilities in [ranking.py](file:///Users/emiliorodrigocarreiravillalta/Desktop/SAES/saesV2/src/saesV2/stats/ranking.py#L330-L337) came from a Dirichlet bootstrap over Friedman ranks rather than a formal Bayesian ranking model such as Plackett–Luce (Calvo et al. 2018).
  - **Inconsistent approximations in `tables.py`:** `_fast_bayesian_pair_probs` and `_fast_bayesian_summary_probs` ([tables.py](file:///Users/emiliorodrigocarreiravillalta/Desktop/SAES/saesV2/src/saesV2/stats/tables.py#L40-L135)) used parametric Normal/$t$ distributions over **cross-instance means**, contradicting `BayesianRankingTest` and violating cross-instance incommensurability.

#### 3. Statistically Invalid Kolmogorov–Smirnov Test with Estimated Parameters

- In [explorer.py](file:///Users/emiliorodrigocarreiravillalta/Desktop/SAES/saesV2/src/saesV2/stats/explorer.py#L142-L146), data were standardized using **sample** mean and standard deviation (`z_scores = (arr - mean_v) / std_v`) and passed to `stats.kstest(z_scores, "norm")`.
- Applying the standard Kolmogorov–Smirnov null distribution when $\mu$ and $\sigma$ are estimated from the sample produces **incorrect (severely conservative) $p$-values**. The **Lilliefors test** (or Anderson–Darling for normality) must be used instead.

#### 4. Post-Hoc (Observed) Power Fallacy & Inconsistencies in `power.py`

- In [power.py](file:///Users/emiliorodrigocarreiravillalta/Desktop/SAES/saesV2/src/saesV2/stats/power.py#L160-L272), `compute_post_hoc_power_audit()` computed "achieved/observed power" from the sample Cohen's $d$ and issued recommendations based on whether that value fell below $0.70$.
- In academic statistics, it is well established (Hoenig & Heisey, 2001, *The American Statistician*) that observed power is a 1-to-1 function of the observed $p$-value and **adds no independent information regarding Type II error risk**. For JSS, this must be reframed around **a priori power**, **sensitivity analysis (Minimum Detectable Effect Size, MDES)**, and/or **equivalence testing (TOST)**.
- In addition, line 209 of [power.py](file:///Users/emiliorodrigocarreiravillalta/Desktop/SAES/saesV2/src/saesV2/stats/power.py#L200-L214) computed $d$ with an **independent** pooled SD (`pooled_sd`), passed `paired=(n1 == n2)` to `calculate_statistical_power`, and obtained the $p$-value via an **independent** Welch $t$-test (`equal_var=False`): three mutually incompatible formulas inside the same loop.

#### 5. Mathematical Omissions in Friedman & Independence Violation in `all-metrics`

- **Missing tie correction in Friedman ([ranking.py](file:///Users/emiliorodrigocarreiravillalta/Desktop/SAES/saesV2/src/saesV2/stats/ranking.py#L241-L245)):** Average ranks were used for ties (`method="average"`), but the $\chi^2_F$ statistic omitted the tie-correction denominator (disagreeing with `scipy.stats.friedmanchisquare` and R's `friedman.test`).
- **Dependent blocks in `metric="all-metrics"` ([ranking.py](file:///Users/emiliorodrigocarreiravillalta/Desktop/SAES/saesV2/src/saesV2/stats/ranking.py#L113-L137)):** Stacking multiple metrics on the same instances as if they were independent blocks ($N_{\text{blocks}} = N_{\text{inst}} \times N_{\text{metrics}}$) violated block independence and **artificially shrank the Critical Distance (CD)**.

#### 6. Inconsistencies in Global Tables & Dolan–Moré Profiles

- **Unblocked global ANOVA / Kruskal–Wallis on cross-instance means ([tables.py](file:///Users/emiliorodrigocarreiravillalta/Desktop/SAES/saesV2/src/saesV2/stats/tables.py#L662-L685)):** Executed `OneWayANOVA`, `WelchANOVA`, and `KruskalWallisTest` directly on per-instance mean vectors, ignoring both the blocked design (same instances evaluated by all algorithms) and cross-problem incommensurability (which [explorer.py](file:///Users/emiliorodrigocarreiravillalta/Desktop/SAES/saesV2/src/saesV2/stats/explorer.py#L379) itself warned against).
- **Multiplicity & win direction in W/T/L ([profiles.py](file:///Users/emiliorodrigocarreiravillalta/Desktop/SAES/saesV2/src/saesV2/stats/profiles.py#L198-L221), [tables.py](file:///Users/emiliorodrigocarreiravillalta/Desktop/SAES/saesV2/src/saesV2/stats/tables.py#L989)):** Performed $\binom{k}{2} \times N$ per-instance tests without multiplicity adjustment and determined win/loss direction using the **mean** (`np.mean`) after a rank-based non-parametric test (Wilcoxon/Mann–Whitney), where mean direction can contradict the median or $A_{12}$.

#### 7. Methodological Gap: Recommended Yet Unimplemented Methods & Depth

- In [explorer.py](file:///Users/emiliorodrigocarreiravillalta/Desktop/SAES/saesV2/src/saesV2/stats/explorer.py#L480-L549), SAES recommended **Dunn**, **Games–Howell**, and **Tukey HSD**, yet **none existed in `saesV2`**.
- Standard algorithm-evaluation procedures were missing (several of which were even present in SAES v1 or `scmamp`):
  - **Alternative blocked omnibus tests:** Friedman Aligned-Ranks, Quade (García et al., 2010), Repeated-Measures ANOVA (RM-ANOVA with Greenhouse–Geisser correction).
  - **Powerful *all-pairs* and *1-vs-all* post-hoc procedures:** Bergmann–Hommel, Shaffer, Finner, Holland, Rom, Li, Conover–Iman, Dunn, Tukey HSD, Games–Howell, Dunnett.
  - **Full Bayesian suite:** Correlated $t$-test (Nadeau & Bengio / Benavoli et al. 2017), multi-dataset hierarchical Bayesian model (Corani et al. 2017), and Bayesian Plackett–Luce (Calvo et al. 2018).
  - **Confidence intervals on effect sizes:** `EffectSize` ([models.py](file:///Users/emiliorodrigocarreiravillalta/Desktop/SAES/saesV2/src/saesV2/domain/models.py#L119-L120)) declared `ci_lower` and `ci_upper`, but **no test populated them** (compare with `RESI` v112i03 and `nparcomp` v064i09).

#### 8. Python Packaging Hygiene, Technical Debt & Documentation (JSS Software Scrutiny)

- **Non-idiomatic package name:** `saesV2` violates PEP 8 (requiring `ignore = ["N999"]` in [pyproject.toml](file:///Users/emiliorodrigocarreiravillalta/Desktop/SAES/saesV2/pyproject.toml#L66)). JSS packages publish clean, stable names (`saes`, `asgl`, `ogboost`, `marginaleffects`, `bambi`).
- **Metadata & dependencies in [pyproject.toml](file:///Users/emiliorodrigocarreiravillalta/Desktop/SAES/saesV2/pyproject.toml):** Missing `license`, `classifiers`, `urls`, and named authors (only `"SAES Team"`). Listed `statsmodels>=0.14.0` as a hard dependency despite **0 imports in `src/`**, while `export_statistical_table(..., export_format="pdf")` ([tables.py](file:///Users/emiliorodrigocarreiravillalta/Desktop/SAES/saesV2/src/saesV2/stats/tables.py#L2215)) imported `matplotlib` despite it living in optional `[viz]`.
- **Polish bugs:** Duplicated cell (identical Sections 5 and 6) in the Jupyter Notebook generated by [reproducibility.py](file:///Users/emiliorodrigocarreiravillalta/Desktop/SAES/saesV2/src/saesV2/reports/reproducibility.py#L254-L295); monolithic 2,266-line `tables.py` mixing statistics, LaTeX, HTML, DOCX XML, and PDF; **603 warnings** in `pytest` (mainly Seaborn/Matplotlib deprecations).
- **Insufficient documentation & numerical verification for JSS:** No formatted documentation site (Sphinx/MkDocs/ReadTheDocs), tutorials, or user vignettes; the 50 baseline tests were mostly unit/smoke checks and trivial `scipy.stats` comparisons, without **systematic cross-validation** against R (`scmamp`, `PMCMRplus`, `nparcomp`, `rstatix`) or `baycomp`/`autorank`.

---

## 4. Competitive Landscape & Strategic Positioning

One of the most frequent reasons for JSS rejection is **failing to demonstrate substantial software innovation over already-published packages**. SAES competes in the following landscape:

| Package               | Language   | Venue                    | Primary Focus                                                                                                             | Potential Differentiating Contribution of SAES                                                                                                                                                                                                           |
| :-------------------- | :--------- | :----------------------- | :------------------------------------------------------------------------------------------------------------------------ | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **`scmamp`**          | R          | *The R Journal* (2016)   | Friedman, Aligned-Ranks, Quade, post-hoc (Bergmann–Hommel, Holm, Nemenyi), Bayesian Plackett–Luce, LaTeX tables.          | Modern Python ecosystem, strictly typed models, Dolan–Moré profiles, effect sizes + CIs, multi-format exports, and FAIR replication artifacts.                                                                                                           |
| **`autorank`**        | Python     | *JOSS* (2020)            | Automated classifier comparison workflow (Shapiro → ANOVA/Tukey or Friedman/Nemenyi + CD plot + text/LaTeX summary).      | Broader scope than `autorank` (multi-run per-instance analysis, Dolan–Moré profiles, Bayesian ROPE, power/sensitivity, multi-format tables, extensible architecture), though at `v0.3.1` `autorank` had more coherent selection logic than `decision.py`. |
| **`baycomp`**         | Python / R | *JMLR* (2017)            | Bayesian tests (sign, signed-rank, correlated $t$, hierarchical) + ROPE simplex.                                          | Integrates Bayesian inference within a full frequentist + profile + reporting pipeline, **credible only when Benavoli et al. (2017) and Corani et al. (2017) are implemented faithfully and cross-checked against `baycomp`**.                           |
| **`scikit-posthocs`** | Python     | *JOSS* (2019)            | Wide catalog of post-hoc tests (Nemenyi, Conover, Dunn, Tamhane, Games–Howell, etc.) and significance plots.              | Offers a structured experimental workflow for stochastic benchmarks (*algorithm × instance × metric × run*), publication-ready tables, and integrated reproducibility.                                                                                     |
| **`pingouin`**        | Python     | *JOSS* (2018)            | General-purpose statistical tests in Python ($t$-test, ANOVA, RM-ANOVA, non-parametric, power, effect sizes).             | Specialized for stochastic algorithm evaluation designs (multi-instance, multi-metric, Dolan–Moré profiles, CD diagrams, benchmarking LaTeX tables).                                                                                                     |
| **`nparcomp`**        | R          | **JSS (2015)**           | Non-parametric multiple comparisons with exact/asymptotic simultaneous confidence intervals.                              | Different scope (one-way designs in R), but a direct benchmark for JSS mathematical standards on relative effects ($A_{12}$ / $p_{ij}$).                                                                                                                 |
| **`IOHanalyzer`**     | R / Web    | *GECCO* (2022)           | *Anytime* analysis (fixed-budget, fixed-target, ECDF, ERT) for iterative optimization heuristics.                         | Covers comparative inferential analysis, publication tables, and Bayesian/Dolan–Moré evaluation; optional anytime analysis would further broaden impact.                                                                                                 |

> [!TIP]
> **What role should `saes-ui`, `saes-ai`, and `saes-plugins` play in a JSS submission?**
>
> - In JSS, **the primary reviewed artifact must be the pure Python statistical library (`saes`)**.
> - JSS editors and reviewers do not consider a web/Tauri GUI or external LLM chat assistant to be core statistical innovation—and calls to external LLM providers (OpenAI/Anthropic/Gemini) **conflict with offline deterministic reproducibility**.
> - Optimal strategy: dedicate **90–95% of the manuscript to the Python core** (conceptual framework, statistical rigor, extensibility, numerical cross-validation, empirical case studies, reproducible export), mentioning the REST API and desktop workbench only briefly in an architecture/interoperability subsection (or in a separate software engineering article, e.g., in *SoftwareX*).
> - **Regarding SAES v1 (Zenodo 2025, `jMetal/SAES`):** Because it is a software deposit on Zenodo/GitHub rather than a peer-reviewed journal paper, it does not preclude JSS publication, but consolidating under a **single clean package name** (`saes` 2.0 on PyPI, avoiding `saesV2`) and transparently describing the evolution from v1 is strongly recommended.

---

## 5. Concrete Roadmap to Make SAES Viable for JSS

To target **JSS** seriously, execute these **4 phases** prior to drafting and submitting the manuscript:

### Phase 1 — Statistical Hardening (Blocking, Mandatory Before Submission)

1. **Unify and fix `TestDecisionEngine`** ([decision.py](file:///Users/emiliorodrigocarreiravillalta/Desktop/SAES/saesV2/src/saesV2/stats/decision.py)): remove implicit `run_id` pairing inference (require explicit `paired: bool = False`, reserving automatic pairing exclusively for instance blocks across algorithms), fix non-parametric routing, and document *pre-testing* caveats.
2. **Faithfully re-implement Benavoli et al. (2017)** in [ranking.py](file:///Users/emiliorodrigocarreiravillalta/Desktop/SAES/saesV2/src/saesV2/stats/ranking.py): remove `eff_weight = 12/n_blocks` and the 3 artificial pseudo-points; implement exact $\mathrm{DP}(s, \delta_{z_0})$ for Bayesian Signed-Rank and Bayesian Sign, support absolute and relative ROPE, and add the Bayesian Correlated $t$-test / hierarchical model (Corani et al., 2017) and Bayesian Plackett–Luce (Calvo et al., 2018). Replace parametric heuristics in `_fast_bayesian_*` inside [tables.py](file:///Users/emiliorodrigocarreiravillalta/Desktop/SAES/saesV2/src/saesV2/stats/tables.py).
3. **Fix verified point defects:**
   - Replace `kstest(z, "norm")` with **Lilliefors** (`statsmodels.stats.diagnostic.lilliefors`) in [explorer.py](file:///Users/emiliorodrigocarreiravillalta/Desktop/SAES/saesV2/src/saesV2/stats/explorer.py).
   - Add **tie correction to Friedman** (verified against `scipy.stats.friedmanchisquare` and R's `friedman.test`) and redesign `all-metrics` aggregation so block independence is preserved.
   - Replace the "post-hoc power audit" in [power.py](file:///Users/emiliorodrigocarreiravillalta/Desktop/SAES/saesV2/src/saesV2/stats/power.py) with **a priori power**, **sensitivity analysis (MDES)**, and **TOST equivalence testing**, ensuring consistency between paired and independent $d$.
   - Fix multiplicity adjustment and median/$A_{12}$-consistent win direction in [profiles.py](file:///Users/emiliorodrigocarreiravillalta/Desktop/SAES/saesV2/src/saesV2/stats/profiles.py) and remove unblocked ANOVA/Kruskal–Wallis over cross-instance means in [tables.py](file:///Users/emiliorodrigocarreiravillalta/Desktop/SAES/saesV2/src/saesV2/stats/tables.py).

### Phase 2 — Methodological Depth & Software Innovation (What Convinces the JSS Editor)

1. **Complete the promised statistical catalog:** implement **Friedman Aligned-Ranks**, **Quade**, **Dunn**, **Conover–Iman**, **Tukey HSD**, **Games–Howell**, **Bergmann–Hommel**, **Shaffer**, **Finner**, and **RM-ANOVA (Greenhouse–Geisser)**.
2. **Confidence intervals on all effect sizes:** populate `ci_lower`/`ci_upper` on `EffectSize` (noncentral / Brunner–Munzel / bootstrap CIs for Cohen's $d$, Hedges' $g$, $\eta^2$, $\varepsilon^2$, $A_{12}$, and Cliff's $\delta$; plus simultaneous contrasts akin to `nparcomp`).
3. **Articulate a unifying conceptual framework + genuine extensibility protocol (`marginaleffects` / `texreg` style):**
   - Formally define an extensible 4-protocol architecture: `ExperimentDesign` (*tidy* / multi-run / multi-instance / explicit pairing) → `HypothesisProcedure` (dynamic registry for omnibus & post-hoc tests) → `EffectEstimator` → `ReportRenderer` (extensible LaTeX/HTML/Markdown/DOCX/PDF renderer registry, factoring presentation out of the `tables.py` monolith).
   - Expose standard methods on result objects (`summary()`, `to_dataframe()`, `plot()`, `to_latex()`) matching JSS expectations.

### Phase 3 — Package Engineering, Cross-Validation & Documentation

1. **Name & metadata consolidation:** publish a clean PEP 8 release (`saes` v2.0 without `V2`, complete `pyproject.toml` metadata, zero dead dependencies, zero `pytest` warnings, fix duplicate notebook cell in `reproducibility.py`, clear error message when `[viz]` is missing).
2. **Numerical cross-validation suite (`marginaleffects` standard):** build automated tests verifying SAES outputs to $10^{-6}$ precision (or fixed-seed Monte Carlo tolerances) against golden references from **R** (`stats::friedman.test`, `scmamp`, `PMCMRplus`, `nparcomp`, `effsize`) and **Python** (`baycomp`, `scipy`, `statsmodels`, `autorank`).
3. **Professional documentation:** publish a **Sphinx / MkDocs** site (full API reference with mathematical formulas, literature references in docstrings, and 4–5 reproducible tutorials).

### Phase 4 — Recommended JSS Manuscript Structure (`jss.cls`, ~25–30 Pages)

Following the winning structure observed in `v111i09`, `v114i01`, and `v117i03`:

1. **Introduction & Motivation** (~3 pp.): challenges of statistical evaluation for stochastic algorithms (multi-run, multi-instance, non-normality, multiplicity, reproducibility) + **comprehensive Table 1 comparison** against `scmamp`, `autorank`, `baycomp`, `scikit-posthocs`, `pingouin`, `PMCMRplus`, and `IOHanalyzer`.
2. **Conceptual Framework & Statistical Methodology** (~6 pp.): exact mathematical formulation of all implemented procedures (assumptions, blocked/unblocked omnibus tests, post-hoc and FWER/FDR control, effect sizes with CIs, Bayesian ROPE inference, Dolan–Moré profiles, a priori power and MDES sensitivity).
3. **Software Design, Architecture, and Extensibility** (~5 pp.): *tidy* schema, immutable result models, extensible registries, practical demonstration of registering a custom test or renderer in <15 lines (as in `texreg` Sec. 6 and `marginaleffects` Sec. 6), and an optional brief mention of the REST layer / FAIR reproducibility.
4. **Empirical Case Studies** (~8–10 pp.): **two non-trivial real-world case studies** from distinct domains—e.g., (a) multi-objective optimization (NSGA-II, MOEA/D, SPEA2, etc. on ZDT/DTLZ using `swarmintelligence.csv`) and (b) supervised machine learning (classifiers across multiple datasets with paired cross-validation)—showcasing clean Python code, high pen-to-paper-ratio vector figures, and package-generated LaTeX tables.
5. **Numerical Validation, Computational Benchmarks, and Limitations** (~3 pp.): numerical agreement table against R/`baycomp`, runtime scaling in $(k, N, n_{\text{runs}})$, an **explicit *Limitations* section**, and *Computational details* (OS, CPU, Python, exact dependency versions).
6. **Single replication script (`replication.py`)** + `requirements.txt` reproducing every number, table, and figure in $< 10$ minutes on a standard laptop.

---

## 6. Strategic Venue Comparison: JSS vs. Alternative Journals

| Journal                                                                |               Baseline Fit (`v0.3.1`)               | Post Phases 1–3 Fit (`v1.0`) | Strategic Pros & Cons                                                                                                                                                                                   |
| :--------------------------------------------------------------------- | :-------------------------------------------------: | :--------------------------: | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| ***Journal of Statistical Software* (JSS)**                            |        ❌ Low (high risk of *desk reject*)          | ✅ **Medium-High / High**    | Highest prestige and impact in computational statistics; diamond open access (0 EUR APC). Requires 12–24 months, spotless mathematical rigor, and forbids resubmission after rejection.                 |
| ***Journal of Open Source Software* (JOSS)**                           |   ⚠️ Medium (after Phase 1 fixes + docs)            |      ✅ **Very High**        | Fast, open review on GitHub (1–3 months), home to `autorank`, `pingouin`, and `scikit-posthocs`. Short paper (1–2 pp.), lower weight in traditional academic evaluation systems.                        |
| ***SoftwareX* (Elsevier)**                                             | ⚠️ Medium-High (after Phase 1 fixes + docs)         |      ✅ **Very High**        | JCR Q2, faster review (3–6 months), well suited to full ecosystems (library + REST API + Tauri GUI + reproducibility). Requires an open-access APC.                                                     |
| ***Applied Soft Computing* / *Swarm and Evolutionary Computation***    | ⚠️ Medium (as a tool + empirical study paper)       |         ✅ **High**          | Natural audience for metaheuristics and stochastic optimization (home to seminal papers such as Derrac et al. 2011 and Carrasco et al. 2020).                                                          |
| ***ACM Transactions on Mathematical Software* (TOMS)**                 |                    ❌ Very Low                      |       ⚠️ Low-Medium          | Demands deep algorithmic/numerical innovation; weaker fit than JSS for a statistical evaluation suite.                                                                                                  |

### Final Conclusion

`saesV2` already exhibits a **clean, modern software engineering architecture** (GPL-3.0, strict typing, Pydantic V2, automated test suite, cohesive end-to-end design) surpassing many academic packages in code organization. However, the **JSS** bar is not cleared by web infrastructure or breadth of surface features alone, but by **impeccable mathematical accuracy, methodological completeness, cross-validation against the state of the art, and an extensible, thoroughly documented Python design**. By completing statistical hardening (Phase 1) and methodological depth/cross-validation (Phases 2–3), **SAES gains a strong, realistic case for JSS**.
