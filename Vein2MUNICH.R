library(sf)
library(mapview)
library(scales)

source('./wudapt2munich.R')

## In My desktop Machine
CO   <- readRDS('~/Downloads/CO.rds')
NO   <- readRDS('~/Downloads/NO.rds')
NO2  <- readRDS('~/Downloads/NO2.rds')
NMHC <- readRDS('~/Downloads/NMHC.rds')

# CO   <- readRDS('/media/quishqa/Marvin/CO.rds')
# NO   <- readRDS('/media/quishqa/Marvin/NO.rds')
# NO2  <- readRDS('/media/quishqa/Marvin/NO2.rds')
# NMHC <- readRDS('/media/quishqa/Marvin/NMHC.rds') 

# save.image('EmissMun.Rda')

munich.zones <- data.frame(name = c("Parque Dom Pedro", "Itaim Paulista",
                                    "Pinheiros", "Parque Ibirapuera", "Itaquera",
                                    "Parque Interlagos", "Cidade Universitria"),
                           abr = c("PDP", "PAU", "PIN", "IBI", "ITA", "INTER", 
                                   "USP"),
                           stringsAsFactors = F)



ZoneSelector <- function(POL, Zone.name){
  df <- POL[POL$NomeZona == Zone.name, ]
  df <- df[st_geometry_type(df$geometry) == 'LINESTRING', ]
  df <- df[as.numeric(df$LKM3) > 1.0, ]
  return(df)
}

ZONES <- list()

for (i in seq(1, nrow(munich.zones))){
  ZONES[[i]] <- ZoneSelector(CO, munich.zones$name[i])
}

lapply(ZONES, PlotMapStreet)


# est <- 'Itaim Paulista'
# 
# no <- ZoneSelector(NO, est)
# no2 <- ZoneSelector(NO2, pdp)
# co <- ZoneSelector(CO, pdp)
# nmhc <- ZoneSelector(NMHC, pdp)

GetCoords <- function(df){
  st.coords <- st_coordinates(df)
  st.coords1 <- as.data.frame(st.coords[seq(1, nrow(st.coords), 2), ])
  st.coords2 <- as.data.frame(st.coords[seq(2, nrow(st.coords), 2), ])
  st.coords <- data.frame(xa = st.coords1$X, xb = st.coords2$X,
                          ya = st.coords1$Y, yb = st.coords2$Y)
  return(st.coords)
}

# st.coords <- GetCoords(no)

CoordsAndBh <- function(df){
  df <- GetCoords(df)
  st.bh <- BuildingHeightWudapt(df)
  return(st.bh)
}


#create a dataframe with all the info and then cut ???

StreetGeogInfoWriter <- function(df, ff){
  st.info <- data.frame(id = df$id, length = 0, width = 3.05 * df$lanes,
                        height = CoordsAndBh(df))
  file.name <- paste0("street-geog-info_", ff,".dat")
  cat("#id,length,width,height\n", file = file.name)
  write.table(st.info, file = file.name, col.names = F, row.names = F, 
              quote = F, append = T, sep = '\t')
  return(st.info)
}


# st.info <- StreetGeogInfoWriter(no)
# streets.ids <- seq(min(st.info$id), max(st.info$id))
# street.rm <- streets.ids[!(streets.ids %in% st.info$id)]



# Building emission files
# tmplt <- read.table('./EL.traf.2014032501', header = T, dec = '.', sep = '')
# sim.time <- seq(as.POSIXct('2018-02-19 00:00', tz = 'America/Sao_Paulo'),
#                 by = 'hour', length.out = 168)
# attributes(sim.time)$tzone <- 'UTC'
# sim.time.f <- format(sim.time, format = '%Y%m%d%H')


EmissFile <- function(tt, ff){
  df   <- data.frame(matrix(0.0, ncol = ncol(tmplt), nrow = nrow(st.coords)))
  names(df) <- names(tmplt)
  df$i <- st.info$id 
  df$idbrin <- st.info$id
  df$typo   <- 20
  df$xa     <- st.coords$xa
  df$ya     <- st.coords$ya
  df$xb     <- st.coords$xb
  df$yb     <- st.coords$yb
  df$NMHC   <- nmhc[[tt]] * (10^6)  / (nmhc$LKM3/1000) / 3600 # to ug/s
  df$NOx    <- (no[[tt]] + no2[[tt]]) * (10^6)  / (no$LKM3/1000) /3600
  df$NO2    <- no2[[tt]] * (10^6) /   (no2$LKM3/1000) /3600
  df$CO     <- co[[tt]] * (10^6) / (co$LKM3/1000)
  file.name <- paste0(ff,'.traf.', sim.time.f[tt])
  write.table(df, file = file.name, col.names = T, row.names = F, sep = ' ', dec = '.',
              quote = F)
}



# for (i in seq(1, length(sim.time.f))){
#   EmissFile(i, "PDP")
# }


AllInputs <- function(i, j){
  
  print("Selecting polluntants")
  
  no  <<- ZoneSelector(NO, i)
  no2 <<- ZoneSelector(NO2, i)
  co  <<- ZoneSelector(CO, i)
  nmhc <<- ZoneSelector(NMHC, i)
  
  print('Writting Street Coords File ')

  st.coords <<- GetCoords(no)  # data.frame with coords
  print(nrow(st.coords))
  st.info   <<- StreetGeogInfoWriter(no, j )  # creating
  print(nrow(st.info))

  
  print("Writting filtered index files")
  streets.ids <- seq(min(st.info$id), max(st.info$id))
  street.rm <- streets.ids[!(streets.ids %in% st.info$id)]
  write.table(street.rm, file = paste0(j, 'index_out.dat'),
              quote = F, row.names = F, col.names = F)

  print("Beginning building emission files")
  tmplt <<- read.table('./EL.traf.2014032501', header = T, dec = '.', sep = '')
  sim.time <<- seq(as.POSIXct('2018-02-19 00:00', tz = 'America/Sao_Paulo'),
                  by = 'hour', length.out = 168)
  attributes(sim.time)$tzone <- 'UTC'
  sim.time.f <- format(sim.time, format = '%Y%m%d%H')

  for (n in seq(1, length(sim.time.f))){
    EmissFile(n, j)
  }
}



usp <- ZoneSelector(NO, Zone.name = munich.zones$name[7])
mapview(usp, z = 'h1')

# usp.bh <- CoordsAndBh(usp)
# h <-  hist(usp.bh)
# h$density <- h$counts / sum(h$counts) * 100
# h.per <- round(h$density, 1)
# h.per[h.per <= 0.01] <- ''
# h.labs <- paste(h$breaks[seq(1, length(h$breaks)-1, 1)],
#                 h$breaks[seq(2, length(h$breaks), 1)],
#                 sep = '-')
# plot(h, freq = F, main = '',
#      xlab = '',
#      ylab = '',
#      ylim = c(0, 100), axes = F, border = NA,
#      col = scales::alpha('firebrick', 0.7))
# mtext('Cidade Universitária', side = 3, adj =0, line = 1.2,
#       cex = 1.5, font = 2)
# mtext('Buiding height frequency (%)',side = 3, cex = 1, font =3, adj =0)
# text(x = h$mids, y = h$density + 2.75, labels = h.per)
# axis(1, h$mids, h.labs, tick = T, col =NA,
#      col.ticks = 1)

HistBuildingHeight <- function(df, title){
  df.bh <- CoordsAndBh(df)
  h <-  hist(df.bh)
  h$density <- h$counts / sum(h$counts) * 100
  h.per <- round(h$density, 1)
  h.per[h.per <= 0.01] <- ''
  h.labs <- paste(h$breaks[seq(1, length(h$breaks)-1, 1)],
                  h$breaks[seq(2, length(h$breaks), 1)],
                  sep = '-')
  plot(h, freq = F, main = '',
       xlab = '',
       ylab = '',
       ylim = c(0, 100), axes = F, border = NA,
       col = scales::alpha('firebrick', 0.7))
  mtext(title, side = 3, adj =0, line = 1.2,
        cex = 1.5, font = 2)
  mtext('Buiding height frequency (%)',side = 3, cex = 1, font =3, adj =0)
  text(x = h$mids, y = h$density + 2.75, labels = h.per)
  axis(1, h$mids, h.labs, tick = T, col =NA,
       col.ticks = 1)
}


