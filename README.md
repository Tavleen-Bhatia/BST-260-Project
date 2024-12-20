# BST-260-Project

Steps on reproducing results:

1) Use `raw-data/NST-EST2023-ALLDATA.csv` file from https://www.census.gov/data/tables/time-series/demo/popest/2020s-state-total.html to get 2020-2023 population data
2) Wrangle file using `get_pop.R` file, which uses the average population from 2020-2023 to get census data for 2024 for each state
3) Make data frame to get information about population and COVID19 cases/deaths/hospitalization/vaccines from 2020-2023 together by running `make_df.R` file, this calls in `functions.R` to read in json files and calls in COVID-19 information from the CDC (https://data.cdc.gov/resource/pwn4-m3yp.json, https://data.cdc.gov/resource/39z2-9zu6.json, https://data.cdc.gov/resource/r8kw-7aab.json, https://data.cdc.gov/resource/rh2h-3yt2.json)
4) Use `raw-data/nst-est_preCovid.csv` file from https://www.census.gov/programs-surveys/popest/technical-documentation/research/evaluation-estimates/2020-evaluation-estimates/2010s-totals-national.html to get population data from 2010-2020
5) Wrangle file and get data frame of population and total deaths together before COVID-19 (2014-2019) using the `make_df_preCovid.R` file, this calls in total deaths information from the CDC (https://data.cdc.gov/NCHS/Weekly-Counts-of-Deaths-by-State-and-Select-Causes/3yf8-kanr/about_data)
6) Use `findingWaves_Q1.qmd` to get possible COVID19 waves of interest (i.e., cases and deaths both rising and falling very close together)
7) Use `deathRates_Q2.qmd` to analyze and use `Death_Rates_Q2.qmd` to zoom in on states/periods of interest
8) Use `virulence_Q3.qmd` to analyze the COVID-19 case rates for each state
9) Use `Excess_Mortality_Q4.qmd` to calculate excess deaths to see if increases in total deaths are caused by COVID-19 or not
10) Use `Excess_Mortality_Rates_Q5.qmd` to analyze excess deaths for each state


