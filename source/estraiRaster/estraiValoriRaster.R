#16 luglio 2020
#Estrae i valori dei raster e li assegna ai punti stazione
library("git2rdata")
library("tidyverse")
library("raster")
library("sf")
library("seplyr")
library("furrr")

plan(multicore,workers=6)

read_vc(root="./risultati_modello_lmm_2018/data",file="pm10_dati_2018")->dati
dati[!duplicated(dati$id_centralina),]->stazioni

st_as_sf(stazioni,coords = c("X","Y"),crs=32632)->sfStazioni
as_Spatial(sfStazioni)->spStazioni

list.files(pattern="^.+\\.nc$")->ffile

furrr::future_imap(ffile,.f=function(.x=nomeFile,.y){

    .x->nomeFile

    brick(nomeFile)->mybrick
    nlayers(mybrick)->numeroGiorni
    crs(mybrick)<-CRS("+init=epsg:32632")
    
    purrr::map2(.x=1:numeroGiorni,.y=names(mybrick),.f=function(.x,.y){
      subset(mybrick,.x)->myraster

      raster::extract(myraster,spStazioni)->valori
   
      data.frame(valori=valori) %>%
        seplyr::rename_se(c(.y:="valori"))
    
    }) %>% purrr::reduce(.f=bind_cols)->mydf

    mydf$id_centralina<-spStazioni@data$id_centralina
    
    mydf %>%
      gather(key="yymmdd_temp",value="val",-id_centralina)%>%
      mutate(yymmdd=str_remove(yymmdd_temp,"\\..+$")) %>%
      mutate(yymmdd=str_remove(yymmdd,"^X"))%>%
      mutate(yymmdd=as.Date(yymmdd,format="%Y%m%d")) %>%
      mutate(val.s=scale(val,center = TRUE,scale = TRUE)) %>%
      seplyr::rename_se(c(stringr::str_remove(nomeFile,"\\.nc$"):="val")) %>%
      seplyr::rename_se(c(paste0(stringr::str_remove(nomeFile,"\\.nc$"),".s"):="val.s")) %>%      
      dplyr::select(-yymmdd_temp)

}) %>% purrr::reduce(.,.f=full_join)->dfPredittori

full_join(dati,dfPredittori)->daScrivere

#############################
### Estraggo i dati spaziali
#############################

raster("d_a1.s.tif")->myraster
extract(myraster,spStazioni)->spStazioni@data$d_a1.s
rm(myraster)

raster("q_dem.s.tif")->myraster
extract(myraster,spStazioni)->spStazioni@data$q_dem.s
rm(myraster)

raster("i_surface.s.tif")->myraster
extract(myraster,spStazioni)->spStazioni@data$i_surface.s
rm(myraster)

as.data.frame(spStazioni)->spStazioni
spStazioni$yymmdd<-NULL
spStazioni$banda<-NULL
spStazioni$pm10<-NULL
spStazioni$coords.x1<-NULL  
spStazioni$coords.x2<-NULL
spStazioni$station_code<-NULL

full_join(daScrivere,spStazioni)->daScrivere

daScrivere %>%
  mutate(lpm10=log(pm10+1))->daScrivere

write_delim(daScrivere,path = "pm10_2018_con_predittori_27luglio2020.csv",delim=";",col_names=TRUE)
