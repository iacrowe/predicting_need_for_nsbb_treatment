table_2_output <- function(x) {
  
  varices <-
    x %>% 
    group_by(varices_cat) %>% 
    count(decomp_cat) %>%
    mutate(
      varices_cat = if_else(varices_cat == 0, "no", "yes"),
      decomp_cat = if_else(decomp_cat == 0, "none", "decomp"),
      label = "varices") %>%
    pivot_wider(
      names_from = decomp_cat, values_from = n
    ) %>%
    rename(present = varices_cat)
  
  lsm_25 <-
    x %>% 
    group_by(te_25) %>% 
    count(decomp_cat) %>%
    mutate(
      decomp_cat = if_else(decomp_cat == 0, "none", "decomp"),
      label = "LSM >25kPa") %>%
    pivot_wider(
      names_from = decomp_cat, values_from = n
    ) %>%
    rename(present = te_25)
  
  aasld <-
    x %>% 
    group_by(aasld) %>% 
    count(decomp_cat) %>%
    mutate(
      decomp_cat = if_else(decomp_cat == 0, "none", "decomp"),
      label = "AASLD rule-in") %>%
    pivot_wider(
      names_from = decomp_cat, values_from = n
    ) %>%
    rename(present = aasld)
  
  score_3P <- x %>% 
    group_by(score_3P_cat) %>% 
    count(decomp_cat) %>%
    mutate(
      score_3P_cat = if_else(score_3P_cat == "no", "no", "yes"),
      decomp_cat = if_else(decomp_cat == 0, "none", "decomp"),
      label = "Score 3P"
    ) %>%
    pivot_wider(
      names_from = decomp_cat, values_from = n
    ) %>%
    rename(present = score_3P_cat)
  
  score_3P_lsm <- x %>% 
    group_by(score_3P_lsm_cat) %>% 
    count(decomp_cat) %>%
    mutate(
      score_3P_lsm_cat = if_else(score_3P_lsm_cat == "no", "no", "yes"),
      decomp_cat = if_else(decomp_cat == 0, "none", "decomp"),
      label = "Score 3P + LSM"
    ) %>%
    pivot_wider(
      names_from = decomp_cat, values_from = n
    ) %>%
    rename(present = score_3P_lsm_cat)
  
  anticipate <- x %>% 
    group_by(anticipate_prob_csph_cat) %>% 
    count(decomp_cat) %>%
    mutate(
      anticipate_prob_csph_cat = if_else(anticipate_prob_csph_cat == "no", "no", "yes"),
      decomp_cat = if_else(decomp_cat == 0, "none", "decomp"),
      label = "ANTICIPATE"
    ) %>%
    pivot_wider(
      names_from = decomp_cat, values_from = n
    ) %>%
    rename(present = anticipate_prob_csph_cat)
  
  ## Combine all summary tables into a single table
  bind_rows(varices, lsm_25, aasld, score_3P, score_3P_lsm, anticipate)
}

## illustrated data for the 1 dataset
### 2-by-2 table equivalent for all predictors
table_2_output(imputed_datasets[[1]])


## function to calculate sensitivity and specificity 
calculate_sensitivity_specificity <- function(data, predictor, outcome) {
  if (predictor == "varices_cat") {
    data <- data %>% mutate(varices_cat = if_else(varices_cat == 1, "yes", "no"))
  }
  
  # Ensure the outcome is consistently coded as "yes" and "no"
  data <- data %>% mutate(decomp_cat = if_else(decomp_cat == 1, "yes", "no"))
  
  # Create a confusion matrix
  confusion_matrix <- table(data[[predictor]], data[[outcome]])
  
  # Check if the confusion matrix has the required dimensions
  if (!all(c("yes", "no") %in% rownames(confusion_matrix)) || !all(c("yes", "no") %in% colnames(confusion_matrix))) {
    return(tibble(sensitivity = NA, specificity = NA))
  }
  
  
  # Calculate sensitivity and specificity
  TP <- confusion_matrix["yes", "yes"]
  FN <- confusion_matrix["no", "yes"]
  TN <- confusion_matrix["no", "no"]
  FP <- confusion_matrix["yes", "no"]
  
  sensitivity <- TP / (TP + FN)
  specificity <- TN / (TN + FP)
  
  return(tibble(sensitivity = sensitivity, specificity = specificity))
}

## calculate sensitivity and specificity for all predictors for one imputed dataset
varices_ss <- calculate_sensitivity_specificity(imputed_datasets[[1]], "varices_cat", "decomp_cat") %>% mutate(predictor = "varices")
lsm_25_ss <- calculate_sensitivity_specificity(imputed_datasets[[1]], "te_25", "decomp_cat") %>% mutate(predictor = "LSM >25kPa")
aasld_ss <- calculate_sensitivity_specificity(imputed_datasets[[1]], "aasld", "decomp_cat") %>% mutate(predictor = "AASLD rule-in")
score_3P_ss <- calculate_sensitivity_specificity(imputed_datasets[[1]], "score_3P_cat", "decomp_cat") %>% mutate(predictor = "Score 3P")
score_3P_lsm_ss <- calculate_sensitivity_specificity(imputed_datasets[[1]], "score_3P_lsm_cat", "decomp_cat") %>% mutate(predictor = "Score 3P + LSM")
anticipate_ss <- calculate_sensitivity_specificity(imputed_datasets[[1]], "anticipate_prob_csph_cat", "decomp_cat") %>% mutate(predictor = "ANTICIPATE")

sensitivity_specificity_results <- 
  bind_rows(varices_ss, lsm_25_ss, aasld_ss, score_3P_ss, score_3P_lsm_ss, anticipate_ss) %>%
  select(predictor, sensitivity, specificity)

sensitivity_specificity_results
