require(srvyr)
source("C:/code/external/functions/survey/svysummary.R")

couples <- readRDS(paste0(path_lasi_family_folder,"/working/LASI Couples.RDS"))
continuous_vars <- paste0(rep(c("w_","h_"),each=10),
                          c("sbp","dbp","glucose","weight","height",
                            "bmi","waistcircumference","hipcircumference",
                            "age","eduyr"))

proportion_vars <- paste0(rep(c("w_","h_"),each=15),
                          c("screened_bp","diagnosed_bp","medication_bp",
                            "fasting","screened_dm","diagnosed_dm","medication_dm",
                            "pregnant","employment","smokeever","smokecurr","alcohol",
                            "insurance","dm","htn"))

grouped_vars <- c("w_education","h_education","in_caste","in_religion","in_wealth")

couples_svy <- couples %>% 
  as_survey_design(.data = .,
                   ids = psu,strata = state,
                   weight = sampleweight,
                   nest = TRUE,
                   variance = "YG",pps = "brewer")

couples_svysummary <- svysummary(couples_svy,
                                 continuous_vars,
                                 proportion_vars,
                                 grouped_vars) %>% 
  mutate_at(vars(estimate,lci,uci),~round(.,1)) %>% 
  mutate(est_ci = paste0(estimate," (",
                         lci,", ",uci,")"))

couples_count <- couples %>% 
  summarize_at(vars(one_of(c(continuous_vars,
                    proportion_vars,
                    grouped_vars))),
               list(n = ~sum(!is.na(.)))) %>% 
  pivot_longer(names_to="variable",values_to="n",cols=everything()) %>% 
  mutate(variable = str_replace(variable,"_n$",""))


left_join(couples_svysummary,
          couples_count,
          by="variable") %>% 
  write_csv(.,"analysis/summary table.csv")

