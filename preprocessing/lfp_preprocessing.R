
# ht002, ht003: Ever diagnosed for HTN, DM
# ht002c, ht003c: Currently on medication for HTN, DM

require(lubridate)
lfp_preprocessing <- function(df){
  df %>% 
    # Blood pressure cleaning -------
    mutate(
           diagnosed_dm = case_when(diagnosed_dm == 1 ~ 1,
                                    TRUE ~ 0),
           medication_dm = case_when(medication_dm == 1 ~ 1,
                                     TRUE ~ 0),
           
           
           
           diagnosed_bp = case_when(diagnosed_bp == 1 ~ 1,
                                    TRUE ~ 0),
           medication_bp = case_when(medication_bp == 1 ~ 1,
                                     TRUE ~ 0))  %>% 
    
    mutate(bmi_underweight = case_when(bmi > bmi_max ~ NA_real_,
                                       bmi < bmi_cutoff[1] ~ 1,
                                       bmi >= bmi_cutoff[1] ~ 0,
                                       TRUE ~ NA_real_),
           
           
           bmi_overweight = case_when(bmi > bmi_max ~ NA_real_,
                                      bmi >= bmi_cutoff[2] & bmi < bmi_cutoff[3] ~ 1,
                                      bmi < bmi_cutoff[2] | bmi >= bmi_cutoff[3] ~ 0,
                                      TRUE ~ NA_real_),
           
           
           bmi_obese = case_when(bmi > bmi_max ~ NA_real_,
                                 bmi >= bmi_cutoff[3] ~ 1,
                                 bmi < bmi_cutoff[3] ~ 0,
                                 TRUE ~ NA_real_)) %>% 

    mutate(sbp_avg = rowMeans(.[,c("sbp1","sbp2","sbp3")],na.rm=TRUE),
           
           dbp_avg = rowMeans(.[,c("dbp1","dbp2","dbp3")],na.rm=TRUE),
           htn = case_when(diagnosed_bp == 1 ~ 1,
                           is.na(sbp) | is.na(dbp) ~ NA_real_,
                           sbp >= sbp_cutoff ~ 1,
                           dbp >= dbp_cutoff ~ 1,
                           sbp < sbp_cutoff ~ 0,
                           dbp < dbp_cutoff ~ 0,
                           TRUE ~ NA_real_),
           highbp = case_when(
             is.na(sbp) | is.na(dbp) ~ NA_real_,
             sbp >= sbp_cutoff ~ 1,
             dbp >= dbp_cutoff ~ 1,
             sbp < sbp_cutoff ~ 0,
             dbp < dbp_cutoff ~ 0,
             TRUE ~ NA_real_),
           # Among those diagnosed, indicator of hypertension control status
           diaghtn = case_when(
             diagnosed_bp == 0 ~ NA_real_,
             is.na(sbp) | is.na(dbp) ~ NA_real_,
             diagnosed_bp == 1 & age <= agebp_cutoff & sbp > sbp_target[1] ~ 1,
             diagnosed_bp == 1 & age <= agebp_cutoff & dbp > dbp_target[1] ~ 1,
             diagnosed_bp == 1 & age <= agebp_cutoff & sbp <= sbp_target[1] ~ 0,
             diagnosed_bp == 1 & age <= agebp_cutoff & dbp <= dbp_target[1] ~ 0,
             
             diagnosed_bp == 1 & age > agebp_cutoff & sbp > sbp_target[2] ~ 1,
             diagnosed_bp == 1 & age > agebp_cutoff & dbp > dbp_target[2] ~ 1,
             diagnosed_bp == 1 & age > agebp_cutoff & sbp <= sbp_target[2] ~ 0,
             diagnosed_bp == 1 & age > agebp_cutoff & dbp <= dbp_target[2] ~ 0,
             
             TRUE ~ NA_real_)
    ) %>% 
    
  # Hypertension cascade -----
  mutate(htn_sample = case_when(!is.na(sbp)|!is.na(dbp) ~ 1,
                                is.na(sbp) & is.na(dbp) ~ 0,
                                TRUE ~ 1),
         # Diagnosis: No/DK, Blood pressure: in range
         htn_free = case_when(
           is.na(htn) ~ NA_real_,
           htn == 1 ~ 0,
           htn == 0 ~ 1,
           TRUE ~ NA_real_),
         htn_undiag_htn = case_when(diagnosed_bp == 1 | is.na(diagnosed_bp) ~ NA_real_,
                                        htn == 1 ~ 1,
                                        htn == 0 ~ 0,
                                        TRUE ~ NA_real_),
         
         # Diagnosis: Yes + Treated: No, Blood pressure: <NA>
         htn_diag_untreat = case_when(diagnosed_bp == 1 & medication_bp == 1 ~ 0,
                                      diagnosed_bp == 1 & medication_bp == 0 ~ 1,
                                      TRUE ~ NA_real_),
         
         # Dignosis: Yes, Treated: Yes, Blood pressure: out of control range
         htn_treat_uncontr = case_when(medication_bp == 0 | is.na(medication_bp)  ~ NA_real_,
                                       medication_bp == 1 & diaghtn == 1 ~ 1,
                                       medication_bp == 1 & diaghtn == 0 ~ 0,
                                       TRUE ~ NA_real_),
         # Dignosis: Yes, Treated: Yes, Blood pressure: in range
         htn_treat_contr = 1 - htn_treat_uncontr,
         
         # Dignosis: Yes, Treated: Yes or No, Blood pressure: out of control range
         htn_diag_uncontr = case_when(diagnosed_bp == 0 | is.na(diagnosed_bp)  ~ NA_real_,
                                      diaghtn == 1 ~ 1,
                                      diaghtn == 0 ~ 0,
                                      TRUE ~ NA_real_),
         # Dignosis: Yes, Treated: Yes, Blood pressure: in range
         htn_diag_contr = 1 - htn_diag_uncontr
         
  ) %>%
    
    # Prediabetes and Prehypertension ------
  mutate(
    prehypertension = case_when(diagnosed_bp == 1 ~ NA_real_,
                                is.na(sbp) | is.na(dbp) ~ NA_real_,
                                htn == 1 ~ 0,
                                sbp >= sbppre_cutoff & sbp < sbp_cutoff ~ 1,
                                dbp >= dbppre_cutoff & dbp < dbp_cutoff~ 1,
                                sbp < sbppre_cutoff ~ 0,
                                dbp < dbppre_cutoff ~ 0,
                                TRUE ~ NA_real_)) %>% 
   
    mutate(sex = case_when(sex == 1 ~ "Male",
                           sex == 2 ~ "Female"),
           
           education = case_when(is.na(edulevel) ~ 10,
                                 edulevel %in% c(1) ~ 10,
                                 edulevel %in% c(2,3) ~ 11,
                                 edulevel %in% c(4) ~ 12,
                                 edulevel %in% c(5:9) ~ 13,
                                 TRUE ~ NA_real_)
           
    ) %>% 
    mutate(employment = case_when(employment == 2 ~ 0,
                                  employment == 1 ~ 1,
                                  TRUE ~ NA_real_)) %>% 
    
    mutate_at(vars(insurance,diagnosed_bp,medication_bp,
                   diagnosed_dm,medication_dm), function(x) case_when(x== 2 ~ 0,
                                                                      x == 1 ~ 1,
                                                                      TRUE ~ NA_real_)) %>% 
    mutate(caste = case_when(caste == 5 ~ 4,
                             TRUE ~ as.numeric(caste)),
           religion = case_when(religion == 2 ~ 12,
                                religion == 3 ~ 13,
                                TRUE ~ 14)) %>% 
    # BMI
    mutate_at(vars(bmi),function(x) case_when(x > bmi_max ~ NA_real_,
                                              TRUE ~ as.numeric(x))) %>%
    # Circumferences
    mutate_at(vars(waistcircumference,hipcircumference),function(x) case_when(x > 240 ~ NA_real_,
                                                                              TRUE ~ as.numeric(x))) %>% 
    # Caste
    
    mutate(na_caste = case_when(is.na(caste) ~ 1,
                                TRUE ~ 0)) %>% 
    mutate_at(vars(caste),function(x) case_when(x == 1 ~ "Scheduled Caste",
                                                x == 2 ~ "Scheduled Tribe",
                                                x == 3 ~ "OBC",
                                                x == 4 ~ "General",
                                                TRUE ~ "General")) %>% 
    # Education
    mutate(na_education = case_when(is.na(education) ~ 1,
                                TRUE ~ 0)) %>% 
    mutate_at(vars(education),function(x) case_when(x == 10 ~ "No education",
                                                    x == 11 ~ "Primary",
                                                    x == 12 ~ "Secondary",
                                                    x == 13 ~ "Higher",
                                                    TRUE ~ "No education")) %>% 
    # Religion
    mutate_at(vars(religion),function(x) case_when(x == 12 ~ "Hindu",
                                                      x == 13 ~ "Muslim",
                                                      TRUE ~ "Other")) %>% 
    # insurance, alcohol
    mutate_at(vars(
      alcohol,insurance), function(x) case_when(x == 0 ~ 0,
                                                x == 1 ~ 1,
                                                TRUE ~ NA_real_)) %>% 
    # Smoking
    mutate_at(vars(smokeever,smokecurr),function(x) case_when(x == 2 ~ 0,
                                                              x == 1 ~ 1,
                                                              TRUE ~ NA_real_)) %>% 
    mutate(smokecount = case_when(smokecount >= 30 ~ 30,
                                  TRUE ~ smokecount)) %>% 
    
    mutate(
      eduyr = case_when(education == "No education" ~ 0,
                        TRUE ~ as.numeric(eduyr))
    ) %>% 
    mutate(htn_disease = case_when(is.na(htn_free) ~ NA_real_,
                                   htn_free == 1 ~ 0,
                                   htn_undiag_htn == 1 ~ 1,
                                   htn_diag_untreat == 1 ~ 1,
                                   htn_treat_uncontr == 1 ~ 1,
                                   htn_treat_contr == 1 ~ 1,
                                   TRUE ~ 0),
           
           htn_diagnosed = case_when(is.na(htn_free) ~ NA_real_,
                                     htn_free == 1 ~ 0,
                                     htn_undiag_htn == 1 ~ 0,
                                     htn_diag_untreat == 1 ~ 1,
                                     htn_treat_uncontr == 1 ~ 1,
                                     htn_treat_contr == 1 ~ 1,
                                     TRUE ~ 0
           ),
           htn_treated = case_when(is.na(htn_free) ~ NA_real_,
                                   htn_free == 1 ~ 0,
                                   htn_undiag_htn == 1 ~ 0,
                                   htn_diag_untreat == 1 ~ 0,
                                   htn_treat_uncontr == 1 ~ 1,
                                   htn_treat_contr == 1 ~ 1,
                                   TRUE ~ 0
           ),
           htn_controlled = case_when(is.na(htn_free) ~ NA_real_,
                                      htn_free == 1 ~ 0,
                                      htn_undiag_htn == 1 ~ 0,
                                      htn_diag_contr == 1 ~ 1,
                                      htn_diag_untreat == 1 ~ 0,
                                      htn_diag_uncontr == 1 ~ 0,
                                      TRUE ~ 0
           ),
           
           htn_diagnosed_in_dis = case_when(is.na(htn_free) ~ NA_real_,
                                            htn_free == 1 ~ NA_real_,
                                            htn_undiag_htn == 1 ~ 0,
                                            htn_diag_untreat == 1 ~ 1,
                                            htn_treat_uncontr == 1 ~ 1,
                                            htn_treat_contr == 1 ~ 1,
                                            TRUE ~ 0
           ),
           htn_treated_in_dis = case_when(is.na(htn_free) ~ NA_real_,
                                          htn_free == 1 ~ NA_real_,
                                          htn_undiag_htn == 1 ~ 0,
                                          htn_diag_untreat == 1 ~ 0,
                                          htn_treat_uncontr == 1 ~ 1,
                                          htn_treat_contr == 1 ~ 1,
                                          TRUE ~ 0
           ),
           htn_controlled_in_dis = case_when(is.na(htn_free) ~ NA_real_,
                                             htn_free == 1 ~ NA_real_,
                                             htn_undiag_htn == 1 ~ 0,
                                             htn_diag_contr == 1 ~ 1,
                                             htn_diag_untreat == 1 ~ 0,
                                             htn_diag_uncontr == 1 ~ 0,
                                             TRUE ~ 0
           )) %>% 
    
    mutate(bmi_category = case_when(bmi > bmi_max ~ NA_real_,
                                    bmi >= bmi_cutoff[3] ~ 4,
                                    bmi >= bmi_cutoff[2] ~ 3,
                                    bmi >= bmi_cutoff[1] ~ 2,
                                    bmi < bmi_cutoff[1] ~ 1,
                                    TRUE ~ NA_real_),
           
           highwc = case_when(sex == "Female" & waistcircumference >= female_wc_cutoff ~ 1,
                              sex == "Female" & waistcircumference < female_wc_cutoff ~ 0,
                              sex == "Male" & waistcircumference >= male_wc_cutoff ~ 1,
                              sex == "Male" & waistcircumference < male_wc_cutoff ~ 0,
                              TRUE ~ NA_real_
           ),
           waist_hip = case_when(!is.na(hipcircumference) ~ waistcircumference/hipcircumference,
                                 TRUE ~ NA_real_)
    ) %>% 
    
    mutate(bmi_category = factor(bmi_category,levels=c(1:4),labels=c("Underweight","Normal","Overweight","Obese")),
           highwhr = case_when(sex == "Female" & waist_hip >= female_whr_cutoff ~ 1,
                               sex == "Female" & waist_hip < female_whr_cutoff ~ 0,
                               sex == "Male" & waist_hip >= male_whr_cutoff ~ 1,
                               sex == "Male" & waist_hip < male_whr_cutoff ~ 0,
                               TRUE ~ NA_real_
           )) %>% 
    
    mutate_at(vars(diagnosed_dm,medication_dm,
                   diagnosed_bp,medication_bp),~case_when(is.na(.) ~ 0,
                                                          TRUE ~ .)) %>% 
    mutate(age_category = case_when(age %in% c(18:39) ~ 1,
                                   age %in% c(40:64) ~ 2,
                                   age >= 65 ~ 3,
                                   TRUE ~ NA_real_),
           age_category10 = cut(age,breaks=c(18,30,40,50,60,70,80,100),include.lowest=TRUE,right=FALSE),
           age_category5 = cut(age,breaks=seq(15,100,by=5),include.lowest=TRUE,right=FALSE)) %>% 
    return(.)
}

