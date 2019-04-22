library(openair)



munich <- '~/munich/SinG-training/MUNICH/munich-pre_postprocessing/preprocessing/'
results.path <- 'bg_jund_test/results'

all.path <- paste0(munich, results.path)

files <- list.files(all.path, pattern = '201802', full.names = T )

output <- lapply(files, 
                 function(x) read.table(x,header = F, sep = '\t', 
                                        stringsAsFactors = F,
                                        dec = '.', 
                                        col.names = c('link', 'o3', 'no', 'no2', 'nothing')))

h.means <- lapply(output, colMeans)
h.df <- as.data.frame(do.call(rbind, h.means))
