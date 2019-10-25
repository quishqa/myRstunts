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
  
  # Creating a complete date data frame to merge and to pad out with NA
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
  
  # These are the columns of the html table
  cet.names <- c('emp1', 'red', 'mot', 'type', 'day', 'hour', 'cod', 'est',
                 'pol', 'unit', 'value', 'mov','test', 'dt.amos', 'dt.inst',
                 'dt.ret', 'con', 'tax', 'emp2')
  
  # In case there is no data
  if (ncol(dat) != 19){
    dat <- data.frame(date = all.dates$date , pol = rep(NA, nrow(all.dates)))
  } else if (ncol(dat) == 19) {
    names(dat) <- cet.names
    dat$date <- paste(dat$day, dat$hour, sep = '_')
    dat$date <- as.POSIXct(strptime(dat$date, format = '%d/%m/%Y_%H:%M'))
    dat <- merge(all.dates, dat, all = T)
    dat$value <- as.numeric(gsub(",", ".", gsub("\\.", "", dat$value)))
    dat <- data.frame(date = all.dates$date , pol = dat$value)
  }
  return(dat)
}




CetesbRetrievePol <- function(user.name, pass.word,
                              est.name, start.date, 
                              end.date){
  o3 <- CetesbRetrieveCut(user.name, pass.word, 63,
                          est.name, start.date, 
                          end.date)
  no <- CetesbRetrieveCut(user.name, pass.word, 15,
                          est.name, start.date, 
                          end.date)
  no2 <- CetesbRetrieveCut(user.name, pass.word, 17,
                          est.name, start.date, 
                          end.date)
  photo_pol <- data.frame(date = o3$date,
                          o3 = o3$pol,
                          no = no$pol,
                          no2 = no2$pol)
  return(photo_pol)
  
}





user.name <- 'YYYYYYYYY'
pass.word <- 'XXXXXXXXX'
pol.name <- 63   # ozone
est.name <- 99   # pinheiros
start.date <- '01/11/2013'
end.date <- '30/11/2013'



pin_photo <- CetesbRetrievePol(user.name, pass.word, est.name, start.date, end.date)
