##   Supply Curve exploder
##
##   Created:        20 March 2024
##   03April2024:    modified to combine all individual supply curve runs before binning (P1) and then unpack binned VRE into
##   15June2024:     remove limits from output, add capex costs to outputs, added more digits to output
##
##   References:
##
##   ToDo:
##      

#-----0.ADMIN - Include libraries and other important-----------

##--A. Clean
setwd("X:/WORK/NZAu_LandUsePaper_MAIN/d0_2code/eer_supplycurves/v5")
source("clean.R")

##--B.Load Library for country manipulations
suppressMessages ( library ( "openxlsx"     , lib.loc=.libPaths() ) )      # worksheet functions
suppressMessages ( library ( "reshape2"     , lib.loc=.libPaths() ) )      # melt, dcast

#image print vars
wdth          <- 1920
hgth          <- 1080

#sc data in
aspect <- c ( "binned_resource_df" , "capacity_constraints" , "capacity_factors" , "tx_cost" , "capex_cost" )


ver <- 4

dfVer <- "9a"

#-----END 0.ADMIN---------------


#-----1.DISSAGREGATE--------------------

#INCAP
SC              <- read.csv  ( paste ( "final curves/" , aspect[1] , "_case" , dfVer , ".csv" , sep = ""  ) , header=TRUE , stringsAsFactors = FALSE )
SC              <- SC[, c ( 5 , 15 , 13 , 12 , 3 )]
SC$incap        <- round ( SC$incap / 1e3 , 5 )
names ( SC )[5] <- "incap_gW"
SCw                <- dcast ( SC,  NZAu_maj + type + bin_number ~ case , value.var = "incap_gW" , sum )

#format for 
names ( SCw )[4:7] <- c ( "NZAu_GW" , "Case1_GW" , "Case2_GW" , "Case3_GW" )
SCw[,4:7]          <- lapply ( SCw[,4:7] , function (x) round ( x , 3 ) )


CF              <- read.csv  ( paste ( "final curves/" , aspect[3] , "_nzau" ,  ".csv" , sep = ""  ) , header=TRUE , stringsAsFactors = FALSE )
CF              <- subset ( CF , vintage == "2020" )
CF              <- CF[, c ( 3 , 9 , 2  , 6 , 5 )]
CF$value        <- round ( CF$value , 3 )
names ( CF )[5] <- "cf_wLL_2020_nzau"
CFA              <- read.csv  ( paste ( "final curves/" , aspect[3] , "_case" , dfVer ,  ".csv" , sep = ""  ) , header=TRUE , stringsAsFactors = FALSE )
CFA              <- subset ( CFA , vintage == "2020" )
CFA              <- CFA[, c ( 3 , 9 , 2  , 6 , 5 )]
CFA$value        <- round ( CFA$value , 3 )
names ( CFA )[5] <- "cf_wLL_2020_rerun"
CFA              <- merge ( CF , CFA , by = names ( CFA )[1:4] , all = TRUE  )


TX                 <- read.csv ( paste ( "final curves/" , aspect[4] , "_nzau" ,  ".csv" , sep = ""  ) , header=TRUE , stringsAsFactors = FALSE )
TX                 <- TX[, c ( 2 , 5 , 1 , 4 , 3 )]
TX$tx_cost_per_kw  <- round ( TX$tx_cost_per_kw , 0 )
names ( TX )[5]    <- "tx_cost_per_kw_2021_nzau"
TXA                <- read.csv  ( paste ( "final curves/" , aspect[4] , "_case" , dfVer ,  ".csv" , sep = ""  ) , header=TRUE , stringsAsFactors = FALSE )
TXA                <- TXA[, c ( 2 , 5 , 1 , 4 , 3 )]
TXA$tx_cost_per_kw <- round ( TXA$tx_cost_per_kw , 0 )
names ( TXA  )[5]  <- "tx_cost_per_kw_2021_rerun"
TXA                <- merge ( TX , TXA , by = names ( TXA )[1:4] , all = TRUE  )

#offshore wind only
CAP                 <- read.csv ( paste ( "final curves/" , aspect[5] , "_nzau" ,  ".csv" , sep = ""  ) , header=TRUE , stringsAsFactors = FALSE )
CAP                 <- subset ( CAP , vintage == "2021" , select = c ( 2 , 6 , 1 , 5 , 4 ) )
CAP$capex_per_kw    <- round ( CAP$value , 3 )
names ( CAP )[6]    <- "capex_per_kw_2021_nzau"
CAP                 <- CAP[,-5]
CAPA                <- read.csv  ( paste ( "final curves/" , aspect[5] , "_case" , dfVer ,  ".csv" , sep = ""  ) , header=TRUE , stringsAsFactors = FALSE )
CAPA                <- subset ( CAPA , vintage == "2021" , select = c ( 2 , 6 , 1 , 5 , 4 ) )
CAPA$capex_per_kw   <- round ( CAPA$value , 3 )
names ( CAPA  )[6]  <- "capex_per_kw_2021_rerun"
CAPA                <- CAPA[,-5]
CAPA                <- merge ( CAP , CAPA , by = names ( CAPA )[1:4] , all = TRUE  )
#add PV and wind
CAP                 <- read.csv ( paste ( "../../../d0_1source/TECH_CAPITAL_COST.csv" , sep = ""  ) , header=TRUE , stringsAsFactors = FALSE )
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
EER                 <- read.csv ( paste ( "../../../d0_1source/capacity_y.csv" , sep = "" ) , header=TRUE , stringsAsFactors = FALSE , fileEncoding = "UTF-8-BOM" )
EER                 <- subset ( EER , ( EER$tech..type %in% c ( "fixed" ) & !( EER$zone == "export" ) & !( grepl ( "existing|rooftop" , EER$tech ) ) & EER$run.name == scenarios[s] ) ) # & EER$run.name %in% scens ) )  #this is just the generic export zone, not all export zones
EER$value           <- ifelse ( is.na ( EER$value ) , 0 , round ( EER$value  , 4 ) )
EERw                <- dcast  ( EER , tech + zone ~ year , value.var = "value" , sum )
names ( EERw )[1:2] <- c ( "name" , "NZAu_maj" )

FINA                <- merge ( SCF , EERw , by = c ( "NZAu_maj" , "name" ) , all = TRUE )


##nsw-central clean 15 August
FINA$NZAu_GW        <- ifelse ( FINA$NZAu_maj == "nsw-central" & FINA$name == "onshore wind|1" , FINA$`2050` , FINA$NZAu_GW )
FINA$Case1_GW       <- ifelse ( FINA$NZAu_maj == "nsw-central" & FINA$name == "onshore wind|1" , FINA$`2050` , FINA$Case1_GW )
FINA$Case2_GW       <- ifelse ( FINA$NZAu_maj == "nsw-central" & FINA$name == "onshore wind|1" , FINA$`2050` , FINA$Case2_GW )
FINA$Case3_GW       <- ifelse ( FINA$NZAu_maj == "nsw-central" & FINA$name == "onshore wind|1" , FINA$`2050` , FINA$Case3_GW )

#clean  14 August 2024
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

write.csv( FINB , file = paste ( "../../../d0_3results/bdpaper_tables/nzau_cases_" , labs[s] , "_wNzau_all_wCapex_v" , ver , ".csv" , sep = "" ) ,row.names = FALSE )

##combine and make columns for table E+ DIST EXPORT
s                   <- 2
scenarios           <- c ( "eplus" , "eplus-distributedexport" )
labs                <- c ( "ep" , "epde" )
EER                 <- read.csv ( paste ( "../../../d0_1source/capacity_y.csv" , sep = "" ) , header=TRUE , stringsAsFactors = FALSE , fileEncoding = "UTF-8-BOM" )
EER                 <- subset ( EER , ( EER$tech..type %in% c ( "fixed" ) & !( EER$zone == "export" ) & !( grepl ( "existing|rooftop" , EER$tech ) ) & EER$run.name == scenarios[s] ) ) # & EER$run.name %in% scens ) )  #this is just the generic export zone, not all export zones
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

write.csv( FIND , file = paste ( "../../../d0_3results/bdpaper_tables/nzau_cases_" , labs[s] , "_wNzau_all_wCapex_v" , ver , ".csv" , sep = "" ) ,row.names = FALSE )

