##   NZAu_TXcapacity_region_year.r  - buildout by year and scenario for all EER regions
##
##   Created:        7 February 2020 (NZA_VREcapacity)
##   Last updated:  19 January 2023
##
##   Changelog:
##            1. Remove 2020 starting values from all TXIR (done)
##            2. Force QLD port-domestic connection to Abbot Point (change TXIR crosswalk)
##            3. Fix QLD allocation issues in 2050/2055 (fixed problem in share allocations)
##   ToDo:

#-----0.ADMIN - Include libraries and other important-----------

##--A. Clean
setwd("C:/Users/uqapasca/workdeskUQ/NZAu/d0_2code")
source("clean.R")

##--B.Load Library for country manipulations
suppressMessages ( library ( "openxlsx"     , lib.loc=.libPaths() ) )      # worksheet functions
suppressMessages ( library ( "reshape2"     , lib.loc=.libPaths() ) )      # melt, dcast

#ver <- as.character ( Sys.Date() )

tenY <- 0
years <- c ( 2025 , 2030 , 2035 , 2040 , 2045 , 2050 , 2055 , 2060 )
if (tenY == 1 ) { years <- c ( 2030 , 2040 , 2050 , 2060 ) }

all     <- 1
sensi   <- 0
scens   <- c ( "eplus" , "eminus" , "re-const" , "re-plus" , "onshore" , "reference")
run     <- "2023_01_20s5a"
outVer  <- "Jan20a"
if ( sensi == 1 ) { scens <- c ( "cleanexport-minus"  , "drivers-minus" , "drivers-plus" , "eminus faster-emissions" , "eminus sequestration-plus" ,
                                 "eplus faster-emissions" , "eplus sequestration-plus" , "eplus-cheapnuke" , "eplus-distributedexport" , "eplus-remotecost" ,
                                 "export-minus" , "export-plus" , "fossil-plus" , "land-plus" , "onshore export-plus" ,             
                                 "re-const sequestration-minus" , "re-const-cheapnuke" , "re-const-distributedexport" , "re-const-nuke" , "re-const-remotecost" ,         
                                 "solar-minus" , "transmission-minus"  , "wacc-plus" )
if ( all == 1 ) { scens <- c ( "eplus" ,  "re-plus" , "re-const" , "eminus" , "onshore" , "reference" ,
                               "cleanexport-minus"  , "drivers-minus" , "drivers-plus" , "eminus faster-emissions" , "eminus sequestration-plus" ,
                               "eplus faster-emissions" , "eplus sequestration-plus" , "eplus-cheapnuke" , "eplus-distributedexport" , "eplus-remotecost" ,
                               "export-minus" , "export-plus" , "fossil-plus" , "land-plus" , "onshore export-plus" ,             
                               "re-const sequestration-minus" , "re-const-cheapnuke" , "re-const-distributedexport" , "re-const-nuke" , "re-const-remotecost" ,         
                               "solar-minus" , "transmission-minus"  , "wacc-plus" )}
}

life    <- 30

TXype   <- list ( c ( "electricity" ) ) #, c ( "electricity" , "hydrogen blend b" ) )

TXlabel <- c ( "ELE" ) #, "ELEH2")

#sel     <- 2

#-----END 0.ADMIN---------------



#-----1.HACK--------------------
over <- 1
for ( over in 1:(length (TXype ) ) ) {
  
  ##ZA. directionality
  FLO      <- read.csv ( paste ( "../d0_1source/EER/" , run , "/" , "direct_flows" , "_y.csv" , sep = "" ) , header=TRUE , stringsAsFactors = FALSE )
  FLOs           <- subset   ( FLO  , ( FLO$to %in% TXype[[over]] ) | ( FLO$from %in% TXype[[over]] ) )
  FLOs           <- subset   ( FLOs , ( !( FLOs$zone == FLOs$zone_to )  ) )
  FLOs$value     <- ifelse   ( paste ( FLOs$zone , "||" , FLOs$zone_to , "||electricity||1" , sep = "" ) == FLOs$from , FLOs$value , - FLOs$value )
  FLOw           <- dcast    ( FLOs , from + run.name ~ year , value.var = "value" , sum  )
  FLOh           <- melt ( FLOw , id.vars = c ( "from" , "run.name" ) , value.name = "value" , variable.name = "year" )
  FLOh$dir       <- ifelse ( FLOh$value  >= 0 , "fwd" , "bwd" )
  FLOh$name      <- gsub ( "electricity|h2" , "" , FLOh$from )
  FLOh           <- FLOh[, c ( "name" , "run.name" , "year" , "dir")]
  
  
  ##--A.read in EER capacity file and specify TX type
  EER         <- read.csv ( paste ( "../d0_1source/EER/" , run , "/tx_capacity_y.csv" , sep = "" ) , header=TRUE , stringsAsFactors = FALSE )
  EERsub      <- subset ( EER , ( EER$blend %in% TXype[[over]] ) )
  EERsub$name <- gsub ( "electricity|h2" , "" , EERsub$name )
  
  ##--B.gather two way data and estimate max Cap
  i <- 1 #debug
  for ( i in 1:( length ( unique ( EERsub$name ) ) ) ) {
    TE              <- subset ( EERsub , EERsub$name == unique ( EERsub$name )[i] )
#    TE$value        <- ifelse ( paste ( TE$zone , "||" , TE$zone_to , "||||1" , sep = "" ) == TE$name , TE$value , - TE$value )
    TEM             <- dcast ( TE , name + year + run.name ~ zone , value.var = "value" , sum  )
    names(TEM)[4:5] <- c ( "A" , "B" )
    TEM$capGW  <- pmax  ( TEM$A , TEM$B )
    TEM             <- merge ( TEM , FLOh , by = c ( "name" , "year" , "run.name" ) , all.x = TRUE )
    TEM             <- TEM[, c ( "name" , "year" , "run.name" , "capGW" , "dir" )]
    #added to remove starting values 19 Jan 2023
    minus     <- subset ( TEM$capGW , TEM$run.name == "eplus" & TEM$year == 2020 )
    TEM$capGW <- TEM$capGW - minus
    #end add
    if ( i == 1 ) { TX <- TEM }
    if ( i >  1 ) { TX <- rbind ( TX , TEM )}
  }
  

  ##--C.zone progression wide
  TXw                  <- dcast ( TX , name + run.name ~ year , value.var = "capGW" , sum  )
  TXw[3:ncol ( TXw )]  <- round ( TXw[3:ncol ( TXw )] , 3 ) 
#  TXw                  <- TXw[order ( TXw$run.name , TXw$name  , decreasing = c ( FALSE , FALSE ) ),] 
  
  
  ##significant
  TXw_                 <- subset ( TXw , TXw$`2060` > 0.1 )
  
  ##--D.Add GIS signifiers and divide totals in QLD, NT and WA appropriately to build
  ##add OBJECTIDs
  TXc             <- read.csv ( paste ( "../d0_1source/NZAU/t1_TXIRcrosswalk.csv" , sep = "" ) , header=TRUE , stringsAsFactors = FALSE , fileEncoding = "UTF-8-BOM"  )
  TXc             <- subset ( TXc , grepl ( "electricity" , TXc$name ) )
  TXc             <- TXc[,c ( "OBJECTID" , "name" , "exportPortName" , "Shape_Length" )]
  names ( TXc)    <- c ( "OBJECTID" , "name" , "exportPortName" , "length_km" )
  TXc$length_km   <- round ( TXc$length_km / 1e3 , 3 )
  TXc$name        <- gsub ( "electricity|h2" , "" , TXc$name )
  TX              <- merge ( TX , TXc , by = "name" , all.x = TRUE)
  
  ##do division by ports for each year
  VRE     <- read.csv ( paste ( "../d0_3results/Downscale/" , run , "/VRE/NZAu_" , "TXdownscale_" , "pv_" , outVer , ".csv" , sep = ""  ) , header=TRUE , stringsAsFactors = FALSE , fileEncoding = "UTF-8-BOM"  )
  VREb    <- read.csv ( paste ( "../d0_3results/Downscale/" , run , "/VRE/NZAu_" , "TXdownscale_" , "wind_" , outVer , ".csv" , sep = ""  ) , header=TRUE , stringsAsFactors = FALSE , fileEncoding = "UTF-8-BOM"  )
  VREc    <- read.csv ( paste ( "../d0_3results/Downscale/" , run , "/VRE/NZAu_" , "TXdownscale_" , "off_" , outVer , ".csv" , sep = ""  ) , header=TRUE , stringsAsFactors = FALSE , fileEncoding = "UTF-8-BOM"  )
  VRE     <- rbind ( VRE , rbind ( VREb , VREc ) )
  VRE     <- subset ( VRE , VRE$export == 1 & VRE$incap > ifelse ( VRE$type == "solar" , 0.005 , ifelse ( VRE$type == "onshore" , 0.05 , 0.100 ) ) )
  VRE$reg <- substr ( VRE$NZAu_maj , 4 , length ( VRE$NZAu_maj )  )
  #aggregate and proportion QLD, NT, and WA
  AGGr     <- aggregate ( incap ~ reg + run.name + year , VRE , FUN = sum )
  AGGp     <- aggregate ( incap ~ run.name + reg + year + exportPortName , VRE , FUN = sum )
  AGGp     <- merge ( AGGp , AGGr , by = c ( "run.name" , "reg" , "year" ) , all.x = TRUE )
  AGGp$shr <- AGGp$incap.x/AGGp$incap.y
  AGGp     <- AGGp[, c( "run.name" , "year" , "exportPortName" , "shr")]
  #names ( AGGp )[3] <- "exportPortName"
  #combine with TX
  TX        <- merge ( TX , AGGp , by = c ( "year" , "run.name" , "exportPortName" ) , all.x = TRUE )
  TX$shr    <- ifelse ( is.na ( TX$shr ) & substr ( TX$name , 1 , 2 ) == "ex" , 0 , ifelse ( is.na ( TX$shr ) , 1 , TX$shr ) )
  #TX$shr    <- ifelse ( is.na ( TX$shr ) , 1 , TX$shr )
  TX$capGW_ <- TX$capGW * TX$shr
  TX$gwkm   <- round ( TX$capGW_ * TX$length_km , 3 )
  TX$capMW  <- round ( TX$capGW_ * 1e3 , 3 ) 
  TX$export <- ifelse ( TX$exportPort == "" , 0 , 1 )
  
  
  #for H2
  TX$tjpd   <- round ( TX$capGW_ * 86.4 , 3 )
  
  #TX$exportPortName <- ifelse ( is.na( TX$ExportPort ) , TX$exportPortName , TX$ExportPort )
  TX           <- TX[, c ( "run.name" , "year" , "capGW_" , "OBJECTID" , "exportPortName" , "length_km" , "gwkm" , "capMW" , "tjpd" , "dir" , "export")]
  names ( TX ) <- c ( "run.name" , "year" , "capGW" , "OBJECTID" , "exportPort" , "length_km" , "gwkm" , "capMW" , "tjpd" , "Flowdir" , "export")
  
  rm ( VREb , VREc , VRE , AGGr , AGGp )
  
  #write for GIS join
  #i <- 1
  #j <- 6
  for ( i in 1:( length ( unique ( scens ) ) ) ) {
    for ( j in 1:( length ( unique ( years) ) ) ) { 
      temp <- subset ( TX , run.name == scens[i] & year == years[j] ) 
      write.csv ( temp , paste ( "../d0_3results/Downscale/" , run , "/VRE/" , scens[i] , "/NZAu_TXIR_" , scens[i] , "_" , years[j] , "_" , TXlabel[over] , "_" , outVer , ".csv" , sep = ""  ) , row.names = FALSE )
    }
  }
  
  ##--B. Save workbook for check
  wb            <- createWorkbook(creator = "AP")
  addWorksheet  ( wb, sheetName = paste ( "TXsummary" , sep = "" ) )
  writeData     ( wb, sheet     = paste ( "TXsummary" , sep = "" ) , rowNames = FALSE , colNames = TRUE , TXw_ )
  addWorksheet  ( wb, sheetName = paste ( "TXsummaryAll" , sep = "" ) )
  writeData     ( wb, sheet     = paste ( "TXsummaryAll" , sep = "" ) , rowNames = FALSE , colNames = TRUE , TXw )
  addWorksheet  ( wb, sheetName = paste ( "TXbothDir" , sep = "" ) )
  writeData     ( wb, sheet     = paste ( "TXbothDir" , sep = "" ) , rowNames = FALSE , colNames = TRUE , TX )
  saveWorkbook  ( wb, file      = paste ( "../d0_3results/Downscale/" , run , "/VRE/" , TXlabel[over] , "_TXIR" , ".xlsx" , sep = ""  ) , overwrite = TRUE  )
  
  rm ( wb , i , TE , EERsub , TXw , TXw_ , TEM , over )
}
