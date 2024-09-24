# predicting_need_for_nsbb_treatment
Repo to support replication of analyses to predict the need for NSBB treatment in patients with compensated advanced chronic liver disease (cACLD).

This repo contains a synthetic dataset, created to allow reproduction of the analyses in the associated manuscript once published.  The relationships within this synthetic dataset are maintained but will not give exactly the same results as the original data.  This synthetic dataset should not be for inference but rather to explore the analytical strategy.  The original dataset is described in detail in [Shearer et al](https://www.cghjournal.org/article/S1542-3565(22)00290-7/pdf).

![synth_comp_plot](https://github.com/user-attachments/assets/03da39c9-3cf0-401c-b02e-ab7b59e150e5)

The following scripts are intended to be run sequentially.  
## 00_prepare data
REads in data and does multiple imputation of missing data