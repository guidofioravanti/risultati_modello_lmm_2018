# Risultati modello LMM, dati 2018


### Codice del modello 

Una volta organizzati i dati di input per il 2018, il modello e' stato fatto girare mese per mese. Il modello originale prevedeva
un modello unico su tutti i mesi. Come scritto nel paper su INLA, l'effetto delle covariate cambia nel corso dei mesi quindi ha piu'
senso specificare 6 modelli indipendenti con le stesse covariate. 

```
rm(list=objects())
library("git2rdata")
library("lme4")
library("tidyverse")
library("broom")
library("furrr")

#lme4: pacchetto R che contiene la funzione lmer (modello a effetti misti)
#furrr: funzione per far girare in parallelo il modello per i mesi da luglio a dicembre
#broom: per organizzare in un data.frame gli output di lmer
plan(multicore,workers=6)

#lettura dei dati di input dal repository git
read_vc(root="risultati_modello_lmm_2018/data/",file="pm10_dati_con_predittori2_2018_04agosto2020")->dati

#formula: 
#lpm10 (log del pm10): target variable
#(aod600.s+0|banda/cod_reg): random slope dell'aod rispetto al giorno (banda) e alla regione (cod_reg)
lpm10~aod600.s+t2m.s+tp.s+sp.s+wspeed.s+wdir.s+q_dem.s+d_a1.s+dust.s+i_surface.s+(aod600.s+0|banda/cod_reg)->myformula

furrr::future_map(7:12,.f=function(mm){

  #subset dei dati del mese mm
  dati[dati$mm==mm,]->subDati
  print(mm)
  #modello a effetti misti 
  lmer(formula=myformula,data=subDati,REML=TRUE)->modelOut
  #salvo l'output del modello per poter poi fare le mappe
  saveRDS(modelOut,glue::glue("result{mm}.RDS"))
  
  #organizzo in un data.frame l'output di lmer e aggiungio una colonna mm (mese) per distinguere i risultati 
  #di ciascun mese
  tidy(modelOut)->df
  df$mm<-mm
  
  df
  
}) %>%purrr::reduce(.f=bind_rows)->df

#reduce: unisco mediante bind_rows (per righe) i singoli data.frame di output di ciascun modello e 
#il data.frame finale lo unisco in un data.frame finale
write_delim(df,path="effettiCovariate.csv",delim=";",col_names=TRUE)
```

### Descrizione dei dati di input e dei residui del modello

Una descrizione dei dati di input e dei risultati relativi all'analisi del modello sono 
[qui](https://guidofioravanti.github.io/risultati_modello_lmm_2018/index.html) riportati.


### ATTENZIONE

I dati di input **non coprono** tutto il periodo luglio-dicembre 2018! Si veda la tabella qui sotto.

| Mese | Numero di giorni disponibili |
| --- | --- |
| Luglio | 26 |
| Agosto | 24 |
| Settembre | 27 |
| Ottobre | 30 |
| Novembre | 30 |
| Dicembre | 28 |
| --- | --- |


