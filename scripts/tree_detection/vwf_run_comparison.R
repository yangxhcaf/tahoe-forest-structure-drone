## Takes a CHM and makes a map of treetops

library(sf)
library(raster)
library(ForestTools)
library(here)
library(purrr)
library(furrr)
library(tidyverse)

#### Get data dir ####
# The root of the data directory
data_dir = readLines(here("data_dir.txt"), n=1)

#### Convenience functions and main functions ####

source(here("scripts/convenience_functions.R"))
source(here("scripts/tree_detection/vwf_functions.R"))




### Define parameter values to search: only need to run if set defs change

params = read_csv(data("parameter_set_definitions/best_vwf_acrossSmooths012.csv"))
params$detection_params_name = paste0("vwf_",str_pad(1:nrow(params)+9000, width=4, pad = "0"))
params$method = "vwf"



# Run for multiple CHMs

# If running manually, specify paramset names
manual_paramset_names = NULL
# manual_paramset_names = c("paramset14_01","paramset14_02","paramset14_03")

# read paramset from command line argument (otherwise use the hard-coded default above)
command_args = commandArgs(trailingOnly=TRUE)

if(length(command_args) == 0) {
  if(!is.null(manual_paramset_names)) {
    paramset_names = manual_paramset_names
  } else { # pull from directory
    
    chm_files = list.files(data("metashape_products/chm"),pattern="chm\\.tif", full.names=TRUE)
    
    # get all the filenames from before the date
    pieces = str_split(chm_files,"/")
    filenames = map(pieces,sapply(pieces,length)[1]) %>% unlist
    pre_dates_part1 = filenames %>% str_split("_") %>% map(1) %>% unlist
    pre_dates_part2 = filenames %>% str_split("_") %>% map(2) %>% unlist
    pre_dates = paste(pre_dates_part1,pre_dates_part2,sep="_")
    
    
    paramset_names = unique(pre_dates)
    
  }
  
} else if (length(command_args) > 0) {
  paramset_names = command_args[1]
}

# Ramdomize paramset names so can run multiple parallel
paramset_names = paramset_names %>% sample()

### Run the search
options(future.globals.maxSize=5000*1024^2) # 5 GB
plan(multiprocess)
walk(paramset_names,.f = vwf_singlechm_multiparamset, parallelize_params = TRUE, params = params)


