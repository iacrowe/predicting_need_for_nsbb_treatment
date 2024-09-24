library(tidyverse)
library(mice)
library(finalfit)
library(glue)

## read in data and prepare for analysis
data_analysis <-
  read_csv("synthetic_data.csv") %>%
  mutate(
    id = row_number(),
    aet_group = as_factor(aet_group),
    aet_group = 
      fct_relevel(
        aet_group,
        c("alcohol", "nafld", "viral", "immune/metabolic")
      )
  )

## imputation for missing data
explanatory <- c("te_actual", "age", "aet_group", "sex", "albi_score", "fib4",
                 "albumin", "bilirubin", "platelets", "inr")

dependent <- "decomp_cat"

pred_mat <- 
  data_analysis %>%
  select(all_of(c(explanatory, dependent))) %>%
  missing_predictorMatrix()

imputed <-
  data_analysis %>%
  select(all_of(c(explanatory, dependent))) %>%
  mice(m = 10, predictorMatrix = pred_mat)

## tibble of all imputed data
all_imputed <-
  tibble(
    complete(imputed, action = "repeated")
  ) %>%
  select(starts_with("albi"), starts_with("fib4"), starts_with("aet"), starts_with("bilirubin"), 
         starts_with("albumin"), starts_with("platelets"), starts_with("inr")) %>%
  mutate(id = row_number())

## functions include calculation of existing predictive scores
### anticipate
calculate_anticipate <- function(te_actual, platelets_impute) {
  platelets <- ifelse(platelets_impute > 150, 150, platelets_impute)
  logit <- -6.3320165 + 3.1001014 * log(te_actual) - 0.020481545 * platelets
  prob_csph <- 1 / (1 + exp(-logit))
  return(prob_csph)
}

### 3p
calculate_3p <- function(platelets_impute, bilirubin_impute, inr_impute) {
  1 / (1 + exp(-(-1.368246 + (-0.009306 * platelets_impute) +
                   (0.378559 * (bilirubin_impute / 17.1)) +
                   (2.556866 * inr_impute))))
}

### 3p + lsm
calculate_3p_lsm <- function(platelets_impute, bilirubin_impute, inr_impute, te_actual) {
  1 / (1 + exp(-(-1.552564 + (-0.012479 * platelets_impute) +
                   (0.484583 * (bilirubin_impute / 17.1)) +
                   (1.347533 * inr_impute) +
                   (0.081547 * te_actual))))
}

## model thresholds
### anticipate
anticipate_threshold <- 0.6

### 3p
score_3p_threshold <- 0.663

### 3p_lsm
score_3p_lsm_threshold <- 0.647

## make 10 imputed datasets
### filters applied to exclude patients with FIB4 <1.3

make_imputed_dataset <- function(mi_select) {
  all_imputed %>%
    select(id, ends_with(mi_select)) %>%
    rename(
      albi_impute = glue("albi_score.", mi_select),
      fib4_impute = glue("fib4.", mi_select),
      aet_impute = glue("aet_group.", mi_select),
      albumin_impute = glue("albumin.", mi_select),
      bilirubin_impute = glue("bilirubin.", mi_select),
      platelets_impute = glue("platelets.", mi_select),
      inr_impute = glue("inr.", mi_select)
    ) %>%
    left_join(data_analysis, by = "id") %>%
    filter(fib4_impute > 1.3 & te_actual > 10) %>%
    mutate(
      aasld = case_when(
        te_actual > 25 ~ "yes",
        te_actual > 15 & te_actual < 25 & platelets_impute < 110 ~ "yes",
        te_actual > 20 & te_actual < 25 & platelets_impute < 150 ~ "yes",
        TRUE ~ "no"
      ),
      te_25 = if_else(te_actual > 25, "yes", "no"),
      anticipate_prob_csph = calculate_anticipate(te_actual, platelets_impute),
      score_3P = calculate_3p(platelets_impute, bilirubin_impute, inr_impute),
      score_3P_lsm = calculate_3p_lsm(platelets_impute, bilirubin_impute, inr_impute, te_actual),
      anticipate_prob_csph_cat = if_else(anticipate_prob_csph > anticipate_threshold, "yes", "no"),
      score_3P_cat = if_else(score_3P > score_3p_threshold, "yes", "no"),
      score_3P_lsm_cat = if_else(score_3P_lsm > score_3p_lsm_threshold, "yes", "no"),
      decomp_days_after_varices = if_else(varices_cat == 1, decomp_days - varices_days, decomp_days),
      varices_baseline = if_else(decomp_days_after_varices < 0, 0, varices_cat) #Beware, varices_cat is 0 or 1 while all other predictor are no or yes, might have to change that
    )
}

## make 10 imputed datasets
imputed_datasets <- map(1:10, ~ make_imputed_dataset(as.character(.x)))


## create a table using gtsummary
summary_table <- 
  imputed_datasets[[1]] %>%
  select(
    aet_impute, bilirubin_impute, albumin_impute, inr_impute,
    te_actual, anticipate_prob_csph, score_3P, score_3P_lsm,  
    varices_cat, decomp_cat) %>%
  rename(
    aetiology = aet_impute,
    bilirubin = bilirubin_impute,
    albumin = albumin_impute,
    inr = inr_impute,
    lsm = te_actual,
    anticipate = anticipate_prob_csph,
    varices = varices_cat,
    decompensation = decomp_cat
  ) %>%
  gtsummary::tbl_summary()
  

summary_table

