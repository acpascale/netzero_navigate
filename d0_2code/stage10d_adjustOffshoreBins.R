##   Adjust offshore bin numbers to match NZAu
##
##   Created:        21 August 2024  - swicth bins 1 <-> 2 and 3 <-> 4
##                    
##   References:
##
##   ToDo:
##      

#-----0.ADMIN - Include libraries and other important-----------

##--A. Clean
setwd("X:/WORK/NZAu_LandUsePaper_MAIN/d0_2code/eer_supplycurves/v5/")
source("clean.R")

##--B.Load Library for country manipulations
suppressMessages ( library ( "openxlsx"     , lib.loc=.libPaths() ) )      # worksheet functions
suppressMessages ( library ( "reshape2"     , lib.loc=.libPaths() ) )      # melt, dcast

aspect <- c ( "binned_resource_df" , "capacity_constraints" , "capacity_factors" , "tx_cost" , "capex_cost" , "osw_depth" )

#-----END 0.ADMIN---------------



#-----1.COMBINE--------------------

##Read in each file and swicth OSW bin numbers

##binned_resource_df
i<-1
SC              <- read.csv  ( paste ( "final curves/" , aspect[i] , "_case9.csv" , sep = ""  ) , header=TRUE , stringsAsFactors = FALSE )

SC$bin_number   <- ifelse ( !( SC$type == "offshore" ) , SC$bin_number , 
                            ifelse ( SC$bin_number == 5 , SC$bin_number , 
                                     ifelse ( SC$bin_number == 1 , 11 , 
                                              ifelse ( SC$bin_number == 2 , 12 , 
                                                       ifelse ( SC$bin_number == 3 , 13 , 14 ) ) ) ) ) 

a <- subset ( SC , SC$type == "offshore")
b <- subset ( SC , !( SC$type == "offshore" ))
unique ( a$bin_number)
unique ( b$bin_number)

SC$bin_number   <- ifelse ( !( SC$type == "offshore" ) , SC$bin_number , 
                            ifelse ( SC$bin_number == 5 , SC$bin_number , 
                                     ifelse ( SC$bin_number == 11 , 2 , 
                                              ifelse ( SC$bin_number == 12 , 1 , 
                                                       ifelse ( SC$bin_number == 13 , 4 , 3 ) ) ) ) ) 

a <- subset ( SC , SC$type == "offshore")
b <- subset ( SC , !( SC$type == "offshore" ))
unique ( a$bin_number)
unique ( b$bin_number)

write.csv ( SC , paste ( "final curves/" , aspect[i] , "_case9a.csv" , sep = "" ) , row.names = FALSE )

i<-2
for ( i in 2:length ( aspect ) ) {
  
  SC              <- read.csv  ( paste ( "final curves/" , aspect[i] , "_case9.csv" , sep = ""  ) , header=TRUE , stringsAsFactors = FALSE )
  
  SC$bin_number   <- ifelse ( !( SC$type == "offshore" ) , SC$bin_number , 
                              ifelse ( SC$bin_number == 5 , SC$bin_number , 
                                       ifelse ( SC$bin_number == 1 , 11 , 
                                                ifelse ( SC$bin_number == 2 , 12 , 
                                                         ifelse ( SC$bin_number == 3 , 13 , 14 ) ) ) ) ) 
  
  a <- subset ( SC , SC$type == "offshore")
  b <- subset ( SC , !( SC$type == "offshore" ))
  unique ( a$bin_number)
  unique ( b$bin_number)
  
  SC$bin_number   <- ifelse ( !( SC$type == "offshore" ) , SC$bin_number , 
                              ifelse ( SC$bin_number == 5 , SC$bin_number , 
                                       ifelse ( SC$bin_number == 11 , 2 , 
                                                ifelse ( SC$bin_number == 12 , 1 , 
                                                         ifelse ( SC$bin_number == 13 , 4 , 3 ) ) ) ) ) 
  
  a <- subset ( SC , SC$type == "offshore")
  b <- subset ( SC , !( SC$type == "offshore" ))
  unique ( a$bin_number)
  unique ( b$bin_number)
  
  SC$name <- ifelse ( !( SC$type == "offshore" ) , SC$name , paste ( "offshore wind|" , SC$bin_number , sep = "" ) )
  
  write.csv ( SC , paste ( "final curves/" , aspect[i] , "_case9a.csv" , sep = "" ) , row.names = FALSE )

}
