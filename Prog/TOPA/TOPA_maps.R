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

# 1) Co-op Map - Table 28b
TOPA_coop <- TOPA_data %>%
  filter(d_le_coop=="Yes") %>%
  arrange(u_final_units) 

ggplot() +
  geom_sf(data = geoward22, 
          fill = palette_urbn_gray[5]) +
  geom_sf(data = TOPA_coop, 
          mapping = aes(size=u_final_units), 
          color = palette_urbn_main["cyan"],
          alpha = 0.4) +
  geom_sf_text(data = geoward22, aes(label=WARD), color = alpha(palette_urbn_gray[7.5]), nudge_x = 2, size = 4) +
  scale_size_continuous(name="Number of units in project", breaks = c(20, 40, 60, 80)) +
  scale_alpha_continuous(name="Number of units in project", breaks = c(20, 40, 60, 80)) 

ggsave("TOPA_coop_map.png", type = "cairo", dpi = 400)

# 2) Affordable map - Table 13b
TOPA_affordable <- TOPA_data %>%
  filter(d_affordable=="Yes") %>%
  arrange(u_affordable_units) 

ggplot() +
  geom_sf(data = geoward22, 
          fill = palette_urbn_gray[5]) +
  geom_sf(data = TOPA_affordable, 
          mapping = aes(size=u_affordable_units), 
          color = palette_urbn_main["cyan"],
          alpha = 0.4) +
  geom_sf_text(data = geoward22, aes(label=WARD), color = alpha(palette_urbn_gray[7.5]), nudge_x = 2, size = 4) +
  scale_size_continuous(name="Number of affordable units in project", breaks = c(25, 50, 100, 200, 500)) +
  scale_alpha_continuous(name="Number of affordable units in project", breaks = c(25, 50, 100, 200, 500)) 

ggsave("TOPA_affordable_map.png", type = "cairo", dpi = 400)

# 3) Tenants assigned rights/co-op - Table 29b
TOPA_exercise <- TOPA_data %>%
  filter(d_ta_assign_rights=="Yes" | d_le_coop=="Yes") %>%
  arrange(u_final_units)

ggplot() +
  geom_sf(data = geoward22, 
          fill = palette_urbn_gray[5]) +
  geom_sf(data = TOPA_exercise, 
          mapping = aes(size=u_final_units), 
          color = palette_urbn_main["cyan"],
          alpha = 0.4)+
  geom_sf_text(data = geoward22, aes(label=WARD), color = alpha(palette_urbn_gray[7.5]), nudge_x = 2, size = 4) +
  scale_size_continuous(name="Number of units in project", breaks = c(25, 50, 100, 200, 500)) +
  scale_alpha_continuous(name="Number of units in project", breaks = c(25, 50, 100, 200, 500)) 

ggsave("TOPA_exercise_map.png", type = "cairo", dpi = 400)

# 4) Tenants Assigned Rights and Affordability - Table 26b 
TOPA_exercise_affordable <- TOPA_data %>%
  filter((d_ta_assign_rights=="Yes" & d_affordable=="Yes") | d_le_coop=="Yes") %>%
  arrange(u_affordable_units)

ggplot() +
  geom_sf(data = geoward22, 
          fill = palette_urbn_gray[5]) +
  geom_sf(data = TOPA_exercise_affordable, 
          mapping = aes(size=u_affordable_units), 
          color = palette_urbn_main["cyan"],
          alpha = 0.4)+
  geom_sf_text(data = geoward22, aes(label=WARD), color = alpha(palette_urbn_gray[7.5]), nudge_x = 2, size = 4) +
  scale_size_continuous(name="Number of affordable units in project", breaks = c(25, 50, 100, 200, 500)) +
  scale_alpha_continuous(name="Number of affordable units in project", breaks = c(25, 50, 100, 200, 500)) 

ggsave("TOPA_exercise_affordable.png", type = "cairo", dpi = 400)

