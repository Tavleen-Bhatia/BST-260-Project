### CODE FOR WRANGLING POPULATION DATAFRAME ###

### CONTAINS CODE FOR POPULATION OF EACH STATE FROM 2018-2024

library(httr2)
library(tidyverse)
library(janitor)
library(jsonlite)
library(purrr)
library(lubridate)
library(tibble)

source('../data/census-key.R')



# grabs census data for years that are not 2020-2021
# currently grabbing only 2018, 2019
get_pop <- function(given_year) {
  url <- paste0('https://api.census.gov/data/', given_year, '/pep/population')
  
  if (given_year == 2018) {
    request <- request(url) |> req_url_query(get = I("POP,GEONAME"),
                                             `for` = I('state:*'),
                                             key = census_key)
  }
  
  if (given_year == 2019) {
    request <- request(url) |> req_url_query(get = I("POP,NAME"),
                                             `for` = I('state:*'),
                                             key = census_key)
  }
  
  # using req_perform to get request object
  response <- request |> req_perform()
  
  
  # extracting json file into matrix
  population <- response |> resp_body_json(simplifyVector = TRUE)
  
  if (given_year == 2018) {
    # cleaning up dataframe
    population <- population |> 
      row_to_names(1) |> 
      as_tibble() |> 
      select(-state) |>  
      rename(state_name = GEONAME) |>
      pivot_longer(-(state_name),
                   names_to = 'year',
                   values_to = 'population') |>
      mutate(year = given_year,
             population = as.numeric(population),
             state = case_when(state_name == 'Puerto Rico' ~ 'PR',
                               state_name == 'District of Columbia' ~ 'DC',
                               TRUE ~ state.abb[match(state_name, state.name)]))
  }
  
  if (given_year == 2019) {
    # cleaning up dataframe
    population <- population |> 
      row_to_names(1) |> 
      as_tibble() |> 
      select(-state) |>  
      rename(state_name = NAME) |>
      pivot_longer(-(state_name),
                   names_to = 'year',
                   values_to = 'population') |>
      mutate(year = given_year,
             population = as.numeric(population),
             state = case_when(state_name == 'Puerto Rico' ~ 'PR',
                               state_name == 'District of Columbia' ~ 'DC',
                               TRUE ~ state.abb[match(state_name, state.name)]))
  }
  
  return(population)
}


# stores census data for 2018 and 2019
pop_2018 <- get_pop(2018)
pop_2019 <- get_pop(2019)




# grabs census data for 2020, 2021
# 2020 and 2021 are together, only call once
url <- "https://api.census.gov/data/2021/pep/population"


# uses req_url_query to get database using url
# `for` makes "for" a variable instead of a function
# the I() makes string be read in as a literal string 
request <- request(url) |> req_url_query(get = I("POP_2020,POP_2021,NAME"),
                                         `for` = I('state:*'),
                                         key = census_key)


# using req_perform to get request object
response <- request |> req_perform()


# extracting json file into matrix
pop_2020_2021 <- response |> resp_body_json(simplifyVector = TRUE)

# cleaning up dataframe for 2020 and 2021 census data
pop_2020_2021 <- pop_2020_2021 |> 
  row_to_names(1) |> 
  as_tibble() |> 
  select(-state) |>  
  rename(state_name = NAME) |>
  pivot_longer(-(state_name),
               names_to = 'year',
               values_to = 'population') |> 
  mutate(year = str_remove(year, "POP_")) |> 
  mutate(year = as.numeric(year),
         population = as.numeric(population),
         state = case_when(state_name == 'Puerto Rico' ~ 'PR',
                           state_name == 'District of Columbia' ~ 'DC',
                           TRUE ~ state.abb[match(state_name, state.name)])) 


# adding dataframes together
population <- rbind(pop_2018, pop_2019, pop_2020_2021) |>
  arrange(state_name, year)


# graph to justify that using average to extrapolate pop 2022-2024 data is okay
# population |>
#   ggplot(aes(x = year, y = population, color = state_name)) +
#   geom_line()


# saves average pop for each state
averages <- population |>
  group_by(state_name) |>
  summarize(avg = mean(population))


# adding average pop for 2022-2024 to dataframe
population <- population |>
  pivot_wider(names_from = year,
              values_from = population) |>
  left_join(averages, by = 'state_name') |>
  rename(`2022` = avg) |>
  mutate(`2023` = `2022`,
         `2024` = `2022`) |>
  pivot_longer(-c(state_name, state),
               names_to = 'year',
               values_to = 'population') |>
  mutate(year = parse_number(year))



# creating dataframe to see which state is in which region
url <- "https://github.com/datasciencelabs/2024/raw/refs/heads/main/data/regions.json"
regions <- fromJSON(url, simplifyDataFrame = FALSE) # use jsonlit JSON parser 

### CREATING REGIONS DATAFRAME BELOW ###

# convert list to data frame. You can use map_df in purrr package
regions <- map_df(regions, function(x) 
  data.frame(region = x$region,
             region_name = x$region_name,
             state_name = x$states)) |>
  mutate(region_name = str_replace(region_name, 
                                   'New York and New Jersey, Puerto Rico, Virgin Islands', 
                                   'NY NJ PR VI'))
######


### JOINING TOGETHER POPULATION AND REGIONS DATAFRAMES ###

# use left_join to merge tables together by state_name
# population df is the base (i.e., left df kept)
# using regions df to merge onto base df 
# (i.e., info from right df brought to left df)
population <- left_join(population, regions, by = 'state_name')


# when doing source(), load in population object


