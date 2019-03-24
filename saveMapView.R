library(sf)
library(mapview)
library(webshot)


# This script save as png a map made with mapview
# its input its a class sf and dataframe


PlotMapStreet <- function(df){
  plt <- df
  plt$h1 <- plt$h1 * 0
  m <- mapview(plt, zcol = 'h1', legend = F)
  mapshot(m, file = paste0(getwd(), '/', deparse(substitute(df)), '.png'))
}


