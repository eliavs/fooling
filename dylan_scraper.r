library(rvest)
library(geniusR)
library(reticulate)
library(tidyverse)
library(ggmap)
library(nominatim)
library(tidytext)
## get data from python script
#
source_python("ent.py", convert = TRUE)
#Sys.setenv(RETICULATE_PYTHON = "c:/Users/eliavsc/AppData/Local/Programs/Python/Python36-32/python.exe")

#
## url of dylan discography
#url <- "https://en.wikipedia.org/wiki/Bob_Dylan_discography"
#
## read table
#read <- read_html(url)
#tab <- html_nodes(read, xpath='//*[@id="mw-content-text"]/div/table[2]')
#table <- html_table(tab, fill=TRUE)
#
## sort names of albums and release dates
#structered <- str_split( table[[1]][[2]],pattern = '\n')
#album_name <- vapply(structered, FUN = function(x) x[1], FUN.VALUE = 'a')
#release_date <- vapply(structered, FUN = function(x) x[2], FUN.VALUE = 'a')
#album_data_frame <- na.omit(data.frame(album_name, release_date))
#
## get lyrics to al albums 
#all_songs <- apply(album_data_frame, 1 ,FUN = function(x) 
#  tryCatch(
#    genius_album(artist = "Bob Dylan",album =  x[1]),
#    error = function(e) print(e)))
#
#album_names <- gsub(" ", "_", album_name[2:37])
## sort all lyrics  
#for (i in 1:36){
#  assign(x = paste0(trimws(album_names[i])),
#         tryCatch(
#           aggregate(data.frame(all_songs[[i]]), list(data.frame(all_songs[[i]])[,1]),
#                            FUN = function(x) paste0(unique(x))),
#           error = function(e) print(e)))
#  print(album_names[i])
#}
complex_structure <- sapply(album_names, FUN = function(x) get(x))
#df <- data.frame()
#for (disk in complex_structure){
#  for (song in disk$lyric){
#    song_words <- unlist(song) %>% as.tibble() %>% unnest_tokens(word, value) %>% anti_join(stop_words) %>% unique() %>% py$places()
#    placed_words <- sapply(song_words[[2]], function(x) as.character(x$parent))
#    if(length(placed_words) >0){
#      df <- rbind(df, data.frame(placed_words))
#    }
#  }
#}
#print(df)
#barplot(sort(table(df)), col=rgb(0.2,0.4,0.6,0.6), horiz=T , las=1)
#geocoded  <- osm_geocode(df[,1],email="eliavs@gmail.com", key="eaj6RYIerxvpi260F9wmymNeL5AlYnTV")
#data_to_map <-  geocoded [,""]
#sapply(album_names, FUN = function(x) print(get(x)$lyric))
#tab <- unlist(sapply(album_names, FUN = function(x) get(x)$lyric)) %>%
#  as.tibble %>%
#    unnest_tokens(word,value) %>%
#    anti_join(stop_words) %>% py$places()
#flat_places <- sapply(place[[2]], function(x) as.character(x$parent))
#print(flat_places)

#test_for_places <- function(lyrics){
#  song_words <- unlist(lyrics) %>% as.tibble() %>% unnest_tokens(word, value) %>% anti_join(stop_words) %>% unique() %>% py$places()
#  placed_words <- sapply(song_words[[2]], function(x) as.character(x$parent))
#  if(length(placed_words) >0){
#    return(paste(placed_words)) 
#  }
#  else return(NULL)
#  
#}
#
#dat <- by(disk, 1:nrow(disk), FUN = function(row) list(row$track_title,unlist(test_for_places(row$lyric))))
#by(disk, 1:nrow(disk), FUN = function(row) print(c(row$track_title, row$track_n)))
#

songs_df = data.frame(album = character(), track_title = character(), place = character())
for (y in 1:length(complex_structure)){
  disk_name <- names(complex_structure[y])
  if (is.null(complex_structure[y])){next}
  for (i in 1:nrow(complex_structure[[y]])){
    structered <- unlist(complex_structure[[y]][i,]$lyric) %>% as.tibble() %>% unnest_tokens(word, value) %>% anti_join(stop_words) %>% unique()
    tryCatch(
      placed <- py$places(structered),finally = print("error"))
    if (placed[1] != 'error'){
      for (item in placed[[2]])
        songs_df = rbind(songs_df, data.frame(disk_name, complex_structure[[y]][i,]$track_title, as.character(item$parent)))
      print(class(item$parent))
    }
  }
}
print(songs_df)