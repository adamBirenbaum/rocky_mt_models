
server <- function(input, output,session) {
  region_df <<- read.csv("D:/abire/Documents/map_project/data_coordinates_long.csv",stringsAsFactors = F)
  region_info_df <<- read.csv("D:/abire/Documents/map_project/data_coordinates.csv",stringsAsFactors = F)
  
  correct_region <- 0
  
  is_error <- function(x) inherits(x,"try-error")
  
  states_df <- data.frame(x = c(-114.0508,-102.04,-102.04,-109.05,-109.05,-111.047,-111.047,-114.042,-111.047,-104.0577),
                          xend = c(-102.04,-102.04,-109.05,-109.05,-111.047,-111.047,-114.042,-114.042,-104.0577,-104.05),
                          y = c(37,37,41,41,41,41,42,42,45,45),
                          yend = c(37,41,41,37,41,45,42,37,45,41))
  
  get_map_safely <- function(location,zoom,maptype, source){
    g <- try(get_map(location = location, zoom = zoom, maptype = maptype, source = source))
    
    error_in_map <- is_error(g)
    while (error_in_map) {
      Sys.sleep(4)
      g <- try(get_map(location = location, zoom = zoom, maptype = maptype, source = source))
      error_in_map <- is_error(g)
      
    }
    g
  }
  
  get_bbox <- function(brush){
    
    bbox <- c(brush$xmin,brush$ymin,brush$xmax,brush$ymax)
    names(bbox) <- c("left","bottom","right","top")
    bbox
  }
  
  filter_region_df <- function(correct_region,limits) {
    
    region_coordinates <- region_info_df[correct_region,]
    
    load(paste0("D:/abire/Documents/map_project/data_files/m",correct_region,".RData"))
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
    gmap  <<- get_map_safely(location = c(-109,41),zoom = 6,maptype = "roadmap",source="google") 
    gmap <<-  ggmap(gmap)
    
    output$map <- renderPlot({
      gmap + geom_polygon(data = region_df,aes(x = long, y = lat,group = factor(id)),alpha = 0,color = "black") +
        geom_segment(data = states_df,aes(x = x, xend = xend, y = y ,yend = yend), color = "red",size = 2)
      
    })

  }
               
               )
  
 output$map <- renderPlot({

   gmap  <<- get_map_safely(location = c(-109,41),zoom = 6,maptype = "roadmap",source="google") 
   gmap <<-  ggmap(gmap)
  
   
   
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
   gmap  <<- get_map_safely(location = c(final_region$avg_long[1],final_region$avg_lat[1]),zoom = 9,maptype = "roadmap",source="google") 
   gmap <<- ggmap(gmap)
   output$map <- renderPlot(
     gmap +    geom_polygon(data = final_region,aes(x = long, y = lat,group = factor(id)),alpha = 0,color = "black")


   )
 })
 
 observeEvent(input$zoom,{

   

   gbbox <- get_bbox(input$brush)
   gzoom <- calc_zoom(gbbox)
   
   output$map <- renderPlot({
     
     gmap <<- get_map_safely(location = gbbox,zoom = gzoom, maptype = "roadmap",source = "google")
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
   
   calc_zscale <- calculate_zscale(m, limits)
  
   m %>% sphere_shade(texture = "desert") %>%
     #add_shadow(ray_shade(m,zscale = calc_zscale)) %>% 
     #add_shadow(ambient_shade(m,zscale = calc_zscale)) %>% 
     #add_water(detect_water(m,zscale = calc_zscale,cutoff = .99),color = "desert") %>% 
     plot_3d(m,zscale = calc_zscale) 
   
   output$threed_map <- renderRglwidget({
     rglwidget()

     
   })
     
    output$ui_save_3d <- renderUI({
      tagList(
        helpText("4. Press '3D Print' to save as a file for 3d printing"),
        column(width = 6,
               actionButton("save_3d","3D Print")
               ),
        column(width = 6,
               selectInput("print_width", "Max Width (in)",choices = 4:10,selected = 4)
               )
        
      )
      
    })
    
    
 })
 
 
 observeEvent(input$save_3d,{
  
   rayshader::save_3dprint(filename = "D:/abire/Documents/map_project/saved_3d_print.stl",maxwidth = as.numeric(input$print_width),unit = "in")
 })
  
}