library(raster)
library(dplyr)
library(tidyr)

###### SETUP ######
##
## This script is used to download elevation files, read the data and save as an .RData file
##
## For this to work you must do the following:
##
##    1.  Make sure you have downloaded the zip files as a txt document as described in the ReadMe
##    2.  Change the path_to_directory variable to the location of your repository.
##    3.  Within your rocky_mt_models folder, make a new folder called data_files
##
##    Once that is done, you're ready to source the script.  Depending on your computer, and the number of files,
##    it could take a decent amount of time.  It took my computer ~ 2 hours to do 80 files.

path_to_directory <- "D:/abire/Documents/rocky_mt_models/"





files <- read.table(paste0(path_to_directory,"map_zips.txt"),stringsAsFactors = F)

df <- data.frame(xmin = integer(0), xmax = integer(0), ymin = integer(0), ymax = integer(0))

for (i in 1:length(files$V1)){
  print(i)
  download.file(files$V1[i],file.path(path_to_directory,basename(files$V1[i])))
  zip_directory <- file.path(path_to_directory,basename(files$V1[i]))
  non_zip_directory <- gsub(".zip","",zip_directory,fixed = T)
  dir.create(non_zip_directory)
  unzip(file.path(path_to_directory,basename(files$V1[i])),exdir = non_zip_directory)
  
  correct_direct <- list.dirs(non_zip_directory)[2]
  r <- raster(file.path(correct_direct,"w001001.adf"))
  df <- rbind(df, data.frame(xmin = r@extent[1], xmax = r@extent[2], ymin = r@extent[3], ymax = r@extent[4]))
  assign(paste0("m",i),as.matrix(r)) 
  save(list = paste0("m",i),file = paste0(path_to_directory,"data_files/m",i,".RData"))
  rm(list = paste0("m",i))
  unlink(zip_directory,recursive = T)
  unlink(non_zip_directory,recursive = T)
  
  
}

nfiles <- length(files$V1)
df$id <- 1:nfiles


df1 <- df %>% select(-ymin,-ymax) %>% 
  gather("a","long",c(xmin,xmax))

df2 <- df %>% select(-xmin,-xmax) %>% 
  gather("a","lat",c(ymin,ymax))

final_df <- left_join(df1,df2,by = "id") %>% arrange(id) %>% select(-a.x,-a.y)

final_df2 <- final_df %>% group_by(id) %>% 
  mutate(id2 = c(1,2,4,3),
         avg_long = mean(long), 
         avg_lat = mean(lat)) %>% 
  arrange(id2) %>% 
  ungroup() %>% 
  arrange(id) %>% 
  select(-id2)


write.csv(df,paste0(path_to_directory,"data_coordinates.csv"),row.names = F)
write.csv(final_df2,paste0(path_to_directory,"data_coordinates_long.csv"),row.names = F)
