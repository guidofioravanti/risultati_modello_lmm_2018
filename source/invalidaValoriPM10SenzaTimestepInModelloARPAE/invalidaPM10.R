#16 luglio 2020

######################################################
#Vogliamo eliminare dai dati ossservati, i valori di PM10 il cui timestamp
#non compare nei file netCDF forniti da ARPAE (da luglio a dicembre con molti buchi temporali).
#Una soluzione potrebbe essere: tenere tutti i valori di PM10 e invalidarli laddove
#manca il dato nel netCDF. Tuttavia quando si fara' il modello di regressione (lme4)
#ci si trovera' coni predittori == NA per i timestamp non forniti da ARPAE. 
#Quindi prima o dopo ci si trovera' di fronte al problema di dover eliminare righe dal dataset in cui
#i predittori sono NA. Eliminiamo alla radice il problema: creiamo un file di dati
#senza righe con NA nei predittori
######################################################


rm(list=objects())
library("git2rdata")
library("tidyverse")
library("daff")

#questi timestamp sono stati ricavati una volta aggregati i netCDF orari a 
#livello giornaliero
read_delim("timeStepStortini.txt",delim=";",col_names = TRUE) %>%
  mutate(yymmdd=as.Date(yymmdd,format="%Y-%m-%d"))->yymmdd

read_vc(file ="pm10_dati_2018" ,root="./risultati_modello_lmm_2018/data/")->dati

#ris e dati ora dovrebbero differire solo per il numero delle righe
left_join(yymmdd,dati) %>%
  dplyr::select(id_centralina,station_code,yymmdd,banda,pm10,X,Y) %>%
  arrange(id_centralina,banda)->ris


(length(unique(dati$id_centralina))*nrow(yymmdd))->totale
stopifnot(totale==nrow(ris))

write_vc(ris,file="pm10_dati_2018",root="./risultati_modello_lmm_2018/data/")

daff::diff_data(dati,ris)->differenze
render_diff(differenze)