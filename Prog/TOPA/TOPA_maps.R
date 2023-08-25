######
# Program: TOPA study Maps
# Library: PresCat
# Project: DC TOPA
# Author: Elizabeth Burton 
# Created: 8/25/23

# Description: Create maps for DC TOPA study
######

library(tidyverse)
library(sf)
library(urbnmapr)
library(ggplot2)
library(urbnthemes)
library(crsuggest) #suggests CRS
library(tigris)

set_urbn_defaults(style = "map")

#Read in DC TOPA data 
TOPA_data <- read_csv("//sas1/dcdata/Libraries/PresCat/Raw/TOPA/TOPA_table_data.csv") %>%
  st_as_sf(
    coords = c("x", "y"),
    crs=26985) %>%
  filter(u_dedup_notice=="Yes" & u_notice_with_sale=="Yes")

#Read in ward boundaries
geoward22 <- st_read(
  dsn = "//sas1/dcdata/Libraries/PresCat/Raw/TOPA/shapefiles/Wards_from_2022/Wards_from_2022.shp",
  quiet = TRUE
)
#Transform to Maryland plane
geoward22 <- geoward22 %>% st_transform("EPSG:26985")

# 1) Co-op Map
TOPA_coop <- TOPA_data %>%
  filter(d_le_coop=="Yes") %>%
  rename("Total number of housing units"=u_final_units)

coop_map <- ggplot() +
  geom_sf(data = geoward22, 
          fill = palette_urbn_gray[5]) +
  geom_sf(data = TOPA_coop, 
          mapping = aes(size=`Total number of housing units`), 
          color = palette_urbn_main["cyan"],
          alpha = 0.6) +
  geom_sf_text(data = geoward22, aes(label=WARD), color = alpha(palette_urbn_gray[7.5]), nudge_x = 2, size = 4) +
  scale_size_continuous(name="Total number of housing units", breaks = c(20, 40, 60, 80)) +
  scale_alpha_continuous(name="Total number of housing units", breaks = c(20, 40, 60, 80)) 
  
# 2) Affordable map
TOPA_affordable <- TOPA_data %>%
  filter(d_affordable=="Yes") %>%
  arrange(u_final_units)

affordable_map <- ggplot() +
  geom_sf(data = geoward22, 
          fill = palette_urbn_gray[5]) +
  geom_sf(data = TOPA_affordable, 
          mapping = aes(size=u_final_units), 
          color = palette_urbn_main["cyan"],
          alpha = 0.4) +
  geom_sf_text(data = geoward22, aes(label=WARD), color = alpha(palette_urbn_gray[7.5]), nudge_x = 2, size = 4) +
  scale_size_continuous(name="Total number of housing units", breaks = c(25, 50, 100, 200, 500)) +
  scale_alpha_continuous(name="Total number of housing units", breaks = c(25, 50, 100, 200, 500)) 

# 3) Tenants assigned rights/co-op
TOPA_exercise <- TOPA_data %>%
  filter(d_ta_assign_rights=="Yes" | d_le_coop=="Yes")

exercise_map <- ggplot() +
  geom_sf(data = geoward22, 
          fill = palette_urbn_gray[5]) +
  geom_sf(data = TOPA_exercise, 
          mapping = aes(size=u_final_units), 
          color = palette_urbn_main["cyan"],
          alpha = 0.4)+
  geom_sf_text(data = geoward22, aes(label=WARD), color = alpha(palette_urbn_gray[7.5]), nudge_x = 2, size = 4) +
  scale_size_continuous(name="Total number of housing units", breaks = c(25, 50, 100, 200, 500)) +
  scale_alpha_continuous(name="Total number of housing units", breaks = c(25, 50, 100, 200, 500)) 
