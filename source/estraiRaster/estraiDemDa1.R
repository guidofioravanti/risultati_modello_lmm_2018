#04 agosto 2020: il file estraiRaster.R estrae dem e d_a1 ma per un errore i valori NON scalati non sono stati aggiunti nel file di output dei dati. Questo programma recupera queste due variabili.
library("git2rdata")
library("tidyverse")
library("janitor")
library("sf")
library("sp")
library("assertthat")
library("knitr")
library("gt")
library("RPostgreSQL")
library("rpostgis")

dbDriver("PostgreSQL")->mydrv
dbConnect(mydrv,dbname="asiispra",host="localhost",port=5432,user="guido")->mycon
rpostgis::pgGetRast(mycon,c("rgriglia","dem"))->dem
rpostgis::pgGetRast(mycon,c("rgriglia","dis_a1"))->d_a1
dbDisconnect(mycon)


read_vc(root="./risultati_modello_lmm_2018/data/",fil="pm10_dati_con_predittori_2018.tsv")->dati

dati[!duplicated(dati$id_centralina),]->sfStazioni
st_as_sf(sfStazioni,coords = c("X","Y"),crs=32632)->sfStazioni

as_Spatial(sfStazioni)->spStazioni
raster::extract(dem,spStazioni)->demExtract
raster::extract(d_a1,spStazioni)->da1Extract

sfStazioni$q_dem<-demExtract
sfStazioni$d_a1<-da1Extract

full_join(dati,sfStazioni %>% dplyr::select(id_centralina,q_dem,d_a1))->gdati
gdati$geometry<-NULL
write_vc(gdati,root="./risultati_modello_lmm_2018/data/",file="pm10_dati_con_predittori_2018_04agosto2020.tsv",optimize=TRUE,sorting = c("id_centralina","banda"))->dati
