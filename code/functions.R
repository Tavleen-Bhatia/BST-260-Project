### collecting data ###

# downloading libraries
library(httr2)
library(tidyverse)
library(janitor)
library(jsonlite)
library(purrr)


# making function to get data from websites
# use url to make matrices
get_cdc_data <- function(url) {
  df <- request(url) |> # requesting data through url
    req_url_query("$limit" = 10000000) |> # setting limit
    req_perform() |> # getting data
    resp_body_json(simplifyVector = TRUE) # converting json to matrix
  
  return(df) # returning data as matrix
  
}







