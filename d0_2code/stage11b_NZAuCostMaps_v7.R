##   Supply Curve exploder
##
##   Created:        13 August 2024
##   Last updated:   13 August 2024 compare binned outputs and place on map 
##
##   References:
##
##   NOTES:
##           -- wish to keep year builds instead of "unsolve",  need row flag

#-----0.ADMIN - Include libraries and other important-----------

##--A. Clean
setwd("X:/WORK/NZAu_LandUsePaper_MAIN/")
source("d0_2code/clean.R")

##--B.Load Library for country manipulations
suppressMessages ( library ( "openxlsx"     , lib.loc=.libPaths() ) )      # worksheet functions
suppressMessages ( library ( "reshape2"     , lib.loc=.libPaths() ) )      # melt, dcast

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

ver                <- 4 # from previous step
version            <- 8
compare            <- "case2"


#-----END 0.ADMIN---------------

#-----FUNCTIONS---------

#-----END FUNCTIONS---------------

#-----1.HACK--------------------

####COSTS PREP STARTS####

##NZAu costs prepare
AUD2020_AUD2021      <- 1.026
USD2019_AUD2021      <- (255.7988/254.2227) * 1.452 * AUD2020_AUD2021  # (255.7988/249.703) *

#on project costs
TCC                  <- read.csv ( paste ( "d0_1source/TECH_CAPITAL_COST.csv" , sep = "" ) , header=TRUE , stringsAsFactors = FALSE , fileEncoding = "UTF-8-BOM"  )
TCCa                 <- subset ( TCC , grepl ( "wind|solar" , TCC$name ) & ( TCC$vintage %in% years ) & !grepl ( "rooftop" , TCC$name ) & !grepl ( "offshore" , TCC$name ) & !( TCC$source == "NREL 2020 ATB" )   & ( TCC$sensitivity == "2022 ISP [d]" ) ) # & ( TCC$vintage == TCCvin )
TCCb                 <- melt ( TCCa , id.vars = c ( "name" , "gau" , "vintage" ) , measure.vars = "value" , value.name = "AUD2021.kW" )
TCCb$AUD2021.kW      <- TCCb$AUD2021.kW * AUD2020_AUD2021
TCCc                 <- dcast ( TCCb , name + gau ~ vintage , value.var = "AUD2021.kW" , fun.aggregate = sum )
TCCc$'2055'          <- TCCc$'2050'
TCCc$'2060'          <- TCCc$'2050'
ONv                  <- melt ( TCCc , id.vars = 1 , measure.vars = 3:10 , variable.name = "year" , value.name = "CapC_aud2021")
#off project costs original
TCCa                 <- subset ( TCC , grepl ( "offshore" , TCC$name ) & ( TCC$vintage %in% years ) & ( TCC$source == "NREL 2020 ATB" ) & ( TCC$sensitivity == "ATB2020 Moderate w depth adjustment [d]")  )
TCCb                 <- melt   ( TCCa , id.vars = c ( "name" , "gau" , "vintage" ) , measure.vars = "value" , value.name = "AUD2021.kW" )
TCCb$AUD2021.kW      <- TCCb$AUD2021.kW * USD2019_AUD2021
TCCd                 <- dcast  ( TCCb , name + gau ~ vintage , value.var = "AUD2021.kW" , fun.aggregate = sum )
TCCd$'2055'          <- TCCd$'2050'
TCCd$'2060'          <- TCCd$'2050'
OFv                  <- melt ( TCCd , id.vars = 1:2 , measure.vars = 3:10 , variable.name = "year" , value.name = "CapC_aud2021")
names ( OFv )[2]     <- "NZAu_maj"
rm ( TCCd , TCCa , TCCb , TCCc , TCC )
##off project costs new
OFC                 <- read.csv  ( paste ( "d0_2code/eer_supplycurves/v5/final curves/" , "capex_cost" , "_case" , 9 ,  ".csv" , sep = ""  ) , header=TRUE , stringsAsFactors = FALSE )
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

#costOcapVRE          <- TCCa$cost_of_capital[1]
#this could be pulled out of the relevant EER file, but has been hard coded here to save time (perhaps on a re-write)
#costOcapTX           <- 0.021
##crfs also have hard coded lifespans which might be pulled from relevant EER file or other
#crfVRE               <- ( costOcapVRE * ( 1 + costOcapVRE )^30 ) / (( 1 + costOcapVRE )^30 - 1 )
#crfTX                <- ( costOcapTX  * ( 1 + costOcapTX  )^50 ) / (( 1 + costOcapTX  )^50 - 1 )

###offshore wind TX learning curve
TXC                  <- read.csv ( paste ( "d0_1source/" , "NEW_TECH_TX_COST.csv" , sep = "" ) , header=TRUE , stringsAsFactors = FALSE , fileEncoding = "UTF-8-BOM"  )
TXC                  <- subset ( TXC , grepl ( "off" , TXC$name ) )
TXClc                <- subset ( TXC , TXC$gau == "ex-wa" & grepl ( "1" , TXC$name ) & ( TXC$vintage %in% c ( 2021 , years ) ) )
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
  EPA         <- read.csv  ( paste ( "d0_3results/bdpaper_tables/nzau_cases_" , labs[c] , "_wNzau_all_wCapex_v" , ver , ".csv" , sep = "" ) , header=TRUE , stringsAsFactors = FALSE )
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


##get percent differencs
#names(BLDw)[which (names(BLDw) == comapre)]
BLDw$pNr <- round ( 100 * ( BLDw$nzauR - BLDw$nzauO ) / BLDw$nzauO , 2 ) 
BLDw$pC1 <- round ( 100 * ( BLDw$case1 - BLDw[,which (names(BLDw) == compare)] ) / BLDw[,which (names(BLDw) == compare)] , 2 )
BLDw$pC2 <- round ( 100 * ( BLDw$case2 - BLDw[,which (names(BLDw) == compare)] ) / BLDw[,which (names(BLDw) == compare)] , 2 )
BLDw$pC3 <- round ( 100 * ( BLDw$case3 - BLDw[,which (names(BLDw) == compare)] ) / BLDw[,which (names(BLDw) == compare)] , 2 )

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
  write.csv( TEMP   , file = paste ( "d0_3results/bdpaper_tables/___BDmap_" , compare , "_v" , version , "_" , aspL[i]  , ".csv" , sep = "" ) ,row.names = FALSE )
  addWorksheet  ( wb, sheetName = paste ( "maps" , aspL[i] , sep = "" ) )
  writeData     ( wb, sheet     = paste ( "maps" , aspL[i] , sep = "" ) , rowNames = FALSE , colNames = TRUE , TEMP )
}
saveWorkbook  ( wb, file      = paste ( "d0_3results/bdpaper_tables/___BDmap_paperBuild_" , compare , "_v" , version , ".xlsx" , sep = ""  ) , overwrite = TRUE ) 
rm ( wb , TE , TEM , TEMP , BLDv , i  )
