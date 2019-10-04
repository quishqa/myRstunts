# Get climatic zone from WUDAPT data
# This information will get us the building height


library(rgdal)
library(raster)


# WUDAPT data
# Building height for LCZ 1:10 --> URBANPARAM WRF (Pellegati et al., 2019)
# Building height for LCZ 101:107 --> From (Stewart et al., 2014)
# Loading wp and coords

# Street coords
coords <- read.table('./new_coords_pdp.txt',
                     header = F, sep = ',', dec = '.',
                     col.names = c('xa', 'xb', 'ya', 'yb'))

# This function extract building height from WUDAPT raster file
BuildingHeightWudapt <- function(coords){
  lcz <- data.frame(lcz = c(1:10, c(101:107)), 
                    bh  = c(45, 15, 5, 40, 15, 5, 3, 7, 5, 8.5, 
                            20, 7.5, 1.5, 1, 0.05, 0.1, 0.05),
                    name = paste0("LCZ", c(1:10, LETTERS[1:7])))
  wp <- raster('./wudapt_utm.tif')  # Loading WUDAPT raster file
  wp <- as.factor(wp)
  
  rat <- levels(wp)[[1]]
  rat[['LCZ']] <- lcz$name
  levels(wp) <- rat
  
  # We extract the building height at street start
  ref <- coords[c('xa', 'ya')]
  coordinates(ref) <- ~xa + ya
  coords$lcz <- extract(wp, ref)
  coords <- join(coords, lcz)
  return(coords$bh)
}
