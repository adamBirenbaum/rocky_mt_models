
path_to_directory <- "D:/abire/Documents/rocky_mt_models/"

server <- function(input, output,session) {
  region_df <<- read.csv(paste0(path_to_directory,"data_coordinates_long.csv"),stringsAsFactors = F)
  region_info_df <<- read.csv(paste0(path_to_directory,"data_coordinates.csv"),stringsAsFactors = F)
  
  correct_region <- 0
  
  is_error <- function(x) inherits(x,"try-error")
  
  states_df <- data.frame(x = c(-114.0508,-102.04,-102.04,-109.05,-109.05,-111.047,-111.047,-114.042,-111.047,-104.0577),
                          xend = c(-102.04,-102.04,-109.05,-109.05,-111.047,-111.047,-114.042,-114.042,-104.0577,-104.05),
                          y = c(37,37,41,41,41,41,42,42,45,45),
                          yend = c(37,41,41,37,41,45,42,37,45,41))
  
  get_map_safely <- function(custom_bbox,zoom,maptype){
    g <- try(get_stamenmap(bbox = custom_bbox, zoom = zoom, maptype = maptype))

    error_in_map <- is_error(g)
    while (error_in_map) {
      Sys.sleep(4)
      g <- try(get_stamenmap(bbox = custom_bbox, zoom = zoom, maptype = maptype))
      error_in_map <- is_error(g)
      
    }
    g
  }
  
  get_bbox_from_click <- function(click_region_df){

    with(data = click_region_df,c('left' = min(long), 'right' = max(long),'top' = max(lat),'bottom' = min(lat)))
  }
  
  get_bbox <- function(brush){
    
    bbox <- c(brush$xmin,brush$ymin,brush$xmax,brush$ymax)
    names(bbox) <- c("left","bottom","right","top")
    bbox
  }
  
  filter_region_df <- function(correct_region,limits) {
    
    region_coordinates <- region_info_df[correct_region,]
    
    load(paste0(path_to_directory,"data_files/m",correct_region,".RData"))
    assign("m",get(paste0("m",correct_region)))
    rm(list = paste0("m",correct_region))
    
    ncols <- dim(m)[2]
    resolution <- (region_coordinates$xmax - region_coordinates$xmin) / ncols
    
    xmin_index <- floor(abs(limits$xmin - region_coordinates$xmin) / resolution)
    xmax_index <- ceiling(abs(limits$xmax- region_coordinates$xmin) / resolution)
    
    ymin_index <- ceiling(abs(region_coordinates$ymax - limits$ymax) / resolution)
    ymax_index <- floor(abs(region_coordinates$ymax - limits$ymin ) / resolution)
    

    m[ymin_index:ymax_index,xmin_index:xmax_index]
  }
  
  calculate_zscale <- function(m, limits){
    
    #miles per degree
    d_latitude <- 69.172
    
    height_miles <- (limits$ymax - limits$ymin) * d_latitude
    nrows <- dim(m)[1]
    
    (height_miles / nrows) * 1609.3
    
  }
  
  observeEvent(input$reset,{
    
    first_box <- c("left" = -114.54841312748, "right" = -101.72235567187, "top" = 45.16987829678, "bottom" = 36.563926697386)
    
    g  <- get_map_safely(first_box,zoom = 6,maptype = "terrain") 
    gmap <<-  ggmap(g)
    
    
    

    

    
    output$map <- renderPlot({
      gmap + geom_polygon(data = region_df,aes(x = long, y = lat,group = factor(id)),alpha = 0,color = "black") +
        geom_segment(data = states_df,aes(x = x, xend = xend, y = y ,yend = yend), color = "red",size = 2)
      
    })

  }
               
               )
  
 output$map <- renderPlot({


   first_box <- c("left" = -114.54841312748, "right" = -101.72235567187, "top" = 45.16987829678, "bottom" = 36.563926697386)
  

   
   g  <- get_map_safely(first_box,zoom = 6,maptype = "terrain") 
   gmap <<-  ggmap(g)
  
   
   
     gmap + geom_polygon(data = region_df,aes(x = long, y = lat,group = factor(id)),alpha = 0,color = "black") +
   geom_segment(data = states_df,aes(x = x, xend = xend, y = y ,yend = yend), color = "red",size = 2)
 })
   
  
 observeEvent(input$dblclick,{
   
   points <- c(input$dblclick$x,input$dblclick$y)

   


   for (i in 1:80){
     
     sub_df <- region_df %>% filter(id == i)
     in_polygon <- point.in.polygon(points[1],points[2],sub_df$long,sub_df$lat)
     if (in_polygon == 1){
       correct_region <<- i
       break
     }
   }


   final_region <<- region_df %>% filter(id == correct_region)
   new_bbox <- get_bbox_from_click(final_region)
   gmap  <<- get_map_safely(new_bbox,zoom = 10,maptype = "terrain") 
   gmap <<- ggmap(gmap)
   output$map <- renderPlot(
     gmap +    geom_polygon(data = final_region,aes(x = long, y = lat,group = factor(id)),alpha = 0,color = "black")


   )
 })
 
 observeEvent(input$zoom,{

   

   gbbox <- get_bbox(input$brush)
   gzoom <- calc_zoom(gbbox)
   
   output$map <- renderPlot({
     
     gmap <<- get_map_safely(gbbox,zoom = gzoom, maptype = "terrain")
     gmap <<- ggmap(gmap)
     gmap
     
   })
   
   session$resetBrush("brush")

 })
  
 get_limits <- function(brush){
   list(xmin = brush$xmin, xmax = brush$xmax, ymin = brush$ymin, ymax = brush$ymax)
 }
 
 observeEvent(input$make_3d,{

   
   limits <- get_limits(input$brush)
   
   m <- filter_region_df(correct_region, limits)

   
   rev_m <- make_skew_identify(dim(m)[2])
   
   m <- m %*% rev_m
   calc_zscale <- calculate_zscale(m, limits)
  
   m %>% sphere_shade(texture = "desert") %>%
     add_shadow(ray_shade(m,zscale = calc_zscale)) %>% 
     add_shadow(ambient_shade(m,zscale = calc_zscale)) %>% 
     #add_water(detect_water(m,zscale = calc_zscale,cutoff = .99),color = "desert") %>% 
     plot_3d(m,zscale = calc_zscale) 
   
   output$threed_map <- renderRglwidget({
     rglwidget()

     
   })
     
    output$ui_save_3d <- renderUI({
      tagList(
        helpText("4. Press '3D Print' to save as a file for 3d printing"),
        column(width = 6,
               downloadButton("save_3d","3D Print File")
               ),
        column(width = 6,
               selectInput("print_width", "Max Width (in)",choices = 4:10,selected = 4)
               )
        
      )
      
    })
    
    
 })
 
 make_skew_identify <- function(n){
   
   matrix(c(rep(0,n-1),rep(c(1,rep(0,n-2)),n),0),ncol = n)
   
 }
 
 

   output$save_3d <-downloadHandler(
     filename <- function(){
       name=gsub(' ','--',Sys.time())
       name=gsub(':','-',name)
       paste('3d_printable_file--',name,'.stl', sep='')
     },
     content=function(file){
       rayshader::save_3dprint(filename = file,maxwidth = as.numeric(input$print_width),unit = "in")
       

       
     }
   )

  
}