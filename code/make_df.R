
source('get_pop.R')
source('functions.R')


cases_raw <- get_cdc_data('https://data.cdc.gov/resource/pwn4-m3yp.json')
hosp_raw <- get_cdc_data('https://data.cdc.gov/resource/39z2-9zu6.json')
deaths_raw <- get_cdc_data('https://data.cdc.gov/resource/r8kw-7aab.json')
vax_raw <- get_cdc_data('https://data.cdc.gov/resource/rh2h-3yt2.json')


### wrangling cases ###
cases <- cases_raw |> 
  mutate(cases = parse_number(new_cases),
         date = as_date(ymd_hms(end_date))) |> # convert str cols to numeric/date types
  filter(state %in% population$state) |> # filter based on state abbreviations
  mutate(mmwr_week = epiweek(date), 
         mmwr_year = epiyear(date)) |> # adds epiyear/epiweek for unique identification of date
  select(state, mmwr_year, mmwr_week, cases) |> # select specific columns (state, mmwr_year, mmwr_week, cases)
  arrange(state, 
          mmwr_year, 
          mmwr_week) # arranges states by ascending order based on epiweek/epiyear

######  


### wrangling hospitalizations ###
hosp <- hosp_raw |>
  filter(jurisdiction %in% population$state) |> # filter based on state abbreviations
  rename(state = jurisdiction,
         hosp = new_covid_19_hospital) |> # renames columns to state and hops for left_join later
  mutate(hosp = parse_number(hosp),
         date = as_date(ymd_hms(collection_date))) |> # convert str cols to numeric/date types
  mutate(mmwr_week = epiweek(date), 
         mmwr_year = epiyear(date)) |> # adds epiyear/epiweek for unique identification of date
  select(state, mmwr_year, mmwr_week, hosp) |> # selects specific cols (state, mmwr_year, mmwr_week, hosp)
  group_by(state, mmwr_year, mmwr_week) |> # do next calcs after grouping by state, mmwr_year, mmwr_week
  summarize(hosp = sum(hosp), n = n(), .groups = 'drop') |> # collapses daily data by week and counts number of observations per week
  filter(n == 7)  |> # looking at to see if we have reports each day of week
  select(-n) |> # remove counts
  arrange(state, mmwr_year, mmwr_week) # arranges states by ascending order based on epiweek/epiyear

######


### wrangling deaths ###
deaths <- deaths_raw |> 
  mutate(covid_deaths = parse_number(covid_19_deaths), 
         total_deaths = parse_number(total_deaths),
         date = as_date(ymd_hms(end_date)), # convert str cols to numeric/date type
         mmwr_year = epiyear(date),
         mmwr_week = parse_number(mmwr_week)) |> # adds epiyear/epiweek for unique identification of date
  filter(state %in% population$state_name) |> # filter based on state names 
  select(state, mmwr_year, mmwr_week, covid_deaths, total_deaths) |> # selects specific cols (state, mmwr_year, mmwr_week, covid_deaths, total_deaths)
  mutate(state = case_when(state == 'Puerto Rico' ~ 'PR',
                           state == 'District of Columbia' ~ 'DC',
                           TRUE ~ state.abb[match(state, state.name)])) |> # changes names to abbreviations
  arrange(state, mmwr_year, mmwr_week) # arranges states by ascending order based on epiweek/epiyear

######


### wrangling vaccinations ###
vax <- vax_raw |>
  mutate(across(c(series_complete_cumulative,
                  booster_cumulative), parse_number), 
         date = as_date(ymd_hms(date))) |> # convert str cols to numeric/date type
  filter(date_type == 'Admin', 
         location %in% population$state) |> # filter by Admin dates and by state abb
  mutate(mmwr_week = parse_number(mmwr_week), 
         mmwr_year = epiyear(date)) |> # adds epiyear/epiweek for unique identification of date
  select(location, mmwr_year, mmwr_week, 
         series_complete_cumulative, booster_cumulative) |> # selects specific cols (location, mmwr_year, mmwr_week, series_complete_cumulative, booster_cumulative) 
  rename(state = location) |> # renames location col to state
  group_by(state, mmwr_year, mmwr_week) |> # do next calcs after grouping by state, mmwr_year, mmwr_week 
  summarize(series_complete = max(series_complete_cumulative),
            booster = max(booster_cumulative))  # finds total vax/booster at the end of week

######  





# code from Professor
all_dates <- data.frame(date = seq(make_date(2020, 1, 25),
                                   make_date(2024, 12, 31), 
                                   by = "week")) |>
  mutate(date = ceiling_date(date, unit = "week", week_start = 7) - days(1)) |>
  mutate(mmwr_year = epiyear(date), mmwr_week = epiweek(date)) 

dates_and_pop <- cross_join(all_dates, 
                            data.frame(state = unique(population$state))) |> 
  left_join(population, by = c("state", "mmwr_year" = "year"))



# joining cases, hosp, deaths, and vax dfs to dates_and_pop
# to get one big df (i.e., dat)
# joining by state, epiweek, and epiyear cols
dat <- dates_and_pop |>
  left_join(cases, by = c('state', 'mmwr_year', 'mmwr_week')) |>
  left_join(hosp, by = c('state', 'mmwr_year', 'mmwr_week')) |> 
  left_join(deaths, by = c('state', 'mmwr_year', 'mmwr_week')) |> 
  left_join(vax, by = c('state', 'mmwr_year', 'mmwr_week')) |>
  arrange(state, date)




# saving df as RDS file to data folder
saveRDS(dat, file = '../data/dat.rds')

