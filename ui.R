library(shiny)
library(ggplot2)
library(ggmap)
library(sp)
library(dplyr)
library(rgl)
library(rayshader)

ui <- fluidPage(
  br(),
  br(),

  br(),

  fluidRow(
    column(width = 6,
           actionButton("reset","Reset"),
           helpText("1. Double-click the region of interest."),  
           helpText("2. Drag a region and press Zoom to further zoom into the region."),  
           actionButton("zoom","Zoom"),
           helpText("3. Drag a region that you want to make 3D and press 'Make 3D'"),
           actionButton("make_3d","Make 3D"),
           br(),
           br(),
           rglwidgetOutput("threed_map",width = "800px",height = "800px"),
           uiOutput("ui_save_3d")
           ),
    column(
      width = 6,
      plotOutput("map",brush = "brush",dblclick = "dblclick",height = "800px")
    )
    
  )


  
)