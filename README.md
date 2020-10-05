# Risultati modello LMM, dati 2018


## Codice del modello 

```
rm(list=objects())
library("git2rdata")
library("lme4")
library("tidyverse")
library("broom")
library("furrr")

plan(multicore,workers=6)

read_vc(root="risultati_modello_lmm_2018/data/",file="pm10_dati_con_predittori2_2018_04agosto2020")->dati

lpm10~aod600.s+t2m.s+tp.s+sp.s+wspeed.s+wdir.s+q_dem.s+d_a1.s+dust.s+i_surface.s+(aod600.s+0|banda/cod_reg)->myformula

furrr::future_map(7:12,.f=function(mm){

  dati[dati$mm==mm,]->subDati
  print(mm)
  lmer(formula=myformula,data=subDati,REML=TRUE)->modelOut
  saveRDS(modelOut,glue::glue("result{mm}.RDS"))
  
  tidy(modelOut)->df
  df$mm<-mm
  
  df
  
}) %>%purrr::reduce(.f=bind_rows)->df

write_delim(df,path="effettiCovariate.csv",delim=";",col_names=TRUE)
```


Una descrizione dei dati di input e dei risultati relativi all'analisi del modello sono 
[qui](https://guidofioravanti.github.io/risultati_modello_lmm_2018/descrizioneDatiInput.html) riportati.
