library(rvest)
library(geniusR)
library(reticulate)
library(tidyverse)
library(tidytext)
# get data from python script

source_python("C:/Users/eliavsc/Documents/R scripts/ent.py", convert = TRUE)
#place <- py$places()
#flat_places <- sapply(place[[2]], function(x) as.character(x$parent))

# url of dylan discography
url <- "https://en.wikipedia.org/wiki/Bob_Dylan_discography"

# read table
read <- read_html(url)
tab <- html_nodes(read, xpath='//*[@id="mw-content-text"]/div/table[2]')
table <- html_table(tab, fill=TRUE)

# sort names of albums and release dates
structered <- str_split( table[[1]][[2]],pattern = '\n')
album_name <- vapply(structered, FUN = function(x) x[1], FUN.VALUE = 'a')
release_date <- vapply(structered, FUN = function(x) x[2], FUN.VALUE = 'a')
album_data_frame <- na.omit(data.frame(album_name, release_date))

# get lyrics to al albums 
all_songs <- apply(album_data_frame, 1 ,FUN = function(x) 
  tryCatch(
    genius_album(artist = "Bob Dylan",album =  x[1]),
    error = function(e) print(e)))

album_names <- gsub(" ", "_", album_name[2:37])
# sort all lyrics  
for (i in 1:36){
  assign(x = paste0(trimws(album_names[i])),
         tryCatch(
           aggregate(data.frame(all_songs[[i]]), list(data.frame(all_songs[[i]])[,1]),
                            FUN = function(x) paste0(unique(x))),
           error = function(e) print(e)))
  print(album_names[i])
}

df <- data.frame()
for (disk in complex_structure){
  for (song in disk$lyric){
    song_words <- unlist(song) %>% as.tibble() %>% unnest_tokens(word, value) %>% anti_join(stop_words) %>% unique() %>% py$places()
    placed_words <- sapply(song_words[[2]], function(x) as.character(x$parent))
    if(length(placed_words) >0){
      df <- rbind(df, data.frame(placed_words))
    }
  }
}
print(df)
barplot(sort(table(df)), col=rgb(0.2,0.4,0.6,0.6), horiz=T , las=1)
#sapply(album_names, FUN = function(x) print(get(x)$lyric))
#tab <- unlist(sapply(album_names, FUN = function(x) get(x)$lyric)) %>%
#  as.tibble %>%
#    unnest_tokens(word,value) %>%
#    anti_join(stop_words) %>% py$places()
#flat_places <- sapply(place[[2]], function(x) as.character(x$parent))
#print(flat_places)
