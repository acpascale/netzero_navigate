##   NZAu_GenericDownscaleEER_costs_by_type.r  - costs by year and scenario for all EER technologies
##
##   Created:        7 February 2020 (for NZA)
##   Last updated:   13 July 2024 (for BD paper Cap check)
##
##   ToDo:
##        1.

#-----0.ADMIN - Include libraries and other important-----------

##--A. Clean
setwd("X:/WORK/NZAu_LandUsePaper_MAIN/dev/")
source("d0_2code/clean.R")

##--B.Load Library for country manipulations
suppressMessages ( library ( "openxlsx"     , lib.loc=.libPaths() ) )      # worksheet functions
suppressMessages ( library ( "reshape2"     , lib.loc=.libPaths() ) )      # melt, dcast

#set EER output type
type  <- "spend"

fromT <- c ( "electricity" , "solar" , "onshore wind" , "offshore wind"  )
fromE <- c ( "rooftop solar" , "existing_large-scale solar pv" , "existing_onshore wind|1" , "existing_rooftop solar" , "electricity" )

#-----END 0.ADMIN---------------



#-----1.HACK--------------------

##--A1. EER spend file
EER         <- read.csv ( paste ( "d0_1source/" , type , "_y.csv" , sep = "" ) , header=TRUE , stringsAsFactors = FALSE )

##eplus
TE          <- subset ( EER , EER$run.name == "eplus" & EER$from..outputs_group_aggregate %in% fromT & !(EER$from %in% fromE ) )

#unique ( TE$from..outputs_group_detailed )
#unique ( TE$from..outputs_group_aggregate )
#unique ( TE$year )

TEM  <- dcast ( TE , run.name + unit + from..outputs_group_detailed + from ~ cost_type , value.var = "value" , fun = sum )

sum ( TEM$capital )

##eplus distributed export
TE          <- subset ( EER , EER$run.name == "eplus-distributedexport" & EER$from..outputs_group_aggregate %in% fromT & !(EER$from %in% fromE ) )

#unique ( TE$from..outputs_group_detailed )
#unique ( TE$from..outputs_group_aggregate )
#unique ( TE$year )

TEMP  <- dcast ( TE , run.name + unit + from..outputs_group_detailed + from ~ cost_type , value.var = "value" , fun = sum )

wb            <- createWorkbook ( creator = "AP" )
addWorksheet  ( wb, sheetName = paste ( "NZAuSpend_Eplus" , sep = "" ) )
writeData     ( wb, sheet     = paste ( "NZAuSpend_Eplus" , sep = "" ) , rowNames = FALSE , colNames = TRUE , TEM )
addWorksheet  ( wb, sheetName = paste ( "NZAuSpend_EPDE" , sep = "" ) )
writeData     ( wb, sheet     = paste ( "NZAuSpend_EPDE" , sep = "" ) , rowNames = FALSE , colNames = TRUE , TEMP )
saveWorkbook  ( wb, file      = paste ( "d0_4compare/BD_spendVRE_check" ,  ".xlsx" , sep = ""  ) , overwrite = TRUE  )

rm ( wb , TE , TEM , TEMP )
