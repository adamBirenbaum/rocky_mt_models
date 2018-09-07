
library(raster)

files <- read.table("D:/abire/Documents/map_project/map_zips.txt",stringsAsFactors = F)


df <- data.frame(xmin = integer(0), xmax = integer(0), ymin = integer(0), ymax = integer(0))

for (i in 1:length(files$V1)){
  print(i)
  download.file(files$V1[i],file.path("D:/abire/Documents/map_project/",basename(files$V1[i])))
  zip_directory <- file.path("D:/abire/Documents/map_project/",basename(files$V1[i]))
  non_zip_directory <- gsub(".zip","",zip_directory,fixed = T)
  dir.create(non_zip_directory)
  unzip(file.path("D:/abire/Documents/map_project/",basename(files$V1[i])),exdir = non_zip_directory)
  
  correct_direct <- list.dirs(non_zip_directory)[2]
  r <- raster(file.path(correct_direct,"w001001.adf"))
  df <- rbind(df, data.frame(xmin = r@extent[1], xmax = r@extent[2], ymin = r@extent[3], ymax = r@extent[4]))
  assign(paste0("m",i),as.matrix(r)) 
  save(list = paste0("m",i),file = paste0("D:/abire/Documents/map_project/data_files/m",i,".RData"))
  rm(list = paste0("m",i))
  unlink(zip_directory,recursive = T)
  unlink(non_zip_directory,recursive = T)
  
  
}
df$id <- 1:80
library(dplyr)
library(tidyr)
library(ggplot2)
library(ggmap)

df1 <- df %>% select(-ymin,-ymax) %>% 
  gather("a","long",c(xmin,xmax))

df2 <- df %>% select(-xmin,-xmax) %>% 
  gather("a","lat",c(ymin,ymax))

final_df <- left_join(df1,df2,by = "id") %>% arrange(id) %>% select(-a.x,-a.y)

final_df2 <- final_df %>% group_by(id) %>% mutate(id2 = c(1,2,4,3)) %>% arrange(id2) %>% ungroup() %>% arrange(id) %>% select(-id2)
final_df2 <- final_df2 %>% group_by(id) %>% mutate(avg_long = mean(long), avg_lat = mean(lat))

ggplot(final_df2,aes(x = long, y = lat,group = factor(id))) + geom_polygon(fill = "red",alpha = 0.7,color = "black")

write.csv(df,"D:/abire/Documents/map_project/data_coordinates.csv",row.names = F)
write.csv(final_df2,"D:/abire/Documents/map_project/data_coordinates_long.csv",row.names = F)


g  <- get_map(location = c(-109,41),zoom = 6,maptype = "roadmap",source="google")

ggmap(g) + geom_polygon(data = final_df2,aes(x = long, y = lat,group = factor(id)),fill = "blue",alpha = 0.08,color = "black") 


