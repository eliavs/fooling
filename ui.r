options(encoding = 'UTF-8')
library(shiny)
userdata <- list('Upload a file'=c(1))
# Define UI for dataset viewer application
shinyUI(pageWithSidebar(
  
  # Application title
  headerPanel("Unstructered text to geolocation"),
  
  # Sidebar with controls to select a dataset and specify the number
  # of observations to view
  sidebarPanel(
    wellPanel(
      fileInput("bugs", "Input Data"),
      radioButtons("need_proj", "data type:",
                   c("Lat Lon" = "latlon",
                     "projected" = "projected",
                     "Text" = "text",
					 "Unstructered Text"= "unstructered"))
    ),
    textInput("search", "enter a country", value="israel"),
    htmlOutput("selectUI"),
    sliderInput("alpha", "transperity", min = 0, max = 1, value = 0.5, step= 0.1)
  ),
  
  # Show a summary of the dataset and an HTML table with the requested
  # number of observations
  mainPanel(
    tabsetPanel(
      tabPanel("proj",verbatimTextOutput("view")),
      tabPanel( "data",tableOutput('contents'),downloadButton("downloaddata", "download the data")),
      tabPanel("datamap",plotOutput('datamap'),downloadButton('downloaddatamap',"Download map"),downloadButton("downloaddatamapkml","download as kml")),
      tabPanel( "map", plotOutput('map'),downloadButton('downloadmap', 'Download map'),downloadButton("downloadmapkml","download as kml"))
    )
  )
))