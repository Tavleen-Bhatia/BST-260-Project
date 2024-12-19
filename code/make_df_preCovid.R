# wrangling population and total deaths from 2014-2019 (pre COVID-19)

library(httr2)
library(tidyverse)
library(janitor)
library(jsonlite)
library(purrr)
library(lubridate)
library(tibble)


source('functions.R')
population_preCovid <- read.csv('../raw-data/nst-est_preCovid.csv')

deaths_preCovid_raw <- get_cdc_data('https://data.cdc.gov/resource/3yf8-kanr.json')

deaths_preCovid <- deaths_preCovid_raw |>
  rename(state_name = jurisdiction_of_occurrence,
         mmwr_year = mmwryear,
         mmwr_week = mmwrweek,
         total_deaths = allcause,
         date = weekendingdate) |>
  mutate(date = as.Date(ymd_hms(date)),
         mmwr_year = parse_number(mmwr_year),
         mmwr_week = parse_number(mmwr_week)) |> 
  filter(!(state_name %in% c('United States', 'New York City'))) |>
  select(date, state_name, mmwr_year, mmwr_week, total_deaths)



population_preCovid <- population_preCovid |>
  rename(`2010` = X2010,
         `2011` = X2011,
         `2012` = X2012,
         `2013` = X2013,
         `2014` = X2014,
         `2015` = X2015,
         `2016` = X2016,
         `2017` = X2017,
         `2018` = X2018,
         `2019` = X2019) |>
  pivot_longer(-(state_name),
               names_to = 'year',
               values_to = 'population') |>
  mutate(year = parse_number(year),
         state = case_when(state_name == 'Puerto Rico' ~ 'PR',
                           state_name == 'District of Columbia' ~ 'DC',
                           TRUE ~ state.abb[match(state_name, state.name)])) |>
  filter(year %in% c(2014, 2015, 2016, 2017, 2018, 2019))



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
population_preCovid <- left_join(population_preCovid, regions, by = 'state_name')



all_dates <- data.frame(date = seq(make_date(2014, 10, 25),
                                   make_date(2019, 12, 28), 
                                   by = "week")) |>
  mutate(date = ceiling_date(date, unit = "week", week_start = 7) - days(1)) |>
  mutate(mmwr_year = epiyear(date), mmwr_week = epiweek(date)) 

dates_and_pop <- cross_join(all_dates, 
                            data.frame(state = unique(population_preCovid$state))) |> 
  left_join(population_preCovid, by = c("state", "mmwr_year" = "year"))


dat_preCovid <- dates_and_pop |>
  left_join(deaths_preCovid, by = c('date', 'state_name', 'mmwr_year', 'mmwr_week')) |>
  arrange(state, date)



# saves data pre 2020
saveRDS(dat_preCovid, file = '../data/dat_preCovid.rds')





