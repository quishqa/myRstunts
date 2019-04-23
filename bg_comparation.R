library(openair)



munich <- '~/munich/SinG-training/MUNICH/munich-pre_postprocessing/preprocessing/'
results.path <- 'bg_jund_test/results'

LoadMunichOutput <- function(all.path){
  files <- list.files(all.path, pattern = '201802', full.names = T )
  files.dates <- list.files(all.path, pattern = '2018')
  
  output <- lapply(files, 
                   function(x) read.table(x,header = F, sep = '\t', 
                                          stringsAsFactors = F,
                                          dec = '.', 
                                          col.names = c('link', 'o3', 'no', 'no2', 'nothing')))
  
  h.means <- lapply(output, colMeans)
  h.df <- as.data.frame(do.call(rbind, h.means))
  h.df$date <- as.POSIXct(strptime(files.dates, "%Y%m%d_%H-%M"), tz = 'UTM')
  h.df <- h.df[, c('date', 'o3', 'no', 'no2')]
  return(h.df)
}


pin.jund <- LoadMunichOutput(paste0(munich, results.path)
