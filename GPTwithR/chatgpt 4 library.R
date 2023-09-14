library(httr)


############################################################################
# Ask ChatGPT to answer questions about text
############################################################################
#   models evolving fast https://platform.openai.com/docs/models/overview
#   requires an OpenAI account https://platform.openai.com/login
#   also requires billing information



# Define the API endpoint and key
GPTurl <- "https://api.openai.com/v1/chat/completions"
key        <- "sk-"


# Define the text to send to the model
gptQuery <- "If I had peanut butter, jelly, and bread, what kind of meal can I make?"
response <- POST(GPTurl,
                 add_headers(Authorization = paste0("Bearer ", key)),
                 body = list(model = "gpt-3.5-turbo",
                             max_tokens = 1000, 
                             temperature = 0.7, # default 0.7,
                             messages = list(list(role="user",
                                                  content=gptQuery))),
                 encode = "json")
# extract response
content(response)$choices[[1]]$message$content





gptQuery <- 'What kind of guns were involved in this incident? "On Friday, 3/20/15, at approximately 1:03 A.M., uniformed officers, in an unmarked police vehicle were flagged down by an unknown female at 22nd Street and Allegheny Avenue. The unknown female told the officers that there was male in the area of 22nd and Toronto Streets with a large gun. The officers proceeded to the area and observed the a male at 22nd and Toronto Streets armed with a shotgun. The officers exited their vehicle and ordered the male not to move. The male raised the shotgun toward the officers who then drew their weapons. The offender fled west in the 2200 block of Toronto Street, turning and pointing the shotgun at the officers as he ran. In response, one of the officers discharged his weapon, missing the offender. The offender dropped the shotgun and fled into a bar in the 3000 block of N. 22nd Street. Once inside the bar, he removed and discarded his hooded sweatshirt, and then exited the bar. The offender was apprehended at 23rd and Clearfield Streets.  The 12-gauge shotgun that the offender discarded was recovered at the scene.  There were no injuries as a result of this incident.   *** Information posted in the original summary reflects a preliminary understanding of what occurred at the time of the incident. This information is posted shortly after the incident and may be updated as the investigation leads to new information. The DA’s Office is provided all the information from the PPD’s investigation prior to their charging decision."'

response <- POST(GPTurl,
                 add_headers(Authorization = paste0("Bearer ", key)),
                 body = list(model = "gpt-3.5-turbo",
                             max_tokens = 1000, 
                             temperature = 0.7, # default 0.7,
                             messages = list(list(role="user",
                                                  content=gptQuery))),
                 encode = "json")
# extract response
content(response)$choices[[1]]$message$content




a <- scan(file="c:/Users/greg_/Downloads/Officer Involved Shootings _ Philadelphia Police Department.html",
          what="",sep="\n")


i <- grep("o\\.title", a)
head(a[i])
# pack it all into a data frame
ois <- data.frame(id=gsub("<[^>]*>","",a[i]),
                  year    =gsub("<[^>]*>","",a[i+3]),
                  url     =gsub('.* href="([^"]*)".*',"\\1",a[i]))
ois <- subset(ois, year>=2022)

ois$text <- NA
for(i in 1:nrow(ois))
{
  a <- scan(ois$url[i], what="", sep="\n")
  iStart <- grep("entry-content clearfix", a) + 1
  iEnd   <- grep("\\.entry-content", a)       - 1
  
  if(length(iEnd)>0 && length(iStart)>0 && (iEnd-iStart > 1))
  {
    ois$text[i] <- paste(a[iStart:iEnd], collapse="\n")
  } else
  {
    cat("No text for ",ois$id[i],"\n")
  }
}

# a little cleanup
# remove any HTML tags
ois$text <- gsub("<[^>]*>", "", ois$text)
# remove leading/trailing spaces, tabs, newlines
ois$text <- gsub("^[[:space:]]*|[[:space:]]*$", "", ois$text)
# remove special HTML characters... mostly &nbsp;
ois$text <- gsub("&[^;]+;", " ", ois$text)



# Define the text to send to the model
gptQuery <- paste("Did the police transport the person they shot to the hospital in this incident? Just answer yes, no, or unknown:",
                  ois$text[1])
response <- POST(GPTurl,
                 add_headers(Authorization = paste0("Bearer ", key)),
                 body = list(model = "gpt-3.5-turbo",
                             max_tokens = 1,  # force yes/no
                             temperature = 0, # force best answer/no "creativity"
                             # default 0.7,
                             messages = list(list(role="user",
                                                  content=gptQuery))),
                 encode = "json")
# extract response
content(response)$choices[[1]]$message$content



ois$transport <- NA
for(i in 1:nrow(ois))
{
  gptQuery <- paste("Did the police transport the person they shot to the hospital in this incident? Just answer yes, no, or unknown. If the report does not mention them transporting the person they shot to the hospital, then you can conclude no.",
                    ois$text[i])
  response <- POST(GPTurl,
                   add_headers(Authorization = paste0("Bearer ", key)),
                   body = list(model = "gpt-3.5-turbo",
                               max_tokens = 1,
                               temperature = 0,
                               messages = list(list(role="user",
                                                    content=gptQuery))),
                   encode = "json")
  ois$transport[i] <- content(response)$choices[[1]]$message$content
  print(ois[i,c("id","transport")])
}


table(tolower(ois$transport))
with(subset(ois, tolower(transport)=="no"), text)
with(subset(ois, tolower(transport)=="unknown"), text[1:3])




ois$transportDetail <- NA
for(i in 1:nrow(ois))
{
  gptQuery <- paste("Did the police transport the person they shot to the hospital in this incident?:",
                    ois$text[i])
  response <- POST(GPTurl,
                   add_headers(Authorization = paste0("Bearer ", key)),
                   body = list(model = "gpt-3.5-turbo",
                               max_tokens = 100,
                               temperature = 0,
                               messages = list(list(role="user",
                                                    content=gptQuery))),
                   encode = "json")
  ois$transportDetail[i] <- content(response)$choices[[1]]$message$content
  print(ois[i,c("id","transportDetail")])
}




