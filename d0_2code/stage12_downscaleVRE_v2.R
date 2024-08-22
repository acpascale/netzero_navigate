##   NZAu_Downscale_VREcapacity_region_year.r  - buildout by year and scenario and type for all EER regions
##
##   Created:        7 February 2020 (for NZA)
##   Last updated:  12 April 2024
##
##   was: t1_0a_NZAu_Downscale_VREcapacity_region_year_v4.R
##   followed by: 
##       t1_0b_NZAu_Downscale_TXIRcapacity_region_year_v3.R
##       t1_1_NZAu_Downscale_mappingMasterScript_v4.py
##       t1_2a_NZAu_Downscale_mapsPptx_Chris16160_pptxAnalyze.py
##       t1_2b_NZAu_Downscale_mapsPptx_Chris16160_pptxPopulate.py
##       
#-----0.ADMIN - Include libraries and other important-----------

##--A. Clean
setwd ( "C:/Users/uqapasca/workdeskUQ/NZAu/d0_2code" )
source ( "clean.R" )

##--B.Load Library for country manipulations
suppressMessages ( library ( "openxlsx"     , lib.loc=.libPaths() ) )      # worksheet functions
suppressMessages ( library ( "reshape2"     , lib.loc=.libPaths() ) )      # melt, dcast

tenY <- 0
years <- c ( 2025 , 2030 , 2035 , 2040 , 2045 , 2050 , 2055 , 2060 )
if (tenY == 1 ) { years <- c ( 2030 , 2040 , 2050 , 2060 ) }

test    <- 1
sensi   <- 0
all     <- 0
scens   <- c ( "eplus" ,  "re-plus" , "re-const" , "eminus" , "onshore" , "reference" )
if ( sensi == 1 ) { scens <- c ( "cleanexport-minus"  , "drivers-minus" , "drivers-plus" , "eminus faster-emissions" , "eminus sequestration-plus" ,
                                 "eplus faster-emissions" , "eplus sequestration-plus" , "eplus-cheapnuke" , "eplus-distributedexport" , "eplus-remotecost" ,
                                 "export-minus" , "export-plus" , "fossil-plus" , "land-plus" , "onshore export-plus" ,             
                                 "re-const sequestration-minus" , "re-const-cheapnuke" , "re-const-distributedexport" , "re-const-nuke" , "re-const-remotecost" ,         
                                 "solar-minus" , "transmission-minus"  , "wacc-plus" )}
if ( all == 1 ) { scens <- c ( "eplus" ,  "re-plus" , "re-const" , "eminus" , "onshore" , "reference" ,
                               "cleanexport-minus"  , "drivers-minus" , "drivers-plus" , "eminus faster-emissions" , "eminus sequestration-plus" ,
                                 "eplus faster-emissions" , "eplus sequestration-plus" , "eplus-cheapnuke" , "eplus-distributedexport" , "eplus-remotecost" ,
                                 "export-minus" , "export-plus" , "fossil-plus" , "land-plus" , "onshore export-plus" ,             
                                 "re-const sequestration-minus" , "re-const-cheapnuke" , "re-const-distributedexport" , "re-const-nuke" , "re-const-remotecost" ,         
                                 "solar-minus" , "transmission-minus"  , "wacc-plus" )}

if ( test == 1 ) { scens <- c ( "eplus" , "eplus-remotecost" ) }

regions <- c ( "nsw-central" , "nsw-north" , "nsw-outback" , "nsw-south" , "nt" , "qld-north" , "qld-outback" , "qld-south" , "sa" , "vic-west" ,
               "wa-south" , "tas" , "vic-east" , "wa-central" , "wa-north" , "ex-nt" , "ex-qld" , "ex-wa" , "ex-sa" , "ex-nsw" ) #, 
              # "port-nt" , "port-qld" , "port-wa" , "port-sa" , "port-nsw" )

run     <- "2023_01_20s5a"
outVer  <- "Jan20a"
supVer <- "Supply_v11_noSinkPopFilter_proRated_bulk330_proximityBased"

arrayDen <- c ( 45 , 2.7 , 4.4 )

wVer   <- paste ( "wind" , "_AP_v4_all_pd" , "2_7" , sep = "" ) 
pVer   <- paste ( "pv"   , "_AP_v4_all_pd" , "45" , sep = "" )
oVer   <- paste ( "off"  , "_AP_v4_all_pd" , "4_4" , sep = "" )

life  <- 30

#-----END 0.ADMIN---------------


#-----1.HACK--------------------

##--A1.  read in EER capacity file and remove all but VRE (and remove existing and rooftop)
EER         <- read.csv ( paste ( "../d0_1source/EER/" , run , "/capacity_y.csv" , sep = "" ) , header=TRUE , stringsAsFactors = FALSE , fileEncoding = "UTF-8-BOM" )
EERvre      <- subset ( EER , ( EER$tech..type %in% c ( "fixed" ) & !( EER$zone == "export" ) & EER$run.name %in% scens ) )  #this is just the generic export zone, not all export zones
#unique ( EERvre$run.name )

##--A2. load RIO to GIS crosswalk and identify crossovers with potential sites
EXIS             <- read.xlsx ( paste ( "../d0_1source/NZAU/t1_VREcrosswalk_fin.xlsx" , sep = "" ) , sheet = 4 ,  startRow = 1 , colNames = TRUE ,  skipEmptyRows = TRUE , skipEmptyCols = TRUE  ) 
names ( EXIS )[ which ( names ( EXIS ) == "Technology" )] <- "type"
names ( EXIS )[ which ( names ( EXIS ) == "OBJECTID" )]   <- "OID"
EXIS$type        <- ifelse ( EXIS$type == "Wind" , "onshore" , "solar" )

#add wind and pv CPAs that have more than 5% crossover
EXIw             <- read.csv ( paste ( "../d0_3results/supplyCurve/" , wVer , "_cpa.csv" , sep = "" ) , header = TRUE , stringsAsFactors = FALSE , fileEncoding = "UTF-8-BOM"  )
EXIwi            <- EXIw[, c ( "OIDwind" , "m_windOld_maj" , "m_windOld_cov" , "m_cf_noloss" )]
names ( EXIwi )  <- c ( "OBJECTID" , "OID" , "COV" , "CF" )
EXIp             <- read.csv ( paste ( "../d0_3results/supplyCurve/" , pVer , "_cpa.csv" , sep = "" ) , header = TRUE , stringsAsFactors = FALSE , fileEncoding = "UTF-8-BOM"  )
EXIpv            <- EXIp[, c ( "OIDpv" , "m_pvOld_maj" , "m_pvOld_cov" , "m_cf_noloss" )]
names ( EXIpv )  <- c ( "OBJECTID" , "OID" , "COV" , "CF" )
EXIa             <- rbind ( EXIwi , EXIpv )
EXIb             <- subset ( EXIa , !is.na ( EXIa$OID ) & EXIa$COV > 0.1 , select = c ( 1:4 )  )
EXIS             <- merge ( EXIS , EXIb , by = c ( "OID" ) , all = TRUE )
#EXIb             <- subset ( EXIa , !is.na ( EXIa$OID ) & !duplicated ( EXIa$OID ) , select = c ( 2 , 4 )  )
#EXIS             <- merge ( EXIS , EXIb , by = c ( "OID" ) , all = TRUE )
rm ( EXIwi , EXIpv , EXIa , EXIb )
#adjust capacities
EXIS$incap       <- EXIS$capacity * ifelse ( EXIS$OID %in% EXIS$OID[which ( duplicated ( EXIS$OID ) )] & !is.na ( EXIS$COV ) , 0.5 , 1 ) 


##--B2.read in supply curve, order by LCC and combine with relevant attributes from B3, then combine with existing
EERsc   <- read.csv ( paste ( "../d0_1source/EER/" , run , "/finalCurves/binned_resource_df.csv" , sep = "" ) , header=TRUE , stringsAsFactors = FALSE , fileEncoding = "UTF-8-BOM"  )

##--Add in LCC column for ordering/selection -- need to remove any sensitivities
eerTCC             <- read.csv ( paste ( "../d0_2code/eer_rio_db_au/database/Supply/Supply Techs/" , "TECH_CAPITAL_COST.csv" , sep = "" ) , header=TRUE , stringsAsFactors = FALSE , fileEncoding = "UTF-8-BOM"  )
eerTCCa            <- subset ( eerTCC , grepl ( "solar|wind" , eerTCC$name ) & 
                                 !grepl ( "rooftop" , eerTCC$name ) & !( eerTCC$source == "NREL 2020 ATB" ) & 
                                 !( grepl ( "offshore" , eerTCC$name ) ) & !( eerTCC$sensitivity %in% c ( "solar-" , "2x WACC" ) ) )
if ( tenY == 1) { eerTCCa <- subset ( eerTCCa , !vintage %in% c ( 2025 , 2035 , 2045 , 2055 ) ) }  
eerTCCa            <- dcast ( eerTCCa , name + cost_of_capital ~ vintage  )
eerTCCa$type       <- ifelse ( grepl ( "solar" , eerTCCa$name ) , "solar" , "onshore" )
eerTCCa$bin_number <- substr ( eerTCCa$name , nchar ( eerTCCa$name ) , nchar ( eerTCCa$name ) )
eerTCCa            <- eerTCCa[,-1]
EERsc_a            <- merge ( EERsc , eerTCCa , by = c ( "type" , "bin_number" )  )
rm ( eerTCCa  )  

eerTCCb              <- subset ( eerTCC , grepl ( "offshore" , eerTCC$name ) & ( eerTCC$source == "NREL 2020 ATB" ) & eerTCC$vintage %in% c ( 2021 , years ) & grepl ( "depth" , eerTCC$sensitivity ) )
eerTCCb              <- dcast ( eerTCCb , name + cost_of_capital + gau ~ vintage  )
names ( eerTCCb )[3] <- "NZAu_maj"
eerTCCb$type         <- "offshore" 
eerTCCb$bin_number   <- substr ( eerTCCb$name , nchar ( eerTCCb$name ) , nchar ( eerTCCb$name ) )
eerTCCb              <- eerTCCb[,-1]
EERsc_b              <- merge ( EERsc , eerTCCb , by = c ( "type" , "bin_number" , "NZAu_maj" ) )
EERsc_b              <- EERsc_b[, c ( "type" , "bin_number" , "file_name" , "OBJECTID" , "incap" , "CF_wLL" , "NZAu_maj" , 
                                      names ( EERsc_b)[8:ncol(EERsc_b)] )] # c ( 1:2 , 4:7 , 3 , 8:21 )]

##--estimate sLCC
##https://www.nrel.gov/analysis/tech-lcoe-documentation.html
##https://en.wikipedia.org/wiki/Capital_recovery_factor
##sLCOE = {(overnight capital cost * capital recovery factor + fixed O&M cost )/(8760 * capacity factor)} 
##fixed O&M cost is currently zero
#int        <- .03  #assumed to check against cost of capital in EER file
#n          <- 30 #book life from eerTCC
#crf        <- ( int * ( 1 + int )^ n ) / ( ( 1 + int )^ n - 1 )
EERsc                                                      <- rbind ( EERsc_a , EERsc_b )
names ( EERsc )[( ncol ( EERsc ) - ifelse ( tenY == 1 , 3 , 6 ) ):( ncol ( EERsc ) )] <- paste ( "trend_" , names ( EERsc )[( ncol ( EERsc ) - ifelse ( tenY == 1 , 3 , 6 ) ):( ncol ( EERsc ) )] , sep = "" )
EERsc$sLCC                                                 <- ( ( EERsc$trend_2021 + EERsc$tx_cost_per_kw )  * EERsc$cost_of_capital ) / ( 8760 * EERsc$CF_wLL )
rm ( EERsc_a , EERsc_b , eerTCCb , eerTCC )

EERpv              <- subset ( EXIp , EXIp$OBJECTID %in% subset ( EERsc$OBJECTID , EERsc$type == "solar"   ) , select = c ( "OBJECTID" , "d_hwy" , "d_sink" , "d_air" , "m_cyclone" , "m_REZ_maj" , "m_landuse_maj" , "m_locMult" , "Area"  ) )
EERwi              <- subset ( EXIw , EXIw$OBJECTID %in% subset ( EERsc$OBJECTID , EERsc$type == "onshore" ) , select = c ( "OBJECTID" , "d_hwy" , "d_sink" , "d_air" , "m_cyclone" , "m_REZ_maj" , "m_landuse_maj" , "m_locMult" , "Area"  ) )
EERof              <- read.csv ( paste ( "../d0_3results/supplyCurve/" , oVer  , "_cpa.csv" , sep = "" ) , header = TRUE , stringsAsFactors = FALSE , fileEncoding = "UTF-8-BOM" )
EERof              <- subset ( EERof , EERof$OBJECTID %in% subset ( EERsc$OBJECTID , EERsc$type == "offshore" ) , select = c ( "OBJECTID" , "d_hwy" , "d_sink" , "d_air" , "m_cyclone" , "m_REZ_maj" , "m_landuse_maj" , "m_locMult" , "Area" ) )
EERpv$type         <- "solar"
EERwi$type         <- "onshore"
EERof$type         <- "offshore"
EERsc              <- merge ( EERsc , rbind ( EERpv , rbind ( EERwi , EERof ) ) , by = c ( "OBJECTID" , "type" ) , all.x = TRUE )
rm ( EXIp , EXIw , EERwi , EERpv , EERof )
EERsc                  <- merge ( EERsc , EXIS[, c ( "type" , "operating_year" , "retirement_year" , "retirement_year" , "OBJECTID" , "plant" )] , 
                                  by = c ( "OBJECTID" , "type"  ) , all.x = TRUE )  
names ( EERsc )[which ( names ( EERsc ) == "operating_year" ):(which ( names ( EERsc ) == "operating_year" ) + 2 )] <- c ( "built" , "avail" , "retire" )
EERsc$built        <- NA
EERsc$retire       <- NA
EERsc$avail        <- ifelse ( is.na ( EERsc$avail ) , years[1] , EERsc$avail + 1 )


##--A2. MAKE TABLES in 5 year increments for each tech type - by region
#debug
#j <- 1
TEM   <- list ()
for ( j in 1:length ( regions ) ) {
  TE       <- subset ( EERvre , EERvre$zone == ( regions[j] ) )
  if ( nrow ( TE ) > 0 ) {
    if ( min ( TE$year ) > 2020 ) {
      TT <- data.frame ( TE[1,])
      TT$year  <- 2020
      TT$value <- 0
      TE <- rbind ( TE , TT )
    }
  }
  ##need to adjust ouput if considering ports (what to do with empty casts ?)
  TEM[[j]] <- dcast  ( TE , zone + tech + run.name + unit ~ year , value.var = "value" , sum ) 
}
#rm ( j , TE , TT )


##--B3.make build schedule for new CPAs only, old sites will be retired ONLY using existing VRE data set
#debug
j <- 1
i <- 1

#order
EERsc              <- EERsc[order ( EERsc$sLCC  , decreasing = FALSE ),]  
#set up containers
ALL <- list ()
DIS <- list ()
PROB <- data.frame()
for ( i in 1:length ( TEM ) ) {
  BU       <- TEM[[i]]                                          #BUILD
  SU       <- subset ( EERsc , EERsc$NZAu_maj == BU$zone[1] )     #SUPPLY
  SU$incap <- SU$incap / 1e3
  for ( j in 1:length ( scens ) ) {  ##number of scenarios
    #nSU            <- SU
    #for regions with no existing builds in region/scenario -- need to create dummy PROJa
    #if ( nrow ( subset ( BU , BU$run.name == unique ( BU$run.name )[j] & !( grepl ("rooftop" , BU$tech ) ) & ( grepl ("existing" , BU$tech ) )  ) ) == 0 ) {
    #  PROJa <- subset ( nSU , OBJECTID == 0 )
    #}
    BUI             <- subset ( BU , BU$run.name == scens[j] & !( grepl ("existing|rooftop" , BU$tech ) ) )
    BUI$bin_number  <- ifelse ( grepl ( "existing" , BUI$tech ) , 0 , as.numeric ( substr( BUI$tech , nchar ( BUI$tech ) , nchar ( BUI$tech ) ) ) )
    BUI$type        <- ifelse ( grepl ("offshore" , BUI$tech ) , "offshore" , ifelse ( grepl ( "onshore" , BUI$tech ) , "onshore" , "solar" ) )
    #BUI$type       <- ifelse ( grepl ( "existing" , BUI$tech ) & BUI$type == "solar" , "existing PV" , ifelse ( grepl ( "existing" , BUI$tech ) & BUI$type == "onshore" , "existing wind" , BUI$type ) )
    
    k<-5
    for ( k in 1:nrow ( BUI ) ) {   ##number of technologies
      SUP           <- subset ( SU , SU$type == BUI$type[k] & SU$bin_number == BUI$bin_number[k] )
      SUP$incapT    <- SUP$incap
      SUP$incapTB   <- 0
      BUIL          <- data.frame ( built   = names ( BUI )[( which ( names ( BUI ) == years[1] ) ):( which ( names ( BUI ) == "2060" ) )] ,
                                   incapCum = unlist ( BUI[k,( which ( names ( BUI ) == years[1] ) ):( which ( names ( BUI ) == "2060" ) )] ) )
      #remove solver noise (helps when hit the cap in bins) and track when happens
      #get rid of any categories with less than 100 MW of capacity (arbitrary)
      #BUIL$maxPrior <- cumsum ( BUIL$incapCum )
      #BUIL$incapCum <- ifelse ( BUIL$incapCum < 0.1 &  BUIL$maxPrior < 0.1 , 0 , BUIL$incapCum )
      #BUIL          <- BUIL[,-ncol ( BUIL )]
      if ( max ( BUIL$incapCum ) >= sum ( SUP$incap ) ) { 
        PRO           <- BUI[k,]
        PRO$supCap    <- sum ( SUP$incap )
        PROB          <- rbind ( PROB , PRO  )
      }
      #rm ( PRO )
      BUIL$incapCum <- round ( floor ( BUIL$incapCum * 1e3 ) / 1e3 , 3 )
      
      #remove projects at site of existing projects
      EXI           <- subset ( SUP , SUP$avail > years[1] )
      if ( nrow ( EXI ) > 0 ) {
        EXI$incapCumT <- 0
        EXI$incapCumB <- 0
        EXI$incapB    <- 0
      }
      SUP           <- subset ( SUP , SUP$avail == years[1] )
      
      m<-1
      for ( m in 1:length ( years ) ) {
        #handle retirements
        RE                                 <- subset ( SUP , SUP$retire == years[m] )
        if ( m >  1 )  { RET <- rbind ( RET , RE ) }
        if ( m == 1 )  { RET <- RE }
        SUP$avail[SUP$retire == years[m]]  <- NA
        SUP$avail[is.na ( SUP$built )]     <- years[m]
        SUPa                               <- subset ( SUP , !( is.na ( SUP$avail ) ) & !( is.na ( SUP$built ) ) )
        SUPb                               <- subset ( SUP , !( is.na ( SUP$avail ) ) &  ( is.na ( SUP$built ) ) )
        #copy retired projects to beginning of queue and remove built
          if ( nrow ( RE ) > 0 ) {
          RE$avail  <- years[m-1]
          RE$retire <- NA
          RE$built  <- NA
        }
        #add in projects at existing sites that have been retired
        REE       <- subset ( EXI , EXI$avail <= years[m] )
        EXI       <- subset ( EXI , !( EXI$avail <= years[m] ) )
        REE$avail <- REE$avail - 1  
        RE        <- rbind ( RE , REE )
        rm ( REE )
        
        SUP      <- rbind ( SUPa  , RE   )
        #SUP      <- rbind ( SUP   , subset ( PROJb , PROJb$bin_number == BUI$bin_number[k] & PROJb$avail == years[m] )   )
        SUP      <- rbind ( SUP   , SUPb )
        #reorder and cumsum
        SUP           <- SUP[order ( SUP$built , SUP$avail , SUP$sLCC  , decreasing = c ( FALSE , FALSE , FALSE ) ),]
        SUP$incapCumT <- cumsum ( SUP$incap )
        if ( nrow ( SUP ) > 1 ) { SUP$incapCumB <- c ( 0 , SUP$incapCumT[1:( nrow ( SUP ) - 1 )] ) }
        if ( nrow ( SUP ) < 2 ) { SUP$incapCumB <- 0 }
        #full build
        SUP$built  <- ifelse ( is.na ( SUP$built )  & SUP$incapCumT <= BUIL$incapCum[m] , years[m] , SUP$built )
        #partial build
        SUP$built  <- ifelse ( is.na ( SUP$built )  & SUP$incapCumT > BUIL$incapCum[m] & SUP$incapCumB < BUIL$incapCum[m] , years[m] , SUP$built )
        SUP$incapB <- ifelse ( is.na ( SUP$built ) , 0 , BUIL$incapCum[m] )
        SUP$incapB <- ifelse ( SUP$incapB > SUP$incapCumB , ifelse ( SUP$incapB - SUP$incapCumB > SUP$incap , SUP$incap , SUP$incapB - SUP$incapCumB ) , NA )
        #duplicate row if partial build and zero out remaining row as unbuilt
        SUPd             <- subset ( SUP , round ( SUP$incapB , 3 ) < round ( SUP$incap , 3) )
        SUPd$Area        <- SUPd$Area * ( 1 - SUPd$incapB / SUPd$incap )
        SUPd$incap       <- SUPd$incap - SUPd$incapB
        if ( nrow ( SUPd ) > 0 ) {
          SUPd$built       <- NA 
          SUPd$incapB      <- NA
          SUP$Area         <- ifelse ( SUP$OBJECTID == SUPd$OBJECTID , SUP$Area * SUP$incapB / SUP$incap , SUP$Area )
          SUP$incap        <- ifelse ( SUP$OBJECTID == SUPd$OBJECTID , SUP$incapB , SUP$incap )
        }
        #add row in correct place and redo cums?
        SUPa             <- rbind ( subset ( SUP , !is.na ( SUP$built ) ) , SUPd )
        SUP              <- rbind ( SUPa , subset ( SUP , is.na ( SUP$built ) ) )
        #add retirement date
        SUP$retire <- SUP$built + life
        #estimate cumulatives
        SUP$incapCumT <- cumsum ( SUP$incap )
        if ( nrow ( SUP ) > 1 ) { SUP$incapCumB <- c ( 0 , SUP$incapCumT[1:( nrow ( SUP ) - 1 )] ) }
        if ( nrow ( SUP ) < 2 ) { SUP$incapCumB <- 0 }
      }
      if ( nrow ( RET ) > 0 ) { RET$incapCumT <- 0 }
      SUP <- rbind ( RET , SUP )
      SUP <- subset ( SUP , !( is.na ( SUP$built ) ) )
      rm ( SUPa , SUPb , SUPd , RET , RE , EXI )
      
      #aggregate partial builds
      AGG  <- SUP
      p <- 2 #debug
      for ( p in 1:( length ( years ) ) ) {
        AG            <- subset ( AGG , AGG$built <= years[p] & AGG$retire > years[p] , select = c ( 1:ncol ( AGG ) ) )
        if ( nrow ( AG ) > 0 ) {
          A             <- aggregate ( incap ~ OBJECTID , AG , FUN = sum )
          AG            <- subset ( AG , !duplicated ( AG$OBJECTID ) )
          AG            <- AG[,-(which ( names ( AG ) == "incap" ) )]
          AG$year       <- years[p]
          AG            <- merge ( AG , A , by = "OBJECTID" , all.x = TRUE )
          AG$TincapYear <- sum ( A$incap )
          AG$Area       <- ( AG$incap * 1e3 ) / ifelse ( AG$type == "solar" , arrayDen[1] , ifelse ( AG$type == "onshore" , arrayDen[2] , arrayDen[3] ) )
          #assumes a square in area geometry... may nto be right for all
          AG$BUFF       <- - ( ( sqrt ( AG$incapT * 1e3  /  ifelse ( AG$type == "solar" , arrayDen[1] , ifelse ( AG$type == "onshore" , arrayDen[2] , arrayDen[3] ) ) / ifelse ( AG$type == "solar" , 5 , 1 ) ) ) - sqrt ( AG$Area ) )
        }
        if ( nrow ( AG ) == 0 ) { AG  <- AG[,-(which ( names ( AG ) == "incap" ) )] }
        if ( p == 1 ) { ARC <- AG   }
        if ( p >  1 ) { ARC <-  rbind ( ARC , AG ) }
      }
      rm ( AGG , AG , p )
      
      #save in containers
      if ( k == 1 ) { 
        BUILD   <- SUP 
        DISPLAY <- ARC
      }
      if ( k  > 1 ) { 
        BUILD  <- rbind ( BUILD   , SUP )
        DISPLAY <- rbind ( DISPLAY , ARC)
        }
    }
    if ( nrow ( BUILD > 0 ) ) {
      BUILD$run.name    <- scens[j]
      DISPLAY$run.name  <- scens[j]
      if ( j == 1 ) { 
        BUILDS   <- BUILD 
        DISPLAYS <- DISPLAY 
      }
      if ( j  > 1 ) { 
        BUILDS   <- rbind ( BUILDS , BUILD ) 
        DISPLAYS <- rbind ( DISPLAYS , DISPLAY )
      }
    }
  }
  ALL[[i]] <- BUILDS
  DIS[[i]] <- DISPLAYS
}

##for downscale by type
for ( i in 1:length ( ALL ) ) {
  if ( i == 1 ) { 
    b <- ALL[[i]]
    d <- DIS[[i]]
    }
  if ( i >  1 ) { 
    b <- rbind ( b , ALL[[i]] )
    d <- rbind ( d , DIS[[i]] ) 
    }
}

##--E. Save workbook for broad results
wb            <- createWorkbook(creator = "AP")
addWorksheet  ( wb, sheetName = paste ( "EERSupplyCurve_wExist" , sep = "" ) )
writeData     ( wb, sheet     = paste ( "EERSupplyCurve_wExist" , sep = "" ) , rowNames = FALSE , colNames = TRUE , EERsc )
addWorksheet  ( wb, sheetName = paste ( "ExistingVRE" , sep = "" ) )
writeData     ( wb, sheet     = paste ( "ExistingVRE" , sep = "" ) , rowNames = FALSE , colNames = TRUE , EXIS )
addWorksheet  ( wb, sheetName = paste ( "SupplyCurveProbs" , sep = "" ) )
writeData     ( wb, sheet     = paste ( "SupplyCurveProbs" , sep = "" ) , rowNames = FALSE , colNames = TRUE , PROB )
for ( i in 1:length ( TEM ) ) {
  a <- TEM[[i]]
  addWorksheet  ( wb, sheetName = paste ( a$zone[1] , sep ="" ) )
  writeData     ( wb, sheet     = paste ( a$zone[1] , sep ="" )    , rowNames = FALSE , colNames = TRUE , a )
}
saveWorkbook  ( wb, file      = paste ( "../d0_3results/Downscale/" , run , "/VRE/NZAu_" , "upscale_" , outVer , ifelse (tenY == 1 , "_tenY" , "") ,  ".xlsx" , sep = ""  ) , overwrite = TRUE  )

##--F. Save workbook for downscale _ by region
wb            <- createWorkbook(creator = "AP")
addWorksheet  ( wb, sheetName = paste ( "EERSupplyCurve_wExist" , sep = "" ) )
writeData     ( wb, sheet     = paste ( "EERSupplyCurve_wExist" , sep = "" ) , rowNames = FALSE , colNames = TRUE , EERsc )
addWorksheet  ( wb, sheetName = paste ( "ExistingVRE" , sep = "" ) )
writeData     ( wb, sheet     = paste ( "ExistingVRE" , sep = "" ) , rowNames = FALSE , colNames = TRUE , EXIS )
for ( i in 1:length ( ALL ) ) {
  a <- ALL[[i]]
  addWorksheet  ( wb, sheetName = paste ( "build_" , a$NZAu_maj[1] , sep ="" ) )
  writeData     ( wb, sheet     = paste ( "build_" , a$NZAu_maj[1] , sep ="" )    , rowNames = FALSE , colNames = TRUE , a )
}
for ( i in 1:length ( DIS ) ) {
  a <- DIS[[i]]
  addWorksheet  ( wb, sheetName = paste ( "display_" , a$NZAu_maj[1] , sep ="" ) )
  writeData     ( wb, sheet     = paste ( "display_" , a$NZAu_maj[1] , sep ="" )    , rowNames = FALSE , colNames = TRUE , a )
}
saveWorkbook  ( wb, file      = paste ( "../d0_3results/Downscale/" , run , "/VRE/NZAu_" , "downscale_byReg_" , outVer , ifelse (tenY == 1 , "_tenY" , "") ,  ".xlsx" , sep = ""  ) , overwrite = TRUE  )

##--G. Save workbook for downscale _ by type
wb            <- createWorkbook(creator = "AP")
addWorksheet  ( wb, sheetName = paste ( "EERSupplyCurve_wExist" , sep = "" ) )
writeData     ( wb, sheet     = paste ( "EERSupplyCurve_wExist" , sep = "" ) , rowNames = FALSE , colNames = TRUE , EERsc )
addWorksheet  ( wb, sheetName = paste ( "ExistingVRE" , sep = "" ) )
writeData     ( wb, sheet     = paste ( "ExistingVRE" , sep = "" ) , rowNames = FALSE , colNames = TRUE , EXIS )
addWorksheet  ( wb, sheetName = paste ( "display_" , unique ( d$type )[1] , sep ="" ) )
writeData     ( wb, sheet     = paste ( "display_" , unique ( d$type )[1] , sep ="" )    , rowNames = FALSE , colNames = TRUE , subset ( d , d$type == unique ( d$type )[1] ) )
addWorksheet  ( wb, sheetName = paste ( "display_" , unique ( d$type )[2] , sep ="" ) )
writeData     ( wb, sheet     = paste ( "display_" , unique ( d$type )[2] , sep ="" )    , rowNames = FALSE , colNames = TRUE , subset ( d , d$type == unique ( d$type )[2] ) )
addWorksheet  ( wb, sheetName = paste ( "display_" , unique ( d$type )[3] , sep ="" ) )
writeData     ( wb, sheet     = paste ( "display_" , unique ( d$type )[3] , sep ="" )    , rowNames = FALSE , colNames = TRUE , subset ( d , d$type == unique ( d$type )[3] ) )
addWorksheet  ( wb, sheetName = paste ( "build_"   , unique ( b$type )[1] , sep ="" ) )
writeData     ( wb, sheet     = paste ( "build_"   , unique ( b$type )[1] , sep ="" )    , rowNames = FALSE , colNames = TRUE , subset ( b , b$type == unique ( b$type )[1] ) )
addWorksheet  ( wb, sheetName = paste ( "build_"   , unique ( b$type )[2] , sep ="" ) )
writeData     ( wb, sheet     = paste ( "build_"   , unique ( b$type )[2] , sep ="" )    , rowNames = FALSE , colNames = TRUE , subset ( b , b$type == unique ( b$type )[2] ) )
addWorksheet  ( wb, sheetName = paste ( "build_"   , unique ( b$type )[3] , sep ="" ) )
writeData     ( wb, sheet     = paste ( "build_"   , unique ( b$type )[3] , sep ="" )    , rowNames = FALSE , colNames = TRUE , subset ( b , b$type == unique ( b$type )[3] ) )
saveWorkbook  ( wb, file      = paste ( "../d0_3results/Downscale/" , run , "/VRE/NZAu_" , "downscale_byType_" , outVer , ifelse (tenY == 1 , "_tenY" , "") , ".xlsx" , sep = ""  ) , overwrite = TRUE  )

##write csvs
write.csv ( subset ( d , d$type == unique ( d$type )[1] ) , paste ( "../d0_3results/Downscale/" , run , "/VRE/" , unique ( d$type )[1]  , "_" , outVer , ifelse (tenY == 1 , "_tenY" , "") , ".csv" , sep = ""  ) , row.names = FALSE   )
write.csv ( subset ( d , d$type == unique ( d$type )[2] ) , paste ( "../d0_3results/Downscale/" , run , "/VRE/" , unique ( d$type )[2]  , "_" , outVer , ifelse (tenY == 1 , "_tenY" , "") , ".csv" , sep = ""  ) , row.names = FALSE   )
write.csv ( subset ( d , d$type == unique ( d$type )[3] ) , paste ( "../d0_3results/Downscale/" , run , "/VRE/" , unique ( d$type )[3]  , "_" , outVer , ifelse (tenY == 1 , "_tenY" , "") , ".csv" , sep = ""  ) , row.names = FALSE   )


rm ( wb , i , j , k , m , SU , SUP , BU , BUI , BUIL , BUILD , BUILDS , a , DISPLAY , DISPLAYS , ARC , PROB , A , PRO )

##--H. TX apportioning (tie into above scripts or?)
types <- c ( ifelse ( unique ( d$type )[1] == "solar" , "pv" , ifelse ( unique ( d$type )[1] == "onshore" , "wind" , "off" ) ) ,
             ifelse ( unique ( d$type )[2] == "solar" , "pv" , ifelse ( unique ( d$type )[2] == "onshore" , "wind" , "off" ) ) ,
             ifelse ( unique ( d$type )[3] == "solar" , "pv" , ifelse ( unique ( d$type )[3] == "onshore" , "wind" , "off" ) ) )

rm (b,d)
i<-1 #debug
for ( i in 1:length ( types ) ) {
  #get downscale display
  DWN   <- read.xlsx ( paste ( "../d0_3results/Downscale/" , run , "/VRE/NZAu_" , "downscale_byType_" , outVer , ifelse (tenY == 1 , "_tenY" , "") , ".xlsx" , sep = ""  ) , sheet = 2 + i ,  startRow = 1 , colNames = TRUE ,  skipEmptyRows = TRUE , skipEmptyCols = TRUE  ) 
  #get supply curves (full not simple)
  fSUP  <- read.xlsx ( paste ( "../d0_3results/SupplyCurve/" , types[i] , supVer , ".xlsx" , sep = ""  ) , sheet = 3 ,  startRow = 1 , colNames = TRUE ,  skipEmptyRows = TRUE , skipEmptyCols = TRUE  )
  #trim to just TX display vars
  fSUP           <- fSUP[,c ( "OBJECTID" , "subOID" , "spurOID" , "bulkOID" , "sinkOID" , "exportOID"  , "spurLength_km" , 
                              "bulkLength_km" , "sinkLength_km" , "exportLength_km" , "exportPortName" ,  "SA2oid" , "bin" )]
  fSUP$bulkOID   <- ifelse ( fSUP$bin == 1 & !is.na ( fSUP$bulkOID ) , as.numeric( fSUP$bulkOID )   , 0 )
  fSUP$sinkOID   <- ifelse ( ( fSUP$bin == 2 | fSUP$bin == 3 ) & !is.na ( fSUP$sinkOID ), as.numeric ( fSUP$sinkOID )  , 0 )
  #fSUP$sinkOID   <- as.numeric ( fSUP$sinkOID ) ##does not work on export??
  fSUP$exportOID <- ifelse ( fSUP$bin == 4 , fSUP$exportOID , 0 )
  fSUP$spurOID   <- ifelse ( fSUP$bin == 4 , 0 , fSUP$spurOID )
  fSUP$subOID    <- ifelse ( fSUP$bin == 4 , 0 , fSUP$subOID  )
  fSUP           <- fSUP[, -ncol ( fSUP )]
  #merge TX display vars with downscaling display
  DWN   <- merge ( DWN , fSUP , by = "OBJECTID" , all.x = TRUE )
  #adjust export ports
  DWN$exportPortName  <- ifelse ( DWN$export == 0 , NA , DWN$exportPortName )
  #txBuild years
  DWN$spurExsubYear   <- DWN$year
  DWN$sinkBulkYear    <- ifelse ( DWN$year == 2025 , 2025 , DWN$year - 5 )  
  #save TX downscaling file
  write.csv ( DWN , paste ( "../d0_3results/Downscale/" , run , "/VRE/NZAu_" , "TXdownscale_" , types[i] , "_" , outVer , ifelse (tenY == 1 , "_tenY" , "") , ".csv" , sep = ""  ) , row.names = FALSE )
}
rm ( i , fSUP )

i <- 1
j <- 1 
k <- 1 
for ( i in 1:( length ( types ) ) ) {
  DWN   <- read.csv ( paste ( "../d0_3results/Downscale/" , run , "/VRE/NZAu_" , "TXdownscale_" , types[i] , "_" , outVer , ifelse (tenY == 1 , "_tenY" , "") ,  ".csv" , sep = ""  ) , header = TRUE , stringsAsFactors = FALSE , fileEncoding = "UTF-8-BOM"  )
  for ( j in 1:( length ( scens ) ) ) {
    if ( file.exists ( paste ( "../d0_3results/Downscale/" , run , "/VRE/" , scens[j] , sep = "" ) ) == FALSE ) {
      dir.create ( file.path ( paste ( "../d0_3results/Downscale/" , run , "/VRE/" , sep = "" ) , scens[j] ) ) 
    }
    for ( k in 1: length ( years ) ) {
      TEM <- subset ( DWN , year == years[k] & run.name == scens[j] )
      write.csv ( TEM , paste ( "../d0_3results/Downscale/" , run , "/VRE/" , scens[j] , "/NZAu_VRE_" , scens[j] , "_" , types[i] , "_" , years[k] , "_" , outVer , ifelse (tenY == 1 , "_tenY" , "") , ".csv" , sep = ""  ) , row.names = FALSE )
    }
  }
}

#TEM   <- read.csv ( paste ( "../d0_3results/Downscale/" , run , "/VRE/" , scens[4] , "/NZAu_VRE_" , scens[4] , "_" , types[1] , "_" , years[8] , "_" , outVer , ".csv" , sep = ""  ) , header = TRUE , stringsAsFactors = FALSE , fileEncoding = "UTF-8-BOM"  )
#length ( unique ( TEM$OBJECTID ) )
rm ( i , j , k , TEM )

##for checking of islanding
LOD           <- read.csv  ( paste ( "../d0_1source/NZAU/t1_destLoad.csv" , sep = "" ) , header = TRUE , stringsAsFactors = FALSE , fileEncoding = "UTF-8-BOM") 
LOD           <- LOD[, c ( 6 , 10 , 9 , 2  )]
names ( LOD ) <- c ( "SA2oid" , "name" , "type" , "population" )
for (i in 1:length (  scens ) ) {
  LODE <- LOD
  LODE$run.name <- scens[i]
  if ( i == 1 ) {    LODES <- LODE }
  if ( i > 1  ) { LODES <- rbind ( LODES , LODE ) }
}
DWNa           <- read.csv ( paste ( "../d0_3results/Downscale/" , run , "/VRE/NZAu_" , "TXdownscale_" , "pv" , "_" , outVer , ifelse (tenY == 1 , "_tenY" , "") ,  ".csv" , sep = ""  ) , header = TRUE , stringsAsFactors = FALSE , fileEncoding = "UTF-8-BOM"  )
DWNa           <- subset ( DWNa , incap >= 0.005 , select = c ( 1:13 , 23:ncol(DWNa)) )
DWNb           <- read.csv ( paste ( "../d0_3results/Downscale/" , run , "/VRE/NZAu_" , "TXdownscale_" , "wind" , "_" , outVer , ifelse (tenY == 1 , "_tenY" , "") ,  ".csv" , sep = ""  ) , header = TRUE , stringsAsFactors = FALSE , fileEncoding = "UTF-8-BOM"  )
DWNb           <- subset ( DWNb , incap >= 0.050 , select = c ( 1:13 , 23:ncol(DWNb)) )
DWNc           <- read.csv ( paste ( "../d0_3results/Downscale/" , run , "/VRE/NZAu_" , "TXdownscale_" , "off" , "_" , outVer , ifelse (tenY == 1 , "_tenY" , "") ,  ".csv" , sep = ""  ) , header = TRUE , stringsAsFactors = FALSE , fileEncoding = "UTF-8-BOM"  )
DWNc           <- subset ( DWNc , incap >= 0.100 , select = c ( 1:13 , 23:ncol(DWNc)) )
DWN            <- rbind ( DWNa , rbind ( DWNb , DWNc ) )
DWN$yyear      <- paste ( "y" , DWN$year , sep = "" )
DET            <- dcast ( DWN , SA2oid + run.name ~ yyear , value.var = "incap" , sum )
DET$SA2oid     <- ifelse ( is.na ( DET$SA2oid ) , 210 , DET$SA2oid )
SPLY           <- merge ( LODES , DET , by = c ( "SA2oid" , "run.name" ) , all.x = TRUE )
SPLY$population<- ifelse ( is.na( SPLY$population ) , 1 , SPLY$population )
#SPLY$run.name  <- ifelse ( is.na( SPLY$run.name ) , "unused" , SPLY$run.name )
SPLY$name      <- ifelse ( SPLY$name == "" , "TBD" , SPLY$name )
SPLY[is.na(SPLY)]<- 0 
SPLY[6:( ncol( SPLY ))] <- apply ( SPLY[6:( ncol( SPLY ))] , 2 , function (x) round ( x , 3 ) ) 
SPLY$load      <- ifelse ( SPLY$type == "export" , 3 , ifelse ( SPLY$type == "sink" , 1 , 2 ) )
SPLY$kwpp               <- round ( ( SPLY$y2060 * 1e6 )/SPLY$population  , 1 )
names ( SPLY )   <- c ( "OBJECTID" , "scenario" , "name" , "type" , "pop" , names ( SPLY )[6:ncol ( SPLY ) ] )
i<-1
for ( i in 1:length(scens)) {
  TEM <- subset ( SPLY , scenario %in% c ( scens[i] , "unused" ) )
  write.csv ( TEM , paste ( "../d0_3results/Downscale/" , run , "/VRE/island/Chk_" , scens[i] , "_" , outVer , ifelse (tenY == 1 , "_tenY" , "") , ".csv" , sep = ""  ) , row.names = FALSE )
}
