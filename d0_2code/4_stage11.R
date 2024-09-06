##   COMBINED THREE FILES INTO ONE SCRIPT
##
##   Created:        25 August 2024 
##                    
##  TO BE TURNED INTO PYTHON

##--------------------------------------
##   Adjust offshore bin numbers to match NZAu -- NOT NEEDED IF RUNNING NEW WITH NO ALIGNMENT TO NZAU
##
##   Created:        21 August 2024
##                    
##   References:
##
##   ToDo:
##      

#-----0.ADMIN - Include libraries and other important-----------

##--A. Clean
#setwd("[base path here]/netzero_navigate/d0_2code")
source("clean.R")

##--B.Load Library for country manipulations
suppressMessages ( library ( "openxlsx"     , lib.loc=.libPaths() ) )      # worksheet functions
suppressMessages ( library ( "reshape2"     , lib.loc=.libPaths() ) )      # melt, dcast

aspect <- c ( "binned_resource_df" , "capacity_constraints" , "capacity_factors" , "tx_cost" , "capex_cost" , "osw_depth" )

ver <- "paperAU"

#-----END 0.ADMIN---------------



#-----1.COMBINE--------------------

##Read in each file and switch OSW bin numbers

##binned_resource_df
i<-1
SC              <- read.csv  ( paste ( "../d0_3results/sc_final/" , aspect[i] , "_" , ver , "case9.csv" , sep = ""  ) , header=TRUE , stringsAsFactors = FALSE )

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

write.csv ( SC , paste ( "../d0_3results/sc_final/" , aspect[i] , "_" , ver , "case9a.csv" , sep = "" ) , row.names = FALSE )

i<-2
for ( i in 2:length ( aspect ) ) {
  
  SC              <- read.csv  ( paste ( "../d0_3results/sc_final/" , aspect[i] , "_" , ver , "case9.csv" , sep = ""  ) , header=TRUE , stringsAsFactors = FALSE )
  
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
  
  write.csv ( SC , paste ( "../d0_3results/sc_final/" , aspect[i] , "_" , ver ,  "case9a.csv" , sep = "" ) , row.names = FALSE )
  
}

##------------------------------------------------------------------------------------
##   Supply Curve exploder
##
##   Created:        20 March 2024
##   25 August - modified for paper repository
##
##   References:
##
##   ToDo:
##      

#-----0.ADMIN - Include libraries and other important-----------

##--A. Clean
source("clean.R")

#sc data in
aspect <- c ( "binned_resource_df" , "capacity_constraints" , "capacity_factors" , "tx_cost" , "capex_cost" )


outVer <- 1

inVer  <- "paperAU" 
dfVer  <- "9a"

#-----END 0.ADMIN---------------


#-----1.DISSAGREGATE--------------------

#INCAP
SC              <- read.csv  ( paste ( "../d0_3results/sc_final/" , aspect[1] , "_" , inVer , "case" , dfVer , ".csv" , sep = ""  ) , header=TRUE , stringsAsFactors = FALSE )
SC              <- SC[, c ( 5 , 15 , 13 , 12 , 3 )]
SC$incap        <- round ( SC$incap / 1e3 , 5 )
names ( SC )[5] <- "incap_gW"
SCw                <- dcast ( SC,  NZAu_maj + type + bin_number ~ case , value.var = "incap_gW" , sum )

#format for 
names ( SCw )[4:7] <- c ( "NZAu_GW" , "Case1_GW" , "Case2_GW" , "Case3_GW" )
SCw[,4:7]          <- lapply ( SCw[,4:7] , function (x) round ( x , 3 ) )


CF              <- read.csv  ( paste ( "../d0_3results/sc_final/" , aspect[3] , "_nzau" ,  ".csv" , sep = ""  ) , header=TRUE , stringsAsFactors = FALSE )
CF              <- subset ( CF , vintage == "2020" )
CF              <- CF[, c ( 3 , 9 , 2  , 6 , 5 )]
CF$value        <- round ( CF$value , 3 )
names ( CF )[5] <- "cf_wLL_2020_nzau"
CFA              <- read.csv  ( paste ( "../d0_3results/sc_final/" , aspect[3] , "_" , inVer , "case" , dfVer ,  ".csv" , sep = ""  ) , header=TRUE , stringsAsFactors = FALSE )
CFA              <- subset ( CFA , vintage == "2020" )
CFA              <- CFA[, c ( 3 , 9 , 2  , 6 , 5 )]
CFA$value        <- round ( CFA$value , 3 )
names ( CFA )[5] <- "cf_wLL_2020_rerun"
CFA              <- merge ( CF , CFA , by = names ( CFA )[1:4] , all = TRUE  )


TX                 <- read.csv ( paste ( "../d0_3results/sc_final/" , aspect[4] , "_nzau" ,  ".csv" , sep = ""  ) , header=TRUE , stringsAsFactors = FALSE )
TX                 <- TX[, c ( 2 , 5 , 1 , 4 , 3 )]
TX$tx_cost_per_kw  <- round ( TX$tx_cost_per_kw , 0 )
names ( TX )[5]    <- "tx_cost_per_kw_2021_nzau"
TXA                <- read.csv  ( paste ( "../d0_3results/sc_final/" , aspect[4] , "_" , inVer , "case" , dfVer ,  ".csv" , sep = ""  ) , header=TRUE , stringsAsFactors = FALSE )
TXA                <- TXA[, c ( 2 , 5 , 1 , 4 , 3 )]
TXA$tx_cost_per_kw <- round ( TXA$tx_cost_per_kw , 0 )
names ( TXA  )[5]  <- "tx_cost_per_kw_2021_rerun"
TXA                <- merge ( TX , TXA , by = names ( TXA )[1:4] , all = TRUE  )

#offshore wind only
CAP                 <- read.csv ( paste ( "../d0_3results/sc_final/" , aspect[5] , "_nzau" ,  ".csv" , sep = ""  ) , header=TRUE , stringsAsFactors = FALSE )
CAP                 <- subset ( CAP , vintage == "2021" , select = c ( 2 , 6 , 1 , 5 , 4 ) )
CAP$capex_per_kw    <- round ( CAP$value , 3 )
names ( CAP )[6]    <- "capex_per_kw_2021_nzau"
CAP                 <- CAP[,-5]
CAPA                <- read.csv  ( paste ( "../d0_3results/sc_final/" , aspect[5] , "_" , inVer , "case" , dfVer ,  ".csv" , sep = ""  ) , header=TRUE , stringsAsFactors = FALSE )
CAPA                <- subset ( CAPA , vintage == "2021" , select = c ( 2 , 6 , 1 , 5 , 4 ) )
CAPA$capex_per_kw   <- round ( CAPA$value , 3 )
names ( CAPA  )[6]  <- "capex_per_kw_2021_rerun"
CAPA                <- CAPA[,-5]
CAPA                <- merge ( CAP , CAPA , by = names ( CAPA )[1:4] , all = TRUE  )
#add PV and wind
CAP                 <- read.csv ( paste ( "../d0_1source/TECH_CAPITAL_COST.csv" , sep = ""  ) , header=TRUE , stringsAsFactors = FALSE )
CAP                 <- subset ( CAP , grepl ( "onshore|large-scale" , CAP$name) & vintage == 2021 & sensitivity == "2022 ISP [d]" , select = c ( "name" , "value" ) )
CAPB                <- subset ( TXA , !TXA$type == "offshore" , select = c ( 1:4 ) )
CAPB                <- merge ( CAPB , CAP , by = "name" , all = TRUE )
CAPB$value2         <- CAPB$value
names ( CAPB )[5:6] <- c ( "capex_per_kw_2021_nzau" , "capex_per_kw_2021_rerun" )
CAPB                <- CAPB [, c ( 2:4, 1 , 5:6 )]
CAPA                <- rbind ( CAPA , CAPB )

SCF <- merge ( CFA , TXA  , by = names ( CFA )[1:4] , all = TRUE  )
SCF <- merge ( SCF , CAPA , by = names ( SCF )[1:4] , all = TRUE  )
SCF <- merge ( SCF , SCw  , by = names ( CFA )[1:3] , all = TRUE  )

rm ( CF , CFA , TX , TXA, SCw , SC , CAP , CAPB , CAPA)


##combine and make columns for table E+
s                   <- 1
scenarios           <- c ( "eplus" , "eplus-distributedexport" )
labs                <- c ( "ep" , "epde" )
EER                 <- read.csv ( paste ( "../d0_1source/nzauOut_capacity.csv" , sep = "" ) , header=TRUE , stringsAsFactors = FALSE , fileEncoding = "UTF-8-BOM" )
EER                 <- subset ( EER , EER$run.name %in% scenarios[s] )
EER$value           <- ifelse ( is.na ( EER$value ) , 0 , round ( EER$value  , 4 ) )
EERw                <- dcast  ( EER , tech + zone ~ year , value.var = "value" , sum )
names ( EERw )[1:2] <- c ( "name" , "NZAu_maj" )

FINA                <- merge ( SCF , EERw , by = c ( "NZAu_maj" , "name" ) , all = TRUE )


##nsw-central clean 15 August -- NOT NEEDED IF RUNNING NEW
FINA$NZAu_GW        <- ifelse ( FINA$NZAu_maj == "nsw-central" & FINA$name == "onshore wind|1" , FINA$`2050` , FINA$NZAu_GW )
FINA$Case1_GW       <- ifelse ( FINA$NZAu_maj == "nsw-central" & FINA$name == "onshore wind|1" , FINA$`2050` , FINA$Case1_GW )
FINA$Case2_GW       <- ifelse ( FINA$NZAu_maj == "nsw-central" & FINA$name == "onshore wind|1" , FINA$`2050` , FINA$Case2_GW )
FINA$Case3_GW       <- ifelse ( FINA$NZAu_maj == "nsw-central" & FINA$name == "onshore wind|1" , FINA$`2050` , FINA$Case3_GW )

#clean  14 August 2024 - NOT NEEDED IF RUNNING NEW
FINA$tx_cost_per_kw_2021_nzau <- ifelse ( is.na ( FINA$cf_wLL_2020_nzau ) , 0 , FINA$tx_cost_per_kw_2021_nzau )
FINA$capex_per_kw_2021_nzau   <- ifelse ( ( is.na ( FINA$cf_wLL_2020_nzau ) & is.na ( FINA$capex_per_kw_2021_nzau ) ) , 0 , FINA$capex_per_kw_2021_nzau   )
FINA$`2025`                   <- ifelse ( is.na ( FINA$cf_wLL_2020_nzau ) , 0 , FINA$`2025`  )
FINA$`2030`                   <- ifelse ( is.na ( FINA$cf_wLL_2020_nzau ) , 0 , FINA$`2030`  )
FINA$`2035`                   <- ifelse ( is.na ( FINA$cf_wLL_2020_nzau ) , 0 , FINA$`2035`  )
FINA$`2040`                   <- ifelse ( is.na ( FINA$cf_wLL_2020_nzau ) , 0 , FINA$`2040`  )
FINA$`2045`                   <- ifelse ( is.na ( FINA$cf_wLL_2020_nzau ) , 0 , FINA$`2045`  )
FINA$`2050`                   <- ifelse ( is.na ( FINA$cf_wLL_2020_nzau ) , 0 , FINA$`2050`  )
FINA$`2055`                   <- ifelse ( is.na ( FINA$cf_wLL_2020_nzau ) , 0 , FINA$`2055`  )
FINA$`2060`                   <- ifelse ( is.na ( FINA$cf_wLL_2020_nzau ) , 0 , FINA$`2060`  )
FINA$cf_wLL_2020_nzau         <- ifelse ( is.na ( FINA$cf_wLL_2020_nzau ) , FINA$cf_wLL_2020_rerun , FINA$cf_wLL_2020_nzau )

FINA$cf_wLL_2020_rerun         <- ifelse ( is.na ( FINA$NZAu_GW ) , FINA$cf_wLL_2020_nzau , FINA$cf_wLL_2020_rerun )
FINA$tx_cost_per_kw_2021_rerun <- ifelse ( ( is.na ( FINA$NZAu_GW ) & is.na ( FINA$tx_cost_per_kw_2021_rerun ) ) , 0 , FINA$tx_cost_per_kw_2021_rerun )
FINA$capex_per_kw_2021_rerun   <- ifelse ( ( is.na ( FINA$NZAu_GW ) & is.na ( FINA$capex_per_kw_2021_rerun ) ) , 0 , FINA$capex_per_kw_2021_rerun )
FINA$Case1_GW                  <- ifelse ( is.na ( FINA$NZAu_GW ) , 0 , FINA$Case1_GW )
FINA$Case2_GW                  <- ifelse ( is.na ( FINA$NZAu_GW ) , 0 , FINA$Case2_GW )
FINA$Case3_GW                  <- ifelse ( is.na ( FINA$NZAu_GW ) , 0 , FINA$Case3_GW )
FINA$NZAu_GW                   <- ifelse ( is.na ( FINA$NZAu_GW ) , 0 , FINA$NZAu_GW )
# end clean


FINA$type_b         <- paste ( ifelse ( FINA$type == "solar" , "PV [" , ifelse ( FINA$type == "onshore" , "ON [" , "OFF[" ) )  , FINA$bin_number , "]" , sep="" )
FINA$EP2060         <- paste ( ifelse ( FINA$'2060' < 1 , round ( FINA$'2060' , 1 ) , round ( FINA$'2060' , 0) ) , " (" , FINA$cf_wLL_2020_nzau , ", " , FINA$tx_cost_per_kw_2021_nzau , ")" , sep= "" ) 
FINA$CASE1          <- paste ( ifelse ( FINA$Case1_GW < 1 , round ( FINA$Case1_GW , 1 ) , round ( FINA$Case1_GW , 0) ) , " (" , FINA$cf_wLL_2020_rerun , ", " , FINA$tx_cost_per_kw_2021_rerun , ")" , sep= "" ) 
FINA$CASE2          <- paste ( ifelse ( FINA$Case2_GW < 1 , round ( FINA$Case2_GW , 1 ) , round ( FINA$Case2_GW , 0) ) , " (" , FINA$cf_wLL_2020_rerun , ", " , FINA$tx_cost_per_kw_2021_rerun , ")" , sep= "" ) 
FINA$CASE3          <- paste ( ifelse ( FINA$Case3_GW < 1 , round ( FINA$Case3_GW , 1 ) , round ( FINA$Case3_GW , 0) ) , " (" , FINA$cf_wLL_2020_rerun , ", " , FINA$tx_cost_per_kw_2021_rerun , ")" , sep= "" ) 

FINA                <- FINA[order ( FINA$NZAu_maj , decreasing = TRUE ),] 

#FINB                <- subset ( FINA , ( FINA$'2060' > 0.1 | grepl ("ex-" , FINA$NZAu_maj) ) , select = c ( "type_b" , "NZAu_maj" , "EP2060" , "CASE1" , "CASE2" , "CASE3" ) )
FINB <- FINA

write.csv( FINB , file = paste ( "../d0_3results/paper_codeAnalyses/" , inVer , "_cases_" , labs[s] , "_wNzau_all_wCapex_v" , outVer , ".csv" , sep = "" ) ,row.names = FALSE )

##combine and make columns for table E+ DIST EXPORT
s                   <- 2
scenarios           <- c ( "eplus" , "eplus-distributedexport" )
labs                <- c ( "ep" , "epde" )
EER                 <- read.csv ( paste ( "../d0_1source/nzauOut_capacity.csv" , sep = "" ) , header=TRUE , stringsAsFactors = FALSE , fileEncoding = "UTF-8-BOM" )
EER                 <- subset ( EER , EER$run.name %in% scenarios[s] )
EER$value           <- ifelse ( is.na ( EER$value ) , 0 , round ( EER$value  , 2 ) )
EERw                <- dcast  ( EER , tech + zone ~ year , value.var = "value" , sum )
names ( EERw )[1:2] <- c ( "name" , "NZAu_maj" )

FINC                <- merge ( SCF , EERw , by = c ( "NZAu_maj" , "name" ) , all = TRUE )

##nsw-central clean 15 August
FINC$NZAu_GW        <- ifelse ( FINC$NZAu_maj == "nsw-central" & FINC$name == "onshore wind|1" , FINC$`2050` , FINC$NZAu_GW )
FINC$Case1_GW       <- ifelse ( FINC$NZAu_maj == "nsw-central" & FINC$name == "onshore wind|1" , FINC$`2050` , FINC$Case1_GW )
FINC$Case2_GW       <- ifelse ( FINC$NZAu_maj == "nsw-central" & FINC$name == "onshore wind|1" , FINC$`2050` , FINC$Case2_GW )
FINC$Case3_GW       <- ifelse ( FINC$NZAu_maj == "nsw-central" & FINC$name == "onshore wind|1" , FINC$`2050` , FINC$Case3_GW )

#clean  14 August 2024
FINC$tx_cost_per_kw_2021_nzau <- ifelse ( is.na ( FINC$cf_wLL_2020_nzau ) , 0 , FINC$tx_cost_per_kw_2021_nzau )
FINC$capex_per_kw_2021_nzau   <- ifelse ( ( is.na ( FINC$cf_wLL_2020_nzau ) & is.na ( FINC$capex_per_kw_2021_nzau ) ) , 0 , FINC$capex_per_kw_2021_nzau   )
FINC$`2025`                   <- ifelse ( is.na ( FINC$cf_wLL_2020_nzau ) , 0 , FINC$`2025`  )
FINC$`2030`                   <- ifelse ( is.na ( FINC$cf_wLL_2020_nzau ) , 0 , FINC$`2030`  )
FINC$`2035`                   <- ifelse ( is.na ( FINC$cf_wLL_2020_nzau ) , 0 , FINC$`2035`  )
FINC$`2040`                   <- ifelse ( is.na ( FINC$cf_wLL_2020_nzau ) , 0 , FINC$`2040`  )
FINC$`2045`                   <- ifelse ( is.na ( FINC$cf_wLL_2020_nzau ) , 0 , FINC$`2045`  )
FINC$`2050`                   <- ifelse ( is.na ( FINC$cf_wLL_2020_nzau ) , 0 , FINC$`2050`  )
FINC$`2055`                   <- ifelse ( is.na ( FINC$cf_wLL_2020_nzau ) , 0 , FINC$`2055`  )
FINC$`2060`                   <- ifelse ( is.na ( FINC$cf_wLL_2020_nzau ) , 0 , FINC$`2060`  )
FINC$cf_wLL_2020_nzau         <- ifelse ( is.na ( FINC$cf_wLL_2020_nzau ) , FINC$cf_wLL_2020_rerun , FINC$cf_wLL_2020_nzau )

FINC$cf_wLL_2020_rerun         <- ifelse ( is.na ( FINC$NZAu_GW ) , FINC$cf_wLL_2020_nzau , FINC$cf_wLL_2020_rerun )
FINC$tx_cost_per_kw_2021_rerun <- ifelse ( ( is.na ( FINC$NZAu_GW ) & is.na ( FINC$tx_cost_per_kw_2021_rerun ) ) , 0 , FINC$tx_cost_per_kw_2021_rerun )
FINC$capex_per_kw_2021_rerun   <- ifelse ( ( is.na ( FINC$NZAu_GW ) & is.na ( FINC$capex_per_kw_2021_rerun ) ) , 0 , FINC$capex_per_kw_2021_rerun )
FINC$Case1_GW                  <- ifelse ( is.na ( FINC$NZAu_GW ) , 0 , FINC$Case1_GW )
FINC$Case2_GW                  <- ifelse ( is.na ( FINC$NZAu_GW ) , 0 , FINC$Case2_GW )
FINC$Case3_GW                  <- ifelse ( is.na ( FINC$NZAu_GW ) , 0 , FINC$Case3_GW )
FINC$NZAu_GW                   <- ifelse ( is.na ( FINC$NZAu_GW ) , 0 , FINC$NZAu_GW )
# end clean

FINC$type_b         <- paste ( ifelse ( FINC$type == "solar" , "PV [" , ifelse ( FINC$type == "onshore" , "ON [" , "OFF [" ) )  , FINC$bin_number , "]" , sep="" )
FINC$EP2060         <- paste ( ifelse ( FINC$'2060' < 1 , round ( FINC$'2060' , 1 ) , round ( FINC$'2060' , 0) ) , " (" , FINC$cf_wLL_2020_nzau , ", " , FINC$tx_cost_per_kw_2021_nzau , ")" , sep= "" ) 
FINC$CASE1          <- paste ( ifelse ( FINC$Case1_GW < 1 , round ( FINC$Case1_GW , 1 ) , round ( FINC$Case1_GW , 0) ) , " (" , FINC$cf_wLL_2020_rerun , ", " , FINC$tx_cost_per_kw_2021_rerun , ")" , sep= "" ) 
FINC$CASE2          <- paste ( ifelse ( FINC$Case2_GW < 1 , round ( FINC$Case2_GW , 1 ) , round ( FINC$Case2_GW , 0) ) , " (" , FINC$cf_wLL_2020_rerun , ", " , FINC$tx_cost_per_kw_2021_rerun , ")" , sep= "" ) 
FINC$CASE3          <- paste ( ifelse ( FINC$Case3_GW < 1 , round ( FINC$Case3_GW , 1 ) , round ( FINC$Case3_GW , 0) ) , " (" , FINC$cf_wLL_2020_rerun , ", " , FINC$tx_cost_per_kw_2021_rerun , ")" , sep= "" ) 

FINC                <- FINC[order ( FINC$NZAu_maj , decreasing = TRUE ),] 

#FIND                <- subset ( FINC , FINC$'2060' > 0.1  , select = c ( "type_b" , "NZAu_maj" , "EP2060" , "CASE1" , "CASE2" , "CASE3" ) )
FIND                <- FINC

write.csv( FIND , file = paste ( "../d0_3results/paper_codeAnalyses/" , inVer , "_cases_" , labs[s] , "_wNzau_all_wCapex_v" , outVer , ".csv" , sep = "" ) ,row.names = FALSE )


##-------------------------------------------------------------------------------------
##   Supply Curve exploder
##
##   Created:        13 August 2024
##   Last updated:   25 August 2024 prepare for paper repository
##
##   References:
##
##   NOTES:
##           -- wish to keep year builds instead of "unsolve",  need row flag

#-----0.ADMIN - Include libraries and other important-----------

##--A. Clean
source("clean.R")

resource           <- c ( "solar" , "onshore" , "offshore" )
scenarios           <- c ( "eplus" , "eplus-distributedexport" )
labs                <- c ( "ep" , "epde" )
cases              <- c ( "nzauO" , "nzauR" , "case1" , "case2" , "case3" )
asp                <- c ( "build" , "TX_bAUD2021" , "CP_bAUD2021" , "TOT_bAUD2021" )
aspL               <- c ( "GW" , "TX" , "CAP" , "TOT" )
years              <- c ( 2025 , 2030 , 2035 , 2040 , 2045 , 2050 , 2055 , 2060 )
unsolve            <- 9999999
cutoff             <- c ( 0.005 , 0.050 , 0.1 )
mapsMax            <- c ( 0 , 0 , 0 , 0 , 0 ,  unsolve ,  unsolve ,  unsolve ,  unsolve , 0 , 0 , 0 , 0 , 0 ,  unsolve ,  unsolve ,  unsolve ,  unsolve  )
mapsMin            <- c ( 0 , 0 , 0 , 0 , 0 , -unsolve , -unsolve , -unsolve , -unsolve , 0 , 0 , 0 , 0 , 0 , -unsolve , -unsolve , -unsolve , -unsolve  )

inVer              <- "paperAU" # from previous step
inVern             <- 1
outVer             <- 1
compare            <- c ( "case2" , "case3" )


#-----END 0.ADMIN---------------


#-----1.HACK--------------------

####COSTS PREP STARTS####

##NZAu costs prepare
AUD2020_AUD2021      <- 1.026
USD2019_AUD2021      <- (255.7988/254.2227) * 1.452 * AUD2020_AUD2021  # (255.7988/249.703) *

#on project costs
TCC                  <- read.csv ( paste ( "../d0_1source/TECH_CAPITAL_COST.csv" , sep = "" ) , header=TRUE , stringsAsFactors = FALSE , fileEncoding = "UTF-8-BOM"  )
TCCa                 <- subset ( TCC , grepl ( "wind|solar" , TCC$name ) & ( TCC$vintage %in% years ) & !grepl ( "rooftop" , TCC$name ) & !grepl ( "offshore" , TCC$name ) & !( TCC$source == "NREL 2020 ATB" )   & ( TCC$sensitivity == "2022 ISP [d]" ) ) # & ( TCC$vintage == TCCvin )
TCCb                 <- melt ( TCCa , id.vars = c ( "name" , "gau" , "vintage" ) , measure.vars = "value" , value.name = "AUD2021.kW" )
TCCb$AUD2021.kW      <- TCCb$AUD2021.kW * AUD2020_AUD2021
TCCc                 <- dcast ( TCCb , name + gau ~ vintage , value.var = "AUD2021.kW" , fun.aggregate = sum )
TCCc$'2055'          <- TCCc$'2050'
TCCc$'2060'          <- TCCc$'2050'
ONv                  <- melt ( TCCc , id.vars = 1 , measure.vars = 3:10 , variable.name = "year" , value.name = "CapC_aud2021")
#off project costs original
TCC                  <- read.csv ( paste ( "../d0_1source/TECH_CAPITAL_COST_off.csv" , sep = "" ) , header=TRUE , stringsAsFactors = FALSE , fileEncoding = "UTF-8-BOM"  )
TCCa                 <- subset ( TCC , grepl ( "offshore" , TCC$name ) & ( TCC$vintage %in% years ) & ( TCC$source == "NREL 2021 ATB" ) & ( TCC$sensitivity == "ATB2021 Moderate w depth adjustment [d]")  )
TCCb                 <- melt   ( TCCa , id.vars = c ( "name" , "gau" , "vintage" ) , measure.vars = "value" , value.name = "AUD2021.kW" )
TCCb$AUD2021.kW      <- TCCb$AUD2021.kW * USD2019_AUD2021
TCCd                 <- dcast  ( TCCb , name + gau ~ vintage , value.var = "AUD2021.kW" , fun.aggregate = sum )
TCCd$'2055'          <- TCCd$'2050'
TCCd$'2060'          <- TCCd$'2050'
OFv                  <- melt ( TCCd , id.vars = 1:2 , measure.vars = 3:10 , variable.name = "year" , value.name = "CapC_aud2021")
names ( OFv )[2]     <- "NZAu_maj"
rm ( TCCd , TCCa , TCCb , TCCc , TCC )
##off project costs new
OFC                 <- read.csv  ( paste ( "../d0_3results/sc_final/"  , "capex_cost" , "_" , inVer , "case" , 9 ,  ".csv" , sep = ""  ) , header=TRUE , stringsAsFactors = FALSE )
OFC                 <- subset ( OFC ,  select = c ( 5 , 3 , 2 , 4  ) )
names ( OFC  )      <- c ( "name" , "year" , "NZAu_maj" , "capexOFF" )
OFC$capexOFF        <- OFC$capexOFF * USD2019_AUD2021
OFCa                <- subset ( OFC , OFC$year == 2050 )
OFCa$year           <- 2055
OFC                 <- rbind ( OFC, OFCa)
OFCa$year           <- 2060
OFC                 <- rbind ( OFC, OFCa)
OFC                 <- subset ( OFC , OFC$year %in% years)
rm ( OFCa )

###offshore wind TX learning curve
TXC                  <- read.csv ( paste ( "../d0_1source/" , "NEW_TECH_TX_COST.csv" , sep = "" ) , header=TRUE , stringsAsFactors = FALSE , fileEncoding = "UTF-8-BOM"  )
TXC                  <- subset ( TXC , grepl ( "off" , TXC$name ) )
TXClc                <- subset ( TXC , TXC$gau == "all" & grepl ( "1" , TXC$name ) & ( TXC$vintage %in% c ( 2021 , years ) ) )
TXClc$mult           <- TXClc$value / subset ( TXClc$value , TXClc$vintage == 2021 )
TXCa                 <- subset ( TXClc , select = c ( "vintage" , "mult" ) )
names ( TXCa )       <- c ( "year" , "TXmult")
TXm                  <- rbind ( TXCa , rbind ( TXCa[nrow ( TXCa ), ] ,TXCa[nrow ( TXCa ), ] ) )
TXm[8,1]             <- 2055
TXm[9,1]             <- 2060
rm ( TXC , TXClc , TXCa )

####COSTS PREP ENDS###
####BUILD STARTS####

#d#
#d#nzau#
i<-10
#d#resource#
j<-3
#d#cases#
s<-2
#d##yearCol#
y<-12
#d#row of subset resources being worked on#
r<-5
#d##scenarios#
c<-1
#load output of prior step
for ( c in 1:length ( scenarios ) ) {
  EPA         <- read.csv  ( paste ( "../d0_3results/paper_codeAnalyses/" , inVer , "_cases_" , labs[c] , "_wNzau_all_wCapex_v" , inVern , ".csv" , sep = "" ) , header=TRUE , stringsAsFactors = FALSE )
  for ( u in 15:22 ) { EPA[,u] <- ifelse ( EPA$type == resource[1] & EPA[,u] < cutoff[1]  , 0 , ifelse ( EPA$type == resource[2] & EPA[,u] < cutoff[2] , 0 , ifelse ( EPA$type == resource[3] & EPA[,u] < cutoff[3] , 0 , EPA[,u]  ) ) )}
  EPA         <- subset ( EPA , !( ( EPA$X2060 == 0 ) & ( EPA$Case3_GW == 0 ) ) )
  for ( i in 1:length ( unique ( EPA$NZAu_maj ) ) ){
    for ( j in 1:length ( resource ) ) {
      EPB <- subset ( EPA , EPA$NZAu_maj == unique ( EPA$NZAu_maj )[i] & EPA$type == resource[j] , select = c ( 1:5,7,9,6,8,10,15:22,11:14 ) )
      if ( nrow ( EPB ) > 0 ) {
        
        for ( s in 1:5 ) {
          EPC <- subset ( EPB, select = c ( 1:10 , 3 , 11:18 , 11:18 , (17+s) ) )
          names ( EPC )[5:28] <- c ( "CFo" , "TXo" , "CPo" , "CFr" , "TXr" , "CPr" , "case" , names ( EPC )[12:19] , gsub ( "X" , "Y" , names ( EPC )[12:19] ) , "GW" )
          EPC$case <- cases[s]
          ##
          EPC$CPr  <- EPC$TXr / ( 8760 * EPC$CFr )
          if ( s > 1 ) {
            ##adjust builds for for revised bins in all but original case
            EPC[,12:19] <- sapply ( EPC[,12:19] , function ( x ) x * ( EPC$CFo /  EPC$CFr ) ) 
            #get available after adjusting for revised bins
            EPC[,20:27] <- EPC$GW - EPC[,12:19]
            for ( y in 12:19 ) {
              EPC <- EPC[order ( EPC[,(y+8)] , decreasing = FALSE ),]
              for ( r in 1:nrow ( EPC ) ) {
                if ( EPC[r,(y+8)] >= 0 ) {
                  EPC[r,y]     <- EPC[r,y]
                }
                if ( EPC[r,(y+8)] < 0 ) {
                  if ( r+1 <= nrow ( EPC ) ) {
                    adj <- EPC[r,(y+8)]
                    #reorder remaining rows in region according to simple LCofTx
                    EPD <- EPC[(r+1):nrow(EPC),]
                    EPD  <- EPD[order ( EPD$CPr , decreasing = FALSE ),]
                    EPC <- rbind ( EPC[1:r,] , EPD )
                    rm ( EPD )
                    ##draw from next bin
                    for ( z in y:(ifelse ( y+6 > 19 , 19 , y+6 ) ) ) {
                      adj2         <- EPC[r,z] + adj
                      EPC[r,z]     <- ifelse ( adj2 < 0 , 0 , adj2 )
                      EPC[r+1,z]   <- EPC[r+1,z]  -adj * ( EPC$CFr[r]  /  EPC$CFr[r+1] ) + ifelse ( adj2 > 0 , 0 , adj2 * ( EPC$CFr[r]  /  EPC$CFr[r+1] ) )
                      EPC[r+1,z+8] <- ( EPC$GW[r+1] - EPC[r+1,z] ) #EPC[r+1,z+8] + adj * ( EPC$CFr[r]  /  EPC$CFr[r+1] )  #+ adj ...  
                    }
                    for ( z in y:(ifelse ( y+6 > 19 , 19 , y+6 ) ) ) {
                      adj2         <- - EPC[r,(z+8)] + adj
                      EPC[r,(z+8)] <- ifelse ( adj2 < 0 , 0 , EPC[r,(z+8)] - adj )
                    }
                  } else { 
                    ADD      <- data.frame( EPC[r,] )
                    ADD$scen <- labs[c]
                    ADD      <- ADD[,c ( 1:4, 4 , 29 , 11 , 28 , 28 , 28 )]
                    ADD[5]   <- names( EPC )[y]
                    ADD[8]   <- sum ( EPC$GW )
                    ADD[9]   <- sum ( EPC[,y])
                    ADD[10]  <- ADD[8] - ADD[9]
                    names ( ADD ) <- c ( names ( ADD )[1:4] , "year" , "scenario" , "case" , "GW_have" , "GW_need" , "GW_miss" )
                    if (  exists ( "FAILS" ) ) { FAILS <- rbind ( FAILS , ADD ) }
                    if ( !exists ( "FAILS" ) ) { FAILS <- ADD }
                    EPC[r,y] <- unsolve 
                  }
                  
                }
              }
            }
          }
          if ( s == 1) {  EPC$GW <- apply ( EPC[,12:19] , 1 , max ) }
          EPC         <- EPC[,c(1:19,28)]
          EPC[,12:20] <- sapply ( EPC[,12:20] , function ( x ) round ( x , 3) )
          EPC$scen    <- labs[c]
          EPC         <- EPC[, c ( 1:4, 21 , 11 , 5:10 , 20 , 12:19 )] 
          if (  exists ( "COSTS" ) ) { COSTS <- rbind ( COSTS , EPC ) }
          if ( !exists ( "COSTS" ) ) { COSTS <- EPC }
        }
      }
    }
  }
  rm ( EPB , EPC , EPA , c, i , j , r , s , y , adj , u , z , ADD )
}

####BUILD ENDS####
####COSTS STARTS###

##calculate annual build diff
COSTS$build        <- ifelse ( COSTS$X2050 == unsolve | COSTS$X2055 == unsolve | COSTS$X2060 == unsolve, unsolve , COSTS$X2050 + ( COSTS$X2055 + COSTS$X2025 - COSTS$X2050 ) + ifelse ( ( COSTS$X2060 - COSTS$X2055 + (COSTS$X2030 - COSTS$X2025 ) ) <= 0 , 0 , ( COSTS$X2060 - COSTS$X2055 + (COSTS$X2030 - COSTS$X2025 ) ) ) )
COSTS$y2025        <- COSTS$X2025
COSTS$y2030        <- COSTS$X2030 - COSTS$X2025
COSTS$y2035        <- COSTS$X2035 - COSTS$X2030
COSTS$y2040        <- COSTS$X2040 - COSTS$X2035
COSTS$y2045        <- COSTS$X2045 - COSTS$X2040
COSTS$y2050        <- COSTS$X2050 - COSTS$X2045
COSTS$y2055        <- round ( ifelse ( ( COSTS$X2055 + COSTS$X2025 - COSTS$X2050 ) <= 0 , 0 , COSTS$X2055 + COSTS$X2025 - COSTS$X2050 ), 3 )
COSTS$y2060        <- round ( ifelse ( ( COSTS$X2060 + (COSTS$X2030 - COSTS$X2025 ) - COSTS$X2055 ) <= 0 , 0 , COSTS$X2060 + (COSTS$X2030 - COSTS$X2025 ) - COSTS$X2055 ) , 3 )
#COSTS$build2       <- round ( COSTS$build - rowSums ( COSTS[,23:30]) , 0 )

#add costs from prep
COSv               <- melt ( COSTS , id.vars = 1:22 , measure.vars = 23:30 , variable.name = "year" , value.name = "GWy")
COSv$year          <- as.numeric( substring ( COSv$year , 2 , 5 ) )
COSv$GWy           <- ifelse ( COSv$GWy < 0 , 0 , COSv$GWy ) 
#COSv               <- subset ( COSv , COSv$GWy > 0 )
#offshore multiplier
COSv               <- merge ( COSv , TXm , by = "year" , all.x = TRUE )
COSv$TXmult        <- ifelse ( COSv$type == "offshore" , COSv$TXmult , 1)
##add onshore and offshore capital costs
COSv                <- merge ( COSv , ONv , by = c ( "name" , "year" ) , all.x = TRUE )
COSv                <- merge ( COSv , OFv , by = c ( "name" , "NZAu_maj" , "year" ) , all.x = TRUE )
COSv                <- merge ( COSv , OFC , by = c ( "name" , "NZAu_maj" , "year" ) , all.x = TRUE )
COSv$CapC_aud2021.y <- ifelse ( is.na ( COSv$CapC_aud2021.y ) & COSv$case == "nzauO" , 0 , COSv$CapC_aud2021.y )
COSv$CAP_aud2021.kw <- ifelse ( is.na ( COSv$CapC_aud2021.x ) , ifelse ( COSv$case == "nzauO" ,  COSv$CapC_aud2021.y , COSv$capexOFF ) , COSv$CapC_aud2021.x )
COSv                <- subset ( COSv , !( is.na ( COSv$CAP_aud2021.kw ) ) )
COSv                <- COSv[,-c(26:28)]
rm ( TXm , ONv , OFv , OFC  )

#calculate annual costs
COSv$TX_bAUD2021  <- round ( ifelse ( COSv$build >= unsolve , unsolve , ( COSv$GWy * ifelse ( COSv$case == cases[1] , COSv$TXo , COSv$TXr ) * 1e6 / 1e9 ) * COSv$TXmult ) , 4 )
COSv$CP_bAUD2021  <- round ( ifelse ( COSv$build >= unsolve , unsolve , ( COSv$GWy * COSv$CAP_aud2021.kw * 1e6 / 1e9 ) ) , 4 )
COSv$TOT_bAUD2021 <- round ( ifelse ( COSv$build >= unsolve , unsolve , ( COSv$TX_bAUD2021 + COSv$CP_bAUD2021 ) ) , 4 )

##aggregate to map regions
COSv$build <- ifelse ( COSv$year == 2060 , COSv$build , 0 )
BLDv <- melt  ( COSv , id.vars = c ( 2,1,6,7 ) , measure.vars = c ( 23, 27:29 ) , variable.name = "aspect"  )
BLDw <- dcast ( BLDv , NZAu_maj + scen + aspect ~ case , fun.aggregate = sum )
BLDw[,4:8] <- sapply ( BLDw[,4:8] , function ( x ) round ( ifelse ( x >= unsolve , unsolve , x ) , 5 ) )

#d##case comparisons
comp<-2
for ( comp in 1:length ( compare ) ) {
  
  ##get percent differencs
  #names(BLDw)[which (names(BLDw) == compare)]
  BLDw$pNr <- round ( 100 * ( BLDw$nzauR - BLDw$nzauO ) / BLDw$nzauO , 2 ) 
  BLDw$pC1 <- round ( 100 * ( BLDw$case1 - BLDw[,which (names(BLDw) == compare[comp])] ) / BLDw[,which (names(BLDw) == compare[comp])] , 2 )
  BLDw$pC2 <- round ( 100 * ( BLDw$case2 - BLDw[,which (names(BLDw) == compare[comp])] ) / BLDw[,which (names(BLDw) == compare[comp])] , 2 )
  BLDw$pC3 <- round ( 100 * ( BLDw$case3 - BLDw[,which (names(BLDw) == compare[comp])] ) / BLDw[,which (names(BLDw) == compare[comp])] , 2 )
  
  ##improve yearly build file
  CSUM               <- COSv
  CSUM$CF            <- ifelse ( CSUM$case == "nzauO" , CSUM$CFo , CSUM$CFr )
  CSUM$TX_aud2021.kw <- ifelse ( CSUM$case == "nzauO" , CSUM$TXo , CSUM$TXr )
  CSUM$sLCCtx        <- CSUM$CPr
  CSUM               <- subset ( CSUM , CSUM$GWy > 0 )
  CSUM               <- CSUM [,-c ( 8:23 )]
  CSUM               <- CSUM [, c ( 1:7 , 14 , 16 , 10 , 15 , 9 , 8 , 11:13 )]
  GCHK               <- dcast ( CSUM , scen ~ case , value.var = "GWy" , fun.aggregate = sum )
  SCHK               <- dcast ( CSUM , scen ~ case , value.var = "TOT_bAUD2021" , fun.aggregate = sum )
  TCHK               <- dcast ( CSUM , scen ~ case , value.var = "TX_bAUD2021" , fun.aggregate = sum )
  CCHK               <- dcast ( CSUM , scen ~ case , value.var = "CP_bAUD2021" , fun.aggregate = sum )
  #CCHK               <- dcast ( CSUM , NZAu_maj ~ scen + case , value.var = "CP_bAUD2021" , fun.aggregate = sum )
  #CCHK[,2:11]        <- sapply (CCHK[,2:11] , function ( x ) round ( x , 3 ))
  
  ##OUTPUTS
  wb            <- createWorkbook(creator = "AP")
  addWorksheet  ( wb, sheetName = paste ( "paper_build" , sep = "" ) )
  writeData     ( wb, sheet     = paste ( "paper_build" , sep = "" ) , rowNames = FALSE , colNames = TRUE , COSTS )
  addWorksheet  ( wb, sheetName = paste ( "paper_build_year" , sep = "" ) )
  writeData     ( wb, sheet     = paste ( "paper_build_year" , sep = "" ) , rowNames = FALSE , colNames = TRUE , CSUM )
  addWorksheet  ( wb, sheetName = paste ( "paper_build_fails" , sep = "" ) )
  writeData     ( wb, sheet     = paste ( "paper_build_fails" , sep = "" ) , rowNames = FALSE , colNames = TRUE , FAILS )
  #d#aspect#
  i<-2
  for ( i in 1:length ( asp ) ) {
    TE                  <- subset ( BLDw , BLDw$scen == labs[1] & BLDw$aspect == asp[i] )
    names ( TE )[4:12]  <- paste ( labs[1] , names ( TE )[4:12] , sep = "_" )
    TEM                 <- subset ( BLDw , BLDw$scen == labs[2] & BLDw$aspect == asp[i] )
    names ( TEM )[4:12] <- paste ( labs[2] , names ( TEM )[4:12] , sep = "_" )
    TEMP                <- merge ( TE[,-2] , TEM[,-2] , by = c ( "NZAu_maj" , "aspect" ) , all = TRUE )
    TEMP[,3:20]         <- sapply ( TEMP[,3:20] , function ( x ) round ( ifelse ( x > 999999 , unsolve , x ) , 3 ) )
    TEMP                <- rbind ( TEMP , rbind ( TEMP[20,] , TEMP[20,] ) )
    TEMP$NZAu_maj[21]   <- "aus_max"
    TEMP$NZAu_maj[22]   <- "aus_min"
    TEMP[21,3:20]       <- mapsMax
    TEMP[22,3:20]       <- mapsMin
    write.csv( TEMP   , file = paste ( "../d0_3results/paper_codeAnalyses/paperAU_map_" , compare[comp] , "_v" , outVer, "_" , aspL[i]  , ".csv" , sep = "" ) ,row.names = FALSE )
    addWorksheet  ( wb, sheetName = paste ( "maps" , aspL[i] , sep = "" ) )
    writeData     ( wb, sheet     = paste ( "maps" , aspL[i] , sep = "" ) , rowNames = FALSE , colNames = TRUE , TEMP )
  }
  saveWorkbook  ( wb, file      = paste ( "../d0_3results/paper_codeAnalyses/paperAU_mapBuild_" , compare[comp] , "_v" , outVer, ".xlsx" , sep = ""  ) , overwrite = TRUE ) 
}  
rm ( wb , TE , TEM , TEMP , BLDv , i , comp )
