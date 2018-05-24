#install.packages("syuzhet")
library(syuzhet)
library(graphics)
library(purrr)
library(stringr)
library(ggplot2)
library(tm)
library(wordcloud)
library(plotly)
library(wordcloud)

# load tweets csv into R
tweets <- read.csv(file = 'tweets.csv', header = TRUE, sep = ,)
str(tweets)

# build tweets corpus
corpus <- iconv(tweets$text)
corpus <- Corpus(VectorSource(corpus))
inspect(corpus[1:5])

# clean text
clean_corpus <- tm_map(corpus, removePunctuation)
clean_corpus <- tm_map(clean_corpus, tolower)
clean_corpus <- tm_map(clean_corpus, removeNumbers)
clean_corpus <- tm_map(clean_corpus, removeWords, stopwords("english"))
clean_corpus <- tm_map(clean_corpus, removeWords, c("beastfromtheast","beastfromtheeast","beast from the east","BeastFromTheEast","stormemma"))

removeURL <- function(x) gsub("http[[:alnum:]]", "", x)
clean_corpus <- tm_map(clean_corpus,content_transformer(removeURL))
removeNonAscii <- function(x) textclean::replace_non_ascii(x)
clean_corpus <- tm_map(clean_corpus, content_transformer(removeNonAscii))                   
removePic <- function(x) gsub("pictwitter[[:alnum:]]", "", x)  
clean_corpus <- tm_map(clean_corpus, content_transformer(removePic)) 

clean_corpus <- tm_map(clean_corpus, stripWhitespace)
inspect(clean_corpus[1:10])

# apply nrc sentiment analysis function
emotions_data <- get_nrc_sentiment(clean_corpus$content)

# create bar plot
barplot(
  sort(colSums(prop.table(emotions_data))), 
  horiz = TRUE, 
  cex.names = .7, 
  las = 1, 
  main = "Sentiment Scores for tweets", xlab="Percentage"
)

# create wordcloud
wordcloud(clean_corpus, random.order = FALSE, max.words = 80, colors = brewer.pal(8, 'Dark2'))
