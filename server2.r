options(encoding = 'UTF-8')
#open libraries
library(shiny)
library(openair)
#define ability to open large files
options(shiny.maxRequestSize = -1)
# Define server logic for random distribution application
shinyServer(function(input, output,session) {
  #opening the file
  userdata <- reactive(function(){
    if(is.null(input$bugs)){return()}
    bugs <- read.csv(input$bugs$datapath, header=TRUE)
  })
  
  observe({
    df <- userdata()
    str(names(df))
    if (!is.null(df)) {
      updateSelectInput(session,"pollutant", choices =c("no pollutant", names(df)))  
      updateSelectInput(session,"wd", choices = names(df)) 
      updateSelectInput(session,"ws", choices = names(df)) 	  
    }
  }) 
  
  
  # Generate a plot of the data. Also uses the inputs to build the 
  # plot label. Note that the dependencies on both the inputs and
  # the 'data' reactive expression are both tracked, and all expressions 
  # are called in the sequence implied by the dependency graph
  output$plot <- renderPlot({
    if(is.null(input$bugs)){return()}
    if(input$pollutant=="no pollutant"){
      data<-userdata()
      data[,input$ws]<-as.numeric(as.character(data[,input$ws]))
      hist(data[,input$ws], main="wind speed histogram", freq=FALSE)
    }
    else
    {
      data<-userdata()
      data[,input$ws]<-as.numeric(as.character(data[,input$ws]))
      data[,input$pollutant]<-as.numeric(as.character(data[,input$pollutant]))
      par(mfrow=c(1,2))
      hist(data[,input$ws], main="wind speed histogram", freq=FALSE)
      hist(data[,input$pollutant], main=paste(input$pollutant," histogram"), freq=FALSE)
    }
  })
  
  # data summary##
  output$summary <- renderPrint({
    Availability<-sum(is.na((as.numeric(as.character(userdata()[,input$pollutant])))))/length(userdata()[,input$pollutant])*100 
    Availability1<-sum(is.na((as.numeric(as.vector(userdata()[,input$ws])))))/length(userdata()[,input$ws])*100 
    Availability2<-sum(is.na((as.numeric(as.vector(userdata()[,input$wd])))))/length(userdata()[,input$wd])*100 
    print(paste("The availability of the",input$pollutant," is: ",100-Availability,"%"))
    print(paste("The availability of the wind speed is:",100-Availability1,"%" ))
  })
  ##################wind rose################
  #build the wind rose
  plotwindrose<-reactive(function() {
    data<-userdata()
    angle<-360/as.numeric(input$directions)
    data[,input$ws]<-as.numeric(as.character(data[,input$ws]))
    data[,input$wd]<-as.numeric(as.character(data[,input$wd]))
    if(input$sorted=="no sorting"){
      p<-windRose(data,ws=input$ws, wd=input$wd,angle=angle)
    }
    else{
      p<-windRose(data,type=input$sorted,ws=input$ws, wd=input$wd,angle=angle)
    }
  })
  #show the wind rose
  output$windrose <- renderPlot({
    print(plotwindrose())
  })
  #download the wind rose
  output$downloadPlot2 <- downloadHandler(
    filename = function() { paste(input$bugs,"wind rose", ".png", sep="") },
    content = function(file) {
      png(file)
      print(plotwindrose())
      dev.off()
    })
  ##################pollution rose################
  #build the pollution rose
  plotpollutionrose<-reactive(function() {
    data<-userdata()
    data[,input$pollutant]<-as.numeric(as.character(data[,input$pollutant]))
    data[,input$ws]<-as.numeric(as.character(data[,input$ws]))
    data[,input$wd]<-as.numeric(as.character(data[,input$wd]))
    k<-as.numeric(input$k)
    if(input$sorted=="no sorting"){
      a<-polarPlot(data,wd=input$wd,x=input$ws,pollutant=input$pollutant,k=k )
    }
    else{
      a<-polarPlot(data,wd=input$wd,x=input$ws,pollutant=input$pollutant,type=input$sorted, k=k)
    }
  })
  # show the pollution rose
  output$pollutionrose <- renderPlot({
    print(plotpollutionrose())
    
  })
  #download the pollution rose
  output$downloadPlot3 <- downloadHandler(
    filename = function() { paste(input$bugs," pollution rose", ".png", sep="") },
    content = function(file) {
      png(file)
      print(plotpollutionrose())
      dev.off()
    })
})
