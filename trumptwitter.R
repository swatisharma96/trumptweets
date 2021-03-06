
pkgs <-c('twitteR','ROAuth','httr','plyr','stringr','ggplot2','plotly','downloader', 'jsonlite')
for(p in pkgs) if(p %in% rownames(installed.packages()) == FALSE) {install.packages(p)}
for(p in pkgs) suppressPackageStartupMessages(library(p, quietly=TRUE, character.only=TRUE))

library(foreign)
library(RCurl)


url = ("https://github.com/bpb27/trump_tweet_data_archive/blob/master/master_2018.json.zip?raw=true")
download(url, dest="../data/master_2018.json.zip") 
unzip("../data/master_2018.json.zip", exdir = "../data")
list.files("../data")

url = ("https://github.com/bpb27/trump_tweet_data_archive/blob/master/condensed_2018.json.zip?raw=true")
download(url, dest="../data/condensed_2018.json.zip") 
unzip("../data/condensed_2018.json.zip", exdir = "../data")
list.files("../data")

twitterDataRecent <- stream_in(file("../data/condensed_2018.json"))
twitterDataRecent <- flatten(twitterDataRecent)

twitterData2018 <- stream_in(file("../data/master_2018.json"))
twitterData2018 <- flatten(twitterData2018)

# importing dataset
# source: https://github.com/bpb27
# thanks to Brendan Brown for the data 
twitterData <- read.csv("https://raw.githubusercontent.com/bpb27/political_twitter_archive/master/realdonaldtrump/realdonaldtrump.csv")

library(tidyverse) #tidyverse conflicts with RCurl so wait to load
library(lubridate)

twitterData2018 <- twitterData2018 %>% 
  select(favorite_count, full_text, created_at,retweet_count) %>% 
  filter(!is.na(full_text)) %>%
  separate(created_at, c("Date", "Year"), "\\+0000", remove=TRUE) %>%
  separate(Date, c("Day", "Month", "Date", "Time"), " ", remove=TRUE) %>% 
  unite("Date", c("Date", "Month", "Year", "Time"), sep = " ", remove=TRUE) %>% 
  mutate(Date = dmy_hms(Date)) %>%                                               # creating dates
  arrange(Date) %>%
  rename(text = full_text)

twitterDataRecent <- twitterDataRecent %>%
  select(favorite_count, text, created_at, retweet_count) %>%
  filter(!is.na(text)) %>%
  separate(created_at, c("Date", "Year"), "\\+0000", remove=TRUE) %>%
  separate(Date, c("Day", "Month", "Date", "Time"), " ", remove=TRUE) %>% 
  unite("Date", c("Date", "Month", "Year", "Time"), sep = " ", remove=TRUE) %>% 
  mutate(Date = dmy_hms(Date)) %>%                                               # creating dates
  arrange(Date) 

# removing retweets
twitterData <- twitterData %>% 
  subset(is_retweet=="False") %>%                                                # removing retweets
  select(-is_retweet, -source, -in_reply_to_screen_name, -id_str) %>%                     # removing extra columns
  separate(created_at, c("Date", "Year"), "\\+0000", remove=TRUE) %>%
  separate(Date, c("Day", "Month", "Date", "Time"), " ", remove=TRUE) %>% 
  unite("Date", c("Date", "Month", "Year", "Time"), sep = " ", remove=TRUE) %>% 
  mutate(Date = dmy_hms(Date)) %>%                                               # creating dates
  arrange(Date)                                                                  # order by oldest to newest date

beforeRunning <- twitterData %>%                                                 # creating dataset for pre-campaign tweets
  filter(Date < "2015-06-16 00:00:00") %>%
  mutate(id = row_number())

whileRunning <- twitterData %>%                                                  # creating dataset for tweets during campaign
  filter(Date >= "2015-06-16 00:00:00" & Date < "2017-01-20 09:00:00") %>%
  mutate(id = row_number())

postElection <- twitterData %>%                                                  # creating dataset for post-election tweets
  filter(Date >= "2017-01-20 09:00:00") %>%
  mutate(id = row_number())

# aggression level in response to other tweets?

###### generating wordclouds

library(tm)           # text mining
library(wordcloud)    # word-cloud generator

# generating wordcloud for tweets before official candidacy announcement

tweetsBefore <- Corpus(VectorSource(beforeRunning$text))
tweetsBefore <- tm_map(tweetsBefore, removePunctuation)
tweetsBefore <- tm_map(tweetsBefore, removeWords, stopwords('english'))
tweetsBefore <- tm_map(tweetsBefore, removeWords, c("the"))
dtm <- TermDocumentMatrix(tweetsBefore)
m <- as.matrix(dtm)
v <- sort(rowSums(m),decreasing=TRUE)
d <- data.frame(word = names(v),freq=v)

wordcloud(words = d$word, freq = d$freq, max.words=100, random.order = FALSE, colors=brewer.pal(8, "Dark2"))

# generating wordcloud for time while he was running

tweetsDuring <- Corpus(VectorSource(whileRunning$text))
tweetsDuring <- tm_map(tweetsDuring, removePunctuation)
tweetsDuring <- tm_map(tweetsDuring, removeWords, stopwords('english'))
tweetsDuring <- tm_map(tweetsDuring, removeWords, c("the"))
dtm <- TermDocumentMatrix(tweetsDuring)
m <- as.matrix(dtm)
v <- sort(rowSums(m),decreasing=TRUE)
d <- data.frame(word = names(v),freq=v)

wordcloud(words = d$word, freq = d$freq, max.words=100, random.order = FALSE, colors=brewer.pal(8, "Dark2"))

# generating wordcloud for time after he was elected 

tweetsAfter <- Corpus(VectorSource(postElection$text))
tweetsAfter <- tm_map(tweetsAfter, removePunctuation)
tweetsAfter <- tm_map(tweetsAfter, removeWords, stopwords('english'))
tweetsAfter <- tm_map(tweetsAfter, removeWords, c("the"))
dtm <- TermDocumentMatrix(tweetsAfter)
m <- as.matrix(dtm)
v <- sort(rowSums(m),decreasing=TRUE)
d <- data.frame(word = names(v),freq=v)

wordcloud(words = d$word, freq = d$freq, max.words=100, random.order = FALSE, colors=brewer.pal(8, "Dark2"))

