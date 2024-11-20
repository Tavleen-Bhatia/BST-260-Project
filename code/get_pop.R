### CODE FOR WRANGLING POPULATION DATAFRAME ###

### CONTAINS CODE FOR POPULATION OF EACH STATE FROM 2018-2024

library(httr2)
library(tidyverse)
library(janitor)
library(jsonlite)
library(purrr)
library(lubridate)
library(tibble)

# reading in csv
population <- read.csv('../data/NST-EST2023-ALLDATA.csv')


# data wrangling population dataframe
population <- population |>
  filter(STATE != 0) |>
  select(c(NAME, POPESTIMATE2020, 
           POPESTIMATE2021, POPESTIMATE2022, POPESTIMATE2023)) |>
  rename(state_name = NAME,
         `2020` = POPESTIMATE2020,
         `2021` = POPESTIMATE2021,
         `2022` = POPESTIMATE2022,
         `2023` = POPESTIMATE2023)


# creates graph to show if population for each state changes drastically overtime,
# since we see that pop barely changes for each state, can extrapolate
## that 2024 will just be average of pop from 2020-2023
# population |> 
#   pivot_longer(-(state_name),
#                names_to = 'year',
#                values_to = 'population') |>
#   mutate(year = parse_number(year)) |>
#   ggplot(aes(x = year, y = population, color = state_name)) +
#   geom_line()




# saves avg pop for each state
averages <- population |> 
  pivot_longer(-(state_name),
               names_to = 'year',
               values_to = 'population') |>
  group_by(state_name) |>
  summarize(`2024` = mean(population)) |>
  ungroup()



# adds averages to population df and state abbreviations
population <- population |>
  left_join(averages, by = 'state_name') |>
  pivot_longer(-(state_name),
               names_to = 'year',
               values_to = 'population') |>
  mutate(year = parse_number(year),
         state = case_when(state_name == 'Puerto Rico' ~ 'PR',
                           state_name == 'District of Columbia' ~ 'DC',
                           TRUE ~ state.abb[match(state_name, state.name)]))





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

# when doing source() on this file, focus on calling the population dataframe



