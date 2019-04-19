library(RCurl)
library(XML)
library(stringr)
library(zoo)

CetesbRetrieveCut <- function(user.name, pass.word,
                              pol.name, est.name,
                              start.date, end.date){
  
  curl = getCurlHandle()
  curlSetOpt(cookiejar = 'cookies.txt', followlocation = TRUE, autoreferer = TRUE, curl = curl)
  
  url  <- "https://qualar.cetesb.sp.gov.br/qualar/autenticador"
  
  # To actually log in in the site 'style = "POST" ' seems mandatory
  postForm(url, cetesb_login = user.name, cetesb_password = pass.word,
           style = "POST", curl = curl)
  
  
  url2 <-"https://qualar.cetesb.sp.gov.br/qualar/exportaDados.do?method=pesquisar"
  
  # Other parameters
  end.date2  <- as.character(as.Date(end.date, format = '%d/%m/%Y') + 1)
  all.dates <- data.frame(
    date = seq(
      as.POSIXct(strptime(start.date, format = '%d/%m/%Y'),
                 tz = 'America/Sao_Paulo'),
      as.POSIXct(strptime(end.date2, format = '%Y-%m-%d'),
                 tz = 'America/Sao_Paulo'),
      by = 'hour'
    )
  )
  cet.names <- c('emp1', 'red', 'mot', 'type', 'day', 'hour', 'cod', 'est',
                 'pol', 'unit', 'value', 'mov','test', 'dt.amos', 'dt.inst',
                 'dt.ret', 'con', 'tax', 'emp2')
  
  # Start the query
  ask  <- postForm(url2,
                   irede = 'A',
                   dataInicialStr = start.date,
                   dataFinalStr   =  end.date,
                   iTipoDado = 'P',
                   estacaoVO.nestcaMonto = est.name,
                   parametroVO.nparmt = pol.name,
                   style = 'POST',
                   curl = curl)
  pars <- htmlParse(ask, encoding = "UTF-8") # 'Encoding "UTF-8", preserves special characteres
  tabl <- getNodeSet(pars, "//table")
  dat  <- readHTMLTable(tabl[[2]], skip.rows = 1, stringsAsFactors = F)
  
  if (ncol(dat) != 19){
    dat <- data.frame(date = all.dates$date , pol = rep(NA, nrow(all.dates)))
  } else if (ncol(dat) == 19) {
    names(dat) <- cet.names
    dat$date <- paste(dat$day, dat$hour, sep = '_')
    dat$date <- as.POSIXct(strptime(dat$date, format = '%d/%m/%Y_%H:%M'))
    dat <- merge(all.dates, dat, all = T)
    if (pol.name == 16 | pol.name == 25 | pol.name == 24){
      dat$value <- as.numeric(gsub(",", ".", gsub("\\.", "", dat$value)))
      dat <- data.frame(date = all.dates$date , pol = dat$value)
    } else {
      dat$value <- as.double(dat$value)
      dat <- data.frame(date = all.dates$date , pol = dat$value)
    }
  }
  return(dat)
}

# Station code names
## Ibirapuera     : 83
## Cerqueira cesar: 91
# Background stations
## Araraquarea: 107
## Catanduva: 248
## Sao Jose dos Campos: 116

# Pollutant codes
## NO  : 17
## NO2 : 15
## O3  : 63

user.name <- 'XXXXXXXXX'
pass.word <- 'XXXXX'
start <- '01/02/2018'
end   <- '28/02/2018'


# Create background file

BackgroundConcentration <- function(user.name, pass.word, station.code,
                                    start, end, file){
  o3  <- CetesbRetrieveCut(user.name, pass.word, 63, station.code, start, end)
  no2 <- CetesbRetrieveCut(user.name, pass.word, 15, station.code, start, end)
  no  <- CetesbRetrieveCut(user.name, pass.word, 17, station.code, start, end)
  
  df <- data.frame(date = o3$date,
                   o3   = o3$pol,
                   no2  = no2$pol,
                   no   = no$pol)
  # using zoo na.approx to complete data
  df$o3 <- na.approx(df$o3, na.rm = F, rule = 2)
  df$no <- na.approx(df$no, na.rm = F, rule = 2)
  df$no2 <- na.approx(df$no2, na.rm = F, rule = 2)
  
  attributes(df$date)$tzone <- "UTM"
  df$date <- format(df$date, format = '%Y-%m-%d_%H')
  file.name <- paste0('bg_o3_no_no2_', file, '.dat')
  cat("#       O3      NO2     NO\n", file = file.name)
  write.table(df, file.name, sep = '\t', row.names = F,
              quote = F, col.names = F, append = T)
  return(df)
}


# This is background info!!!
#jund.bc <- BackgroundConcentration(user.name, pass.word, 109,
#                                   start, end, 'jund')

# ara.bc <- BackgroundConcentration(user.name, pass.word, 106, 
#                                   start, end, "ara")
# cat.bc <- BackgroundConcentration(user.name, pass.word, 248, 
#                                   start, end, "cat")
# sjr.bc <- BackgroundConcentration(user.name, pass.word, 116, 
#                                   start, end, "sjr")


# Observation data
## PDPII:72
## Pinheiros: 99
## Itaquera: 97
## ItaimPaulista: 266
## Congonhas: 73

ObservationConcentration <- function(user.name, pass.word, station.code,
                                     start, end, file){
  o3  <- CetesbRetrieveCut(user.name, pass.word, 63, station.code, start, end)
  no2 <- CetesbRetrieveCut(user.name, pass.word, 15, station.code, start, end)
  no  <- CetesbRetrieveCut(user.name, pass.word, 17, station.code, start, end)
  
  
  df <- data.frame(date = o3$date,
                   nox   = no2$pol + no$pol,
                   no    = no$pol,
                   no2   = no2$pol)

  attributes(df$date)$tzone <- "UTM"
  df$date <- format(df$date, format = '%Y%m%d%H')
  file.name <- paste0('obs_nox_no_no2_', file, '.dat')
  cat("#               NOx     NO      NO2\n", file = file.name)
  write.table(df, file.name, sep = '\t', row.names = F,
              col.names = F, quote = F, na = '99999.',
              append = T)
  return(df)
}

ObservationValidation <- function(user.name, pass.word, station.code,
                                     start, end, file){
  o3  <- CetesbRetrieveCut(user.name, pass.word, 63, station.code, start, end)
  no2 <- CetesbRetrieveCut(user.name, pass.word, 15, station.code, start, end)
  no  <- CetesbRetrieveCut(user.name, pass.word, 17, station.code, start, end)
  
  
  df <- data.frame(date = o3$date,
                   nox   = no2$pol + no$pol,
                   no    = no$pol,
                   no2   = no2$pol,
                   o3 = o3$pol)
  
  attributes(df$date)$tzone <- "UTM"
  df$date <- format(df$date, format = '%Y%m%d%H')
  file.name <- paste0('val_nox_no_no2_o3', file, '.dat')
  cat("#               NOx     NO      NO2  O3\n", file = file.name)
  write.table(df, file.name, sep = '\t', row.names = F,
              col.names = F, quote = F, na = '99999.',
              append = T)
  return(df)
}


pin.val <- ObservationValidation(user.name, pass.word, 99, 
                                   start,end, 'pin')
usp.val <- ObservationValidation(user.name, pass.word, 95, 
                                   start,end, 'usp')
ibi.val <- ObservationValidation(user.name, pass.word, 83, 
                                   start,end, 'ibi')




## PDPII:72
## Pinheiros: 99
## Itaquera: 97
## ItaimPaulista: 266
## Congonhas: 73

pdp.ob <- ObservationConcentration(user.name, pass.word, 72, 
                                   start,end, 'pdp')
ita.ob <- ObservationConcentration(user.name, pass.word, 97, 
                                   start,end, 'ita')
pin.ob <- ObservationConcentration(user.name, pass.word, 99, 
                                   start,end, 'pin')
ibi.ob <- ObservationConcentration(user.name, pass.word, 83, 
                                   start,end, 'ibi')
inter.ob <- ObservationConcentration(user.name, pass.word, 262, 
                                   start,end, 'inter')
usp.ob <- ObservationConcentration(user.name, pass.word, 95, 
                                   start,end, 'usp')
pau.ob <- ObservationConcentration(user.name, pass.word, 266, 
                                   start,end, 'pau')
con.ob <- ObservationConcentration(user.name, pass.word, 73, 
                                   start,end, 'con')





# # Background data file
# o3.arar  <- CetesbRetrieveCut(user.name, pass.word, 63, 107, start, end)
# no2.arar <- CetesbRetrieveCut(user.name, pass.word, 15, 107, start, end)
# no.arar  <- CetesbRetrieveCut(user.name, pass.word, 17, 107, start, end)
# 
# arar.df <- data.frame(date = o3.arar$date,
#                      o3  = o3.arar$pol,
#                      no2 = no2.arar$pol,
#                      no  = no.arar$pol)
#                      
# # Replace with NA                     
# for(i in seq(1,ncol(ibi.df))){
#   ibi.df[is.na(ibi.df[,i]), i] <- mean(ibi.df[,i], na.rm = TRUE)
# }
# 
# attributes(ibi.df$date)$tzone <- "UTM"
# ibi.df$date <- format(ibi.df$date, format = '%Y-%m-%d_%H')
# write.table(ibi.df, 'bg_o3_no2_no_ibi.dat', sep = '\t', row.names = F,
#             quote = F)


# Observation data
# no.cc  <- CetesbRetrieveCut(user.name, pass.word, 17, 91, start, end)
# no2.cc <- CetesbRetrieveCut(user.name, pass.word, 15, 91, start, end)
# 
# cc.df <- data.frame(date = no.cc$date, 
#                     nox = no.cc$pol + no2.cc$pol,
#                     no  = no.cc$pol,
#                     no2 = no2.cc$pol)
# 
# for(i in 1:ncol(cc.df)){
#   cc.df[is.na(cc.df[,i]), i] <- mean(cc.df[,i], na.rm = TRUE)
# }
# 
# attributes(cc.df$date)$tzone <- "UTM"
# cc.df$date <- format(cc.df$date, format = '%Y%m%d%H')
# write.table(cc.df, 'obs_nox_no_no2_cc.dat', sep = '\t', row.names = F,
#             quote = F)


# Meteo validation data
## PDPII: 72            ## T2: 25 
## PINHE: 99            ## RH: 28
## IBIRA: 83            ## WD: 23
## INTER: 262           ## WS: 24   
## MTIET: 270
## ITAQU: 97


CetesbMet <- function(user.name, pass.word, est,start,end){
  tc <- CetesbRetrieveCut(user.name, pass.word, 25, est, start, end)
  rh <- CetesbRetrieveCut(user.name, pass.word, 28, est, start, end)
  wd <- CetesbRetrieveCut(user.name, pass.word, 23, est, start, end)
  ws <- CetesbRetrieveCut(user.name, pass.word, 24, est, start, end)
  
  est.df <- data.frame(date = tc$date,
                       tc = tc$pol,
                       rh = rh$pol,
                       wd = wd$pol,
                       ws = ws$pol)
  attributes(est.df$date)$tzone <- "UTM"
  cc.df$date <- format(est.df$date, format = '%Y%m%d%H')
  write.table(est.df, paste0(est,'_met.out'), sep = ',', row.names = F,
              quote = F)
}

met.est <- c(72, 99, 83, 262, 270, 97)

# for (i in met.est){
#   CetesbMet(user.name, pass.word, i, start, end)
# }


#tc <- CetesbRetrieveCut(user.name, pass.word, 24, 72, start, end)
# rh <- CetesbRetrieveCut(user.name, pass.word, 28, est, start, end)
# wd <- CetesbRetrieveCut(user.name, pass.word, 23, est, start, end)
# ws <- CetesbRetrieveCut(user.name, pass.word, 24, est, start, end)
