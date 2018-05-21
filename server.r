Sys.setlocale(category = "LC_ALL", locale = "hebrew")
#reticulate::use_virtualenv('/home/fooling', required = TRUE)
library(shiny)
library(rgdal)
library(akima) 
library(reshape2)
library(ggmap)
library(raster)
library(reticulate)
library(tidyverse)
library(tidytext)
options(shiny.maxRequestSize = -1)
# Define server logic required to summarize and view the selected dataset
shinyServer(function(input, output,session) {
source_python("ent.py", convert = TRUE)
  userdata <- reactive({
    if(is.null(input$bugs)){return()}
	if(input$need_proj=="unstructered"){
	bugs <-readLines(input$bugs$datapath)}
    if(input$need_proj=="text"){
	Sys.setlocale(category = "LC_ALL", locale = "hebrew")
      bugs <- read.csv(input$bugs$datapath, header=FALSE, sep=",",fileEncoding="iso-8859-8", stringsAsFactors =F)
	 bugs<-cbind(enc2utf8(as.vector(bugs[,1])),bugs[,2])
     #bugs<-iconv(bugs,"iso-8859-8","UTF-8")
    }
    else
      bugs <- read.csv(input$bugs$datapath, header=FALSE)
  })
  #this is the search bar
  datasetInput <- reactive({
    EPSG<-make_EPSG()
    matrix(EPSG[grep(input$search, EPSG$note, ignore.case=TRUE), 1:2]$note)
    
  })
  #this takes the search bar result and makes it in to a selection
  output$selectUI <- renderUI({ 
    selectInput("projection", "Select your choice", datasetInput()[,1] )
  })
  ####this is the projection parameters
  converted<-reactive({
    EPSG<-make_EPSG()
    foo<-EPSG[grep(input$projection,EPSG$note),]
    return(foo$prj4)
  })
  ######convert data
  converted_data<-reactive({
    data<-userdata()
    if(input$need_proj=="latlon")
      return(data)
    if(input$need_proj=="projected"){
      foo<-project(as.matrix(data[1:2]),converted(), inv=T)
      foo<-cbind(foo,data[3])
      names(foo)<-names(data)
      return(foo)
    }
    if(input$need_proj=="text"){
      foo<-geocode(data[,1])
      d<-cbind(foo,data[,2])
      names(d)<-c("V1", "V2","V3")
      d<-na.omit(d)
      return(d)
    }
	if(input$need_proj=="unstructered"){
	#d <- as.tibble(data)
   b<- unique(unlist(strsplit(as.character(data[[1]]), " "))) %>% as.tibble
   names(b) <- "word"
  d <- anti_join(b, stop_words) %>% py$places()
	tab <- sapply(d[[2]], function(x) as.character(x$parent))
	foo <- geocode(tab)
	bar <- cbind(tab,foo)
	names(bar)<-c("V1", "V2","V3")
	return(bar)
	}
  })
  # Shows a table of the conversion parameters
  output$view <- renderPrint({
    print(converted())
  })
  ##show converted data on table
  output$contents <- renderTable({
    #  data<-userdata()
    data1<-converted_data()
    return(data1)
  })
  ####build point map
  plotdatamap<-reactive({
    data<-converted_data()
    print(data)
    print(class(data))
    print(class(data$V2))
    if (length(data[1])==1) {
      p <- ggmap(get_map(location = c(lon = as.numeric(data$V2),lat= as.numeric(data$V3)), zoom = 'auto',maptype="roadmap"))
    }
    else
        p<-ggmap(get_map(location = c(left = min(data$V1), bottom = min(data$V2), right =max(data$V1) , top = max(data$V2)),maptype="roadmap"))
    v<-p+geom_point(aes(x=V1, y=V2, colour = V3, size=V3),data=data, alpa=0.5)+ scale_colour_gradient(low = "blue", high="red")
    kml()
    print(v)
  })
  #######contour map
  countourmap <- reactive({
    data<-converted_data()
    p<-ggmap(get_map(location = c(left = min(data$V1), bottom = min(data$V2), right =max(data$V1) , top = max(data$V2)),maptype="roadmap"))
    fld <- with(data, interp(x = V1, y = V2, z = V3, duplicate="mean"))
    df <- melt(fld$z, na.rm = TRUE)
    names(df) <- c("x", "y", "conc")
    df$Lon <- fld$x[df$x]
    df$Lat <- fld$y[df$y]
    v<-p+geom_tile(data = df, aes(x = Lon, y = Lat, z = conc, fill = conc), alpha = input$alpha) + scale_fill_gradient(low="green", high="red")+
    stat_contour(data = df, aes(x = Lon, y = Lat, z = conc))
    nw<-cbind(df$Lon,df$Lat,df$conc)
    a<-rasterFromXYZ(nw)
    projection(a)<-CRS("+init=epsg:4326")
	ramp <- colorRamp(c("green", "red"))
	KML(a, file="contour.kmz",col=rgb( ramp(seq(0, 1, length = 10)), max = 255), overwrite=TRUE)
    print(v) 
  })
  ############function to make KML point data 
  kml<-reactive({
    data<-converted_data()
    coordinates(data)<-c("V1","V2")
    proj4string(data)<-CRS("+init=epsg:4326")
    bb_ll<-spTransform(data,CRS("+proj=longlat +datum=WGS84"))
    bb_ll<-writeOGR(bb_ll,"data.kml","V3","KML")
    return(bb_ll)
  })
  #######download point data as KML
  output$downloaddatamapkml<-downloadHandler(
    filename="data.KML",content=function(file){
      file.copy("data.kml",file)
    })
	#######download contour map as KML
  output$downloadmapkml<-downloadHandler(
    filename="contour.kmz",content=function(file){
      file.copy("contour.kmz",file)
    })
  ###########show data map 
  output$datamap<-renderPlot({
    print(plotdatamap())
  })
  ####download data map
  output$downloaddatamap <- downloadHandler(
    filename = function() { paste(input$bugs,"data_map", ".png", sep="") },
    content = function(file) {
      png(file)
      print(plotdatamap())
      dev.off()
    })
  ######show contour map
  output$map<-renderPlot({
    print(countourmap())
  })
  ####download contour map 
  output$downloadmap<-downloadHandler(
    filename = function() { paste(input$bugs,"contour_map", ".png", sep="") },
    content = function(file) {
      png(file)
      print(countourmap())
      dev.off()
    })
})