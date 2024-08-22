##   stage9_Supply_domesticExport.r  - 
##
##   Created:       15 Jul 2021
##   Last updated:  20 August 2024
##
##    20/08/2024: Final adjustments for paper pre: cleaning, code documentation, and ease-of-use changes
##    27/03/2024: made adjustments for line losses in capacity factors in LCOE estimations (not to CF itself as done by EER SC code)
##    25/03/2024: cumulative updates since last entry: added TX learning curve for OSW, updated LCC/LCOE formula (Dom D thanks), fixed bugs in ispAdj for sink lines (Yimin G thanks) and in OSW SA/WA 
##      carvout code that led to random OSW capacity being removed from curve (Yimin G thanks!); added code to use regional capital cost of OSW in LCOE estimates rather than national average, this also
##      comes with code that converts the OSW costs to AUD from USD (Yimin G thanks for identifying this lack); changed notation of CF to indicate inclusion of project losses
##    21/02/2024: updated csv import to work with Stage 8 output of re-written MapRE+ code (renaming this script as Stage9); commented out unused variables; using capital costs from EER DB
##      made loop so can handle multiple resource+cases at once
##    08/11/2022: fixed onshore cost adjustment (for length); fixed problem with and overcosting of any site with a cf > 50% (offshore sites); moved all substations on longer length lines to remove transformers (like project substations)
##      moved to pro-rated cost lengths rather than straight lengths; added adelaide 100km radius for domestic; re-combined bulk and spur for total TX cost
##    19/12/2022: added SA2 in curve tracking

##    TODO: 
##      1. add in names for 140 load regions and 58 'cities'

#-----0.ADMIN - Include libraries and other important-----------

##--A. Clean
setwd("X:/WORK/NZAu_LandUsePaper_MAIN/d0_2code")
source("clean.R")


##--B.Load Library for country manipulations
suppressMessages ( library ( "openxlsx"     , lib.loc=.libPaths() ) )      # worksheet functions
suppressMessages ( library ( "reshape2"     , lib.loc=.libPaths() ) )      # melt, dcast

##--C. Global var

outVer    <- paste ( "v6" , "_bdpaper" , sep = "" )    #13 will be paper and repository version
noPOPfilt <- 1 ##this allows all projects cut due to MW limits on an individual MSA to re-enter supply curve as SINK projects

wbYes     <- 1  #workbook output? 1 = yes

newVer    <- "6"  #5 is paper version #6 will be repository version  (exclusion flatmaps come from v6 GDB)  #not used!

inVers <- c ( "pv_v6_all_pd45d0_B8_case0"    , "pv_v6_all_pd45d0_B8_case1"   ,  "pv_v6_all_pd45d0_B8_case2"   , "pv_v6_all_pd45d0_B8_case3"   , 
              "wind_v6_all_pd2d7_B8_case0"   , "wind_v6_all_pd2d7_B8_case1"  ,  "wind_v6_all_pd2d7_B8_case2"  , "wind_v6_all_pd2d7_B8_case3"  ,
              "off_v6_all_pd4d4_B8_case0"    , "off_v6_all_pd4d4_B8_case1"   ,  "off_v6_all_pd4d4_B8_case2"   , "off_v6_all_pd4d4_B8_case3"   )

#cutoffs for viability of onshore and offshore projects (set by Ryan based on his experience)
onCut    <- 150  
offCut   <- 200

resShare <- 30 ##this allows 30 kw of each resource per person 

CapYear  <- 2021

TCCvin   <- ifelse ( CapYear > 2050 , 2050 , CapYear )

lcoe.year <- 2050

#km.mile  <- 1.609344
#max_line_length <- 250              #length an HVAC line can run before needs a 'repeater' substation
#sub_line_length <- 100 * km.mile    #distance at which a repeater substation is required afterwords

#txLine   <- c (   164                       ,  127                       ,  102                      ,  118                        ,  96                         ,  91            ) #,  84           )
txType   <- c (  "132kV_HVAC_double__250MW" , "275kV_HVAC_single__400MW" , "330kV_HVAC_single__600MW", "275kV_HVAC_double__950MW"  , "330kV_HVAC_double__1200MW" , "500kV_HVAC_double__3040MW" ) #, "500kV HVDC"  )
txCost   <- c (   1.128035219               ,  1.270456199               , 1.468728911               ,  1.563153611                ,  1.794163760                ,  2.541917739   ) #,  2.016549603  )
txMax    <- c (   250                       ,  400                       ,  600                      ,  950                        ,  1200                       ,  3040          ) #,  3000         )
txSub    <- c (   28.12677782               ,  36.42644659               ,  40.69867072              ,  53.36373185                ,  61.83194120                ,  70.37738600   ) #,  632.76374964 )
txSubp   <- c (   20.85177782               ,  23.05644659               ,  23.44767072              ,  26.62373185                ,  27.32994120                ,  34.87538600   ) #,  597.26174964 )
trans330 <- c (   0.02425000                ,  0.02674000                ,  0                        ,  0.02674000                 ,  0                          ,  0   )

bulkAdj     <- 0.5 #adjust bulk TX cost by portion of a line with diverse uses on it
#projLife    <- 30 #(for LCC and plots against energy)
txloss.ac   <- 0.621371/100 #per 100 km - for LCC (Loss factors on electricity are 1% per 100 miles for AC and 0.5% per 100 miles for DC plus 3% conversion losses
txloss.dc   <- 0.621371/200   ##dc not adjusted for onshore yet.. all in AC ... these are adjusted for offshore
convLoss.dc <- 0.03   ##dc not adjusted for onshore yet.. all in AC... these are adjusted for offshore

pvGrossUp   <- 1.15

#transOnly <-( 13.370*2 )

##offshore specific
##capex specific, can be removed if not considering capex
floatPD   <- 4.4 #only used for capex (not part of my job)
fixedPD   <- 4.4 #only used for capex (not part of my job)
typeTrans <- -60  #NREL ATB 2021  #only used for capex (not part of my job)

##tx OFSHORE specific

###offshore wind TX learning curve
TXC                  <- read.csv ( paste ( "../d0_1source/" , "NEW_TECH_TX_COST.csv" , sep = "" ) , header=TRUE , stringsAsFactors = FALSE , fileEncoding = "UTF-8-BOM"  )
TXC                  <- subset ( TXC , grepl ( "off" , TXC$name ) )
TXClc                <- subset ( TXC , TXC$gau == "ex-wa" & grepl ( "1" , TXC$name ) )
TXClc$mult           <- TXClc$value / subset ( TXClc$value , TXClc$vintage == 2021 )
vinOffMult           <- subset ( TXClc$mult , TXClc$vintage == TCCvin )
rm ( TXC , TXClc )

##vinOffMult is applied to txOffCost, txOffSub, txOffSubp.. but not to land costs where no learning curve is expected
txOffType <- c ( "500kv_HVDC_single_subsea__375MW" , "500kV_HVDC_double_subsea__750MW" , "500kV_HVDC_double_subsea__1500MW" , "500kV_HVDC_2xdouble_subsea__2250MW" , "500kV_HVDC_2xdouble_subsea__3000MW" )
txOffCost <- c (  1.076707758                     ,  1.922778756                     ,  3.157886952                      , 1.922778756 + 3.157886952           ,  3.157886952 * 2 ) 
txOffMax  <- c (  375                             ,  750                             ,  1500                             , 2250                                ,  3000 )
txOffSub  <- c (  152.51897642                    ,  272.36754410                    ,  447.32443140                     , 272.36754410 + 447.32443140         ,  447.32443140  * 2 ) 
txOffSubp <- c (  140.41427495                    ,  250.75103521                    ,  411.82243140                     , 250.75103521 + 411.82243140         ,  411.82243140  * 2 )
txOffland <- c (  1.076707758                     ,  1.421162134                     ,  1.721320357                      , 2.016549603                         ,  2.016549603 )

#ISP adjustments
ADJ           <- read.xlsx ( paste ( "../d0_1source/" , "2021-09-28-NZAu_TXmodel_wMults.xlsx" , sep = ""  ) , sheet = 2 ,  startRow = 16 , colNames = TRUE ,  skipEmptyRows = TRUE , skipEmptyCols = TRUE  ) ##list of countries/regions from incoming data that are not handled by countrycode package and replacement codes if/any

#-----END 0.ADMIN---------------


#-----1.HACK--------------------

v <- 2 #d#
for (v in 1:( length ( inVers ) ) ) {
  inVer <- inVers[v]
  case  <- substr ( inVer , nchar ( inVer ) , nchar ( inVer ) )
  resource <- gsub ( "\\_.*" , "" , inVer )
  print ( paste ( "Starting supply curve creation for " , inVer , " for year " , CapYear , sep = "" ) )
  
  ##--A. Get combined site data from new stage8 and clean
  CPA                <- read.csv  ( paste ( "../d0_3results/biodiversity/" , inVer , ".csv" , sep = "" ) , header = TRUE , stringsAsFactors = FALSE , fileEncoding = "UTF-8-BOM" )
  CPA                <- CPA[, - c ( which ( names ( CPA ) == "OBJECTID_1" ) , which ( names ( CPA ) == "OIDcom_12" ) , which ( names ( CPA ) == "Shape_Length_12" ) ,  which ( names ( CPA ) == "Shape_Length_12_13" ) ,  which ( names ( CPA ) == "Shape_Length" ) ,  which ( names ( CPA ) == "Shape_Area" ) )  ]
  names ( CPA )[ ( which ( names ( CPA ) == "type" ) )]   <- "resource"
  names ( CPA )[ ( which ( names ( CPA ) == "nzau" ) )]   <- "subNzau"
  CPA$bulkCost       <- ifelse ( CPA$sub2SA2_m == 0      , 0                  , CPA$bulkCost )
  CPA$bulkSA2aggOID  <- ifelse ( CPA$sub2SA2_m == 0      , CPA$subSA2aggOID  , CPA$bulkSA2aggOID )
  CPA$bulkSA2aggPOP  <- ifelse ( CPA$sub2SA2_m == 0      , CPA$subSA2aggPOP  , CPA$bulkSA2aggPOP )
  CPA$bulkLength_m   <- ifelse ( CPA$sub2SA2_m == 0      , 0                  , CPA$bulkLength_m )
  CPA$sinkCost       <- ifelse ( is.na ( CPA$sinkOID )   , 0                  , CPA$sinkCost )
  CPA$sinkSA2oid     <- ifelse ( is.na ( CPA$sinkOID )   , CPA$subSA2aggOID  , CPA$sinkSA2oid )
  CPA$sinkSA2pop     <- ifelse ( is.na ( CPA$sinkOID )   , CPA$subSA2aggPOP  , CPA$sinkSA2pop )
  CPA$sinkLength_m   <- ifelse ( is.na ( CPA$sinkOID )   , 0                  , CPA$sinkLength_m )
  CPA$exportCost     <- ifelse ( is.na ( CPA$exportOID ) , 0                  , CPA$exportCost )
  
  ##added to better reflect layer
  #CPA$m_cf_noloss    <- CPA$m_cf_noloss
  #CPA                <- CPA[, - c ( which ( names ( CPA ) == "m_cf_noloss" ) ) ]
  
  if ( resource == "off" ) { CPA$m_popden <- 0 }
  
  ## remove any site without a spur line and note problem in problem column
  CPAp                 <- subset ( CPA , is.na ( CPA$spurOID ) )
  CPAg                 <- subset ( CPA , !is.na ( CPA$spurOID ) )
  CPAp$problem         <- ifelse ( is.na ( CPAp$spurOID ) , "(arcGis) Spur line not drawn as centrepoint of the project sits on a subtation and that subtation was not added to bulk/sink processing - can be fixed if needed" )
  
  #supply curve attributes - real lengths
  CPAg$spurLength_km                                           <- CPAg$spurLength_m / 1e3
  CPAg$bulkLength_km                                           <- CPAg$bulkLength_m / 1e3 
  CPAg$sinkLength_km                                           <- CPAg$sinkLength_m / 1e3 
  CPAg$landfallLength_km                                       <- ifelse ( CPAg$resource == "off" , ifelse ( is.na ( CPAg$landfallLength_m ) , 0 , CPAg$landfallLength_m / 1e3 ) , 0 )
  CPAg$onshoreLength_km                                        <- ifelse ( CPAg$resource == "off" , ( CPAg$spurLength_km - CPAg$landfallLength_km ) , CPAg$spurLength_km )
  CPAg$onshoreLength_km[CPAg$onshoreLength_km < 0]             <- 0
  CPAg$exportLength_km                                         <- ifelse ( is.na (CPAg$exportLength_m ) , 0 , CPAg$exportLength_m / 1e3 )
  CPAg$exportLandfallLength_km                                 <- ifelse ( CPAg$resource == "off" , ifelse ( is.na ( CPAg$exportLandfallLength_m ) , 0 , CPAg$exportLandfallLength_m / 1e3 ) , 0 )
  CPAg$exportOnshoreLength_km                                  <- ifelse ( CPAg$resource == "off" , ( CPAg$exportLength_km - CPAg$exportLandfallLength_km ) , CPAg$exportLength_km )
  CPAg$exportOnshoreLength_km[CPAg$exportOnshoreLength_km < 0] <- 0
  CPAg$filter                                                  <- "none"
  
  #pro-rated cost-lengths
  CPAg$landfallCost                                   <- ifelse ( CPAg$resource == "off" , ifelse ( is.na ( CPAg$landfallCost ) , 0 , CPAg$landfallCost ) , 0 )
  CPAg$onshoreCost                                    <- ifelse ( CPAg$resource == "off" , ( CPAg$spurCost - CPAg$landfallCost ) , CPAg$spurCost )
  CPAg$onshoreCost[CPAg$onshoreCost < 0]              <- 0
  CPAg$exportLandfallCost                             <- ifelse ( CPAg$resource == "off" , ifelse ( is.na ( CPAg$exportLandfallCost ) , 0 , CPAg$exportLandfallCost) , 0 )
  CPAg$exportOnshoreCost                              <- ifelse ( CPAg$resource == "off" , ( CPAg$exportCost - CPAg$exportLandfallCost ) , CPAg$exportCost )
  CPAg$exportOnshoreCost[CPAg$exportOnshoreCost < 0]  <- 0
  
  ##PROJECT GENERATION AND CAPITAL COSTS (KEPT FOR GRAPHS) -- BUT NOT SENT TO RIO. RIO ESTIMATES ITS OWN CAPITAL COSTS BASED ON YEAR FIELDED, LEARNING CURVES, ETC
  #generation over one year (no capacity factor derating , no leap day )
  CPAg$egenADJ      <- CPAg$incap *  8760 * CPAg$m_cf_noloss * ifelse ( CPAg$resource == "pv" , pvGrossUp , 1 ) 
  
  ##this was originally envisioned as a GIS later which would incorporate regional differences, etc
  TCC                  <- read.csv ( paste ( "../d0_1source/" , "TECH_CAPITAL_COST.csv" , sep = "" ) , header=TRUE , stringsAsFactors = FALSE , fileEncoding = "UTF-8-BOM"  )
  TCCa                 <- subset ( TCC , grepl ( "wind" , TCC$name )  & !grepl ( "offshore" , TCC$name ) & !( TCC$source == "NREL 2020 ATB" ) & ( TCC$vintage == lcoe.year )  & ( TCC$sensitivity == "2022 ISP [d]" ) )
  costOcapVRE          <- TCCa$cost_of_capital[1]
  #this could be pulled out of the relevant EER file, but has been hard coded here to save time (perhaps on a re-write)
  costOcapTX           <- 0.021
  ##crfs also have hard coded lifespans which might be pulled from relevant EER file or other
  crfVRE               <- ( costOcapVRE * ( 1 + costOcapVRE )^30 ) / (( 1 + costOcapVRE )^30 - 1 )
  crfTX                <- ( costOcapTX  * ( 1 + costOcapTX  )^50 ) / (( 1 + costOcapTX  )^50 - 1 )
  
  CPAg$m_capWin_maj    <- mean ( subset ( TCC$value , grepl ( "wind" , TCC$name )  & !grepl ( "offshore" , TCC$name ) & !( TCC$source == "NREL 2020 ATB" ) & ( TCC$vintage == lcoe.year )  & ( TCC$sensitivity == "2022 ISP [d]" ) ) ) 
  CPAg$m_capPV_maj     <- mean ( subset ( TCC$value , grepl ( "solar" , TCC$name ) & !grepl ( "rooftop" , TCC$name ) & !( TCC$source == "NREL 2020 ATB" ) & ( TCC$vintage == lcoe.year )  & ( TCC$sensitivity == "2022 ISP [d]" ) ) )
  CPAg$m_capOff_maj    <- 3621.3661  #mean ( subset ( TCC$value , grepl ( "offshore" , TCC$name ) & ( TCC$source == "NREL 2020 ATB" ) & ( TCC$vintage == lcoe.year ) & ( TCC$sensitivity == "ATB2020 Moderate") ) )
  
  AUD2020_AUD2021      <- 1.026
  USD2019_AUD2021      <- (255.7988/254.2227) * 1.452 * AUD2020_AUD2021  # (255.7988/249.703) * 
  
  if ( resource == "off" ) {
    CPAg$incap                <- ifelse ( CPAg$m_elev < typeTrans , CPAg$incap / fixedPD *floatPD , CPAg$incap )
    #CPAg$m_capOff_maj         <-   #sapply ( CPAg$subNzau , function (x) mean ( subset ( TCC$value , grepl ( "offshore" , TCC$name ) & ( TCC$source == "NREL 2020 ATB" ) & ( TCC$vintage == lcoe.year ) & ( TCC$sensitivity == "ATB2020 Moderate w depth adjustment [d]") & ( TCC$gau == x  ) ) ) )
    CPAg$m_capOff_maj         <- CPAg$m_capOff_maj * USD2019_AUD2021
    CPAg$CAPEX_maud2021       <- ( CPAg$incap * 1000 * CPAg$m_capOff_maj * CPAg$m_WinMult * CPAg$m_locMult / 1e4) / 1e6
  }
  if ( resource == "wind" ) { 
    CPAg$CAPEX_maud2021  <- ( CPAg$incap * 1000 * CPAg$m_capWin_maj * CPAg$m_WinMult * CPAg$m_locMult / 1e4 ) * AUD2020_AUD2021 / 1e6 
    }
  if ( resource == "pv" )   { 
    CPAg$CAPEX_maud2021  <- ( CPAg$incap * 1000 * CPAg$m_capPV_maj  * CPAg$m_PvMult  * CPAg$m_locMult / 1e4 ) * AUD2020_AUD2021 / 1e6 
  }
  
  rm ( TCC, TCCa )
  
  ##AEMO TX linelength  multipliers
  if ( resource == "off" ) {
    CPAg$ispADJspurLength <- as.numeric ( ifelse ( CPAg$spurLength_km < 1 , ADJ[3,22] , 
                                                   ifelse ( CPAg$spurLength_km >= 1   & CPAg$spurLength_km < 5    , ADJ[3,23]  , 
                                                            ifelse ( CPAg$spurLength_km >= 5   & CPAg$spurLength_km < 10   , ADJ[3,24]  , 
                                                                     ifelse ( CPAg$spurLength_km >= 10  & CPAg$spurLength_km < 100  , ADJ[3,25]  , 
                                                                              ifelse ( CPAg$spurLength_km >= 100 & CPAg$spurLength_km < 200  , ADJ[3,26]  , ADJ[3,27] ) ) ) ) ) )
    CPAg$ispADJbulkLength <- as.numeric ( ifelse ( CPAg$bulkLength_km < 1 , ADJ[3,22] , 
                                                   ifelse ( CPAg$bulkLength_km >= 1   & CPAg$bulkLength_km < 5    , ADJ[3,23]  , 
                                                            ifelse ( CPAg$bulkLength_km >= 5   & CPAg$bulkLength_km < 10   , ADJ[3,24]  , 
                                                                     ifelse ( CPAg$bulkLength_km >= 10  & CPAg$bulkLength_km < 100  , ADJ[3,25]  , 
                                                                              ifelse ( CPAg$bulkLength_km >= 100 & CPAg$bulkLength_km < 200  , ADJ[3,26]  , ADJ[3,27] ) ) ) ) ) )
    CPAg$ispADJsinkLength <- as.numeric ( ifelse ( CPAg$sinkLength_km < 1 , ADJ[3,22] , 
                                                   ifelse ( CPAg$sinkLength_km >= 1   & CPAg$sinkLength_km < 5    , ADJ[3,23]  , 
                                                            ifelse ( CPAg$sinkLength_km >= 5   & CPAg$sinkLength_km < 10   , ADJ[3,24]  , 
                                                                     ifelse ( CPAg$sinkLength_km >= 10  & CPAg$sinkLength_km < 100  , ADJ[3,25]  , 
                                                                              ifelse ( CPAg$sinkLength_km >= 100 & CPAg$sinkLength_km < 200  , ADJ[3,26]  , ADJ[3,27] ) ) ) ) ) )
    CPAg$ispADJexportLength <- as.numeric ( ifelse ( CPAg$exportLength_km < 1 , ADJ[3,22] , 
                                                     ifelse ( CPAg$exportLength_km >= 1   & CPAg$exportLength_km < 5    , ADJ[3,23]  , 
                                                              ifelse ( CPAg$exportLength_km >= 5   & CPAg$exportLength_km < 10   , ADJ[3,24]  , 
                                                                       ifelse ( CPAg$exportLength_km >= 10  & CPAg$exportLength_km < 100  , ADJ[3,25]  , 
                                                                                ifelse ( CPAg$exportLength_km >= 100 & CPAg$exportLength_km < 200  , ADJ[3,26]  , ADJ[3,27] ) ) ) ) ) )
  }
  
  if ( ! ( resource == "off" ) ) {
    CPAg$ispADJspurLength <- as.numeric ( ifelse ( CPAg$spurLength_km < 1 , ADJ[2,22] , 
                                                   ifelse ( CPAg$spurLength_km >= 1   & CPAg$spurLength_km < 5    , ADJ[2,23]  , 
                                                            ifelse ( CPAg$spurLength_km >= 5   & CPAg$spurLength_km < 10   , ADJ[2,24]  , 
                                                                     ifelse ( CPAg$spurLength_km >= 10  & CPAg$spurLength_km < 100  , ADJ[2,25]  , 
                                                                              ifelse ( CPAg$spurLength_km >= 100 & CPAg$spurLength_km < 200  , ADJ[2,26]  , ADJ[2,27] ) ) ) ) ) )
    CPAg$ispADJbulkLength <- as.numeric ( ifelse ( CPAg$bulkLength_km < 1 , ADJ[2,22] , 
                                                   ifelse ( CPAg$bulkLength_km >= 1   & CPAg$bulkLength_km < 5    , ADJ[2,23]  , 
                                                            ifelse ( CPAg$bulkLength_km >= 5   & CPAg$bulkLength_km < 10   , ADJ[2,24]  , 
                                                                     ifelse ( CPAg$bulkLength_km >= 10  & CPAg$bulkLength_km < 100  , ADJ[2,25]  , 
                                                                              ifelse ( CPAg$bulkLength_km >= 100 & CPAg$bulkLength_km < 200  , ADJ[2,26]  , ADJ[2,27] ) ) ) ) ) )
    CPAg$ispADJsinkLength <- as.numeric ( ifelse ( CPAg$sinkLength_km < 1 , ADJ[2,22] , 
                                                   ifelse ( CPAg$sinkLength_km >= 1   & CPAg$sinkLength_km < 5    , ADJ[2,23]  , 
                                                            ifelse ( CPAg$sinkLength_km >= 5   & CPAg$sinkLength_km < 10   , ADJ[2,24]  , 
                                                                     ifelse ( CPAg$sinkLength_km >= 10  & CPAg$sinkLength_km < 100  , ADJ[2,25]  , 
                                                                              ifelse ( CPAg$sinkLength_km >= 100 & CPAg$sinkLength_km < 200  , ADJ[2,26]  , ADJ[2,27] ) ) ) ) ) )
    CPAg$ispADJexportLength <- as.numeric ( ifelse ( CPAg$exportLength_km < 1 , ADJ[2,22] , 
                                                     ifelse ( CPAg$exportLength_km >= 1   & CPAg$exportLength_km < 5    , ADJ[2,23]  , 
                                                              ifelse ( CPAg$exportLength_km >= 5   & CPAg$exportLength_km < 10   , ADJ[2,24]  , 
                                                                       ifelse ( CPAg$exportLength_km >= 10  & CPAg$exportLength_km < 100  , ADJ[2,25]  , 
                                                                                ifelse ( CPAg$exportLength_km >= 100 & CPAg$exportLength_km < 200  , ADJ[2,26]  , ADJ[2,27] ) ) ) ) ) )
  }
  
  #transmission -- this assumes the spur lengths of offshore projects are within HVDC specs with no repeaters, and that HVDC submarine transitions to HVDC overhead with no issue
  if ( resource == "off" ) {
    CPAg$spur_lineCost_maud2021         <- CPAg$incap * ( sapply ( CPAg$incap , function(x) txOffCost[ which ( txOffMax >= x )[1] ] / txOffMax[ which ( txOffMax >= x )[1] ] ) * ( CPAg$landfallCost / 1e3 ) + sapply ( CPAg$incap , function(x) txOffland[ which ( txOffMax >= x )[1] ] / txOffMax[ which ( txOffMax >= x )[1] ] ) * ( CPAg$onshoreCost / 1e3 ) )
    CPAg$spur_subCost_maud2021          <- CPAg$incap * ( sapply ( CPAg$incap , function(x) txOffSubp[ which ( txOffMax >= x )[1] ]  / txOffMax[ which ( txOffMax >= x )[1] ] ) + sapply ( CPAg$incap , function(x) txOffSubp[ which ( txOffMax >= x )[1] ] / txOffMax[ which ( txOffMax >= x )[1] ] ) ) #from submarine HVDC to overhead HVDC + ifelse ( CPAg$onshoreLength_km > 10 , sapply ( CPAg$incap , function(x) txSub[ which ( txMax > x )[1] ] ) , 0 ) + sapply ( CPAg$incap , function(x) txSub[ which ( txMax > x )[1] ] ) * ifelse ( CPAg$onshoreLength_km  <= 250 , 0 , ceiling ( ( CPAg$CPAg$onshoreLength_km - 250 ) / 161 ) )
    CPAg$export_lineCost_maud2021       <- CPAg$incap * ( sapply ( CPAg$incap , function(x) txOffCost[ which ( txOffMax >= x )[1] ] / txOffMax[ which ( txOffMax >= x )[1] ] ) * ( CPAg$exportLandfallCost / 1e3 ) + sapply ( CPAg$incap , function(x) txOffland[ which ( txOffMax >= x )[1] ] / txOffMax[ which ( txOffMax >= x )[1] ] ) * ( CPAg$exportOnshoreCost / 1e3 )  )
    CPAg$export_subCost_maud2021        <- CPAg$incap * ( sapply ( CPAg$incap , function(x) txOffSubp[ which ( txOffMax >= x )[1] ] / txOffMax[ which ( txOffMax >= x )[1] ] ) )
  }
  
  ##if want to include HVDC need to change
  if ( ! ( resource == "off" ) ) {
    CPAg$spur_lineCost_maud2021       <- CPAg$incap * ( sapply ( CPAg$incap , function(x) txCost[ which ( txMax >= x )[1] ] / txMax[ which ( txMax >= x )[1] ] )  * ( CPAg$spurCost / 1e3 ) )
    CPAg$spur_subCost_maud2021        <- CPAg$incap * ( sapply ( CPAg$incap , function(x) txSubp[ which ( txMax >= x )[1] ] / txMax[ which ( txMax >= x )[1] ] ) + sapply ( CPAg$incap , function(x) txSubp[ which ( txMax >= x )[1] ] / txMax[ which ( txMax >= x )[1] ] ) + sapply ( CPAg$incap , function(x) txSubp[ which ( txMax >= x )[1] ] / txMax[ which ( txMax >= x )[1] ] ) * ifelse ( CPAg$spurLength_km  <= 250 , 0 , ceiling ( ( CPAg$spurLength_km - 250 ) / 161 ) ) )
    CPAg$export_lineCost_maud2021     <- CPAg$incap * ( sapply ( CPAg$incap , function(x) txCost[ which ( txMax >= x )[1] ] / txMax[ which ( txMax >= x )[1] ] )  * ( CPAg$exportCost/ 1e3 ) )
    CPAg$export_subCost_maud2021      <- CPAg$incap * ( sapply ( CPAg$incap , function(x) txSubp[ which ( txMax >= x )[1] ] / txMax[ which ( txMax >= x )[1] ] ) )
  }
  
  CPAg$gridConCost_maud2021           <- CPAg$spur_lineCost_maud2021 * CPAg$ispADJspurLength + CPAg$spur_subCost_maud2021 
  CPAg$bulk_lineMult                  <- ifelse ( ( ifelse ( resource == "pv" , pvGrossUp , 1 ) * CPAg$m_cf_noloss / bulkAdj ) > 1 , 1 , ifelse ( resource == "pv" , pvGrossUp , 1 ) * CPAg$m_cf_noloss / bulkAdj )
  #bulk/sink costing of sites > 1200 MW
  CPAgb <- subset ( CPAg ,  CPAg$incap > 1200 )
  CPAg  <- subset ( CPAg , !CPAg$incap > 1200 )
  #330kV for all bulk and sink <= 1200
  CPAg$adjBulkCost_maud2021           <- CPAg$incap * ( ( txCost[5] / txMax[5] * CPAg$bulkCost / 1e3 * CPAg$ispADJbulkLength ) + 
                                                          ifelse ( !CPAg$bulkLength_km > 0 , 0 , ifelse ( CPAg$spurLength_km + CPAg$bulkLength_km <= 250 , sapply ( CPAg$incap , function(x) trans330[ which ( txMax >= x )[1] ] ) ,  ( txSub[5] / txMax[5] ) + 
                                                                                                            ( txSubp[5] / txMax[5] ) * ifelse ( CPAg$bulkLength_km  <= 250 , 0 , ceiling ( ( CPAg$bulkLength_km - 250 ) / 161 ) ) ) ) ) * CPAg$bulk_lineMult
  CPAg$adjSinkCost_maud2021           <- CPAg$incap * ( ( txCost[5] / txMax[5] * CPAg$sinkCost / 1e3 * CPAg$ispADJsinkLength ) + 
                                                          ifelse ( !CPAg$sinkLength_km > 0 , 0 , ifelse ( CPAg$spurLength_km + CPAg$sinkLength_km <= 250 , sapply ( CPAg$incap , function(x) trans330[ which ( txMax >= x )[1] ] ) ,  ( txSub[5] / txMax[5] ) + 
                                                                                                            ( txSubp[5] / txMax[5] ) * ifelse ( CPAg$sinkLength_km  <= 250 , 0 , ceiling ( ( CPAg$sinkLength_km - 250 ) / 161 ) ) ) ) )  * CPAg$bulk_lineMult ##using bulk_lineMult as same for sink
  ##running kV line for all sites above
  if ( nrow ( CPAgb ) > 0 ) {
    CPAgb$adjBulkCost_maud2021           <- CPAgb$incap * ( sapply ( CPAgb$incap , function(x) txCost[ which ( txMax >= x )[1] ] / txMax[ which ( txMax >= x )[1] ] ) * ( CPAgb$bulkCost / 1e3 )  * CPAgb$ispADJbulkLength + 
                                                            ifelse ( !CPAgb$bulkLength_km > 0 , 0 , ifelse ( CPAgb$spurLength_km + CPAgb$bulkLength_km <= 250 , 0 ,  sapply ( CPAgb$incap , function(x) txSub[ which ( txMax >= x )[1] ] / txMax[ which ( txMax >= x )[1] ] ) ) + 
                                                                       sapply ( CPAgb$incap , function(x) txSubp[ which ( txMax >= x )[1] ] / txMax[ which ( txMax >= x )[1] ] ) * ifelse ( CPAgb$bulkLength_km  <= 250 , 0 , ceiling ( ( CPAgb$bulkLength_km - 250 ) / 161 ) ) ) ) * CPAgb$bulk_lineMult
    CPAgb$adjSinkCost_maud2021           <- CPAgb$incap * ( sapply ( CPAgb$incap , function(x) txCost[ which ( txMax >= x )[1] ] / txMax[ which ( txMax >= x )[1] ] ) * ( CPAgb$sinkCost / 1e3 )  * CPAgb$ispADJsinkLength + 
                                                            ifelse ( !CPAgb$sinkLength_km > 0 , 0 , ifelse ( CPAgb$spurLength_km + CPAgb$sinkLength_km <= 250 , 0 ,  sapply ( CPAgb$incap , function(x) txSub[ which ( txMax >= x )[1] ] / txMax[ which ( txMax >= x )[1] ] ) ) + 
                                                                       sapply ( CPAgb$incap , function(x) txSubp[ which ( txMax >= x )[1] ] / txMax[ which ( txMax >= x )[1] ] ) * ifelse ( CPAgb$sinkLength_km  <= 250 , 0 , ceiling ( ( CPAgb$sinkLength_km - 250 ) / 161 ) ) ) ) * CPAgb$bulk_lineMult ##using bulk_lineMult as same for sink
    CPAg <- rbind ( CPAg , CPAgb )
    rm ( CPAgb)
  }
  
  #supply --- did not remove capex as filter is based on capex
  CPAg$bulk_aud2021_kw                <- ( CPAg$CAPEX_maud2021 + CPAg$gridConCost_maud2021 + CPAg$adjBulkCost_maud2021 ) * 1e6 / ( CPAg$incap * 1e3 ) 
  CPAg$sink_aud2021_kw                <- ( CPAg$CAPEX_maud2021 + CPAg$gridConCost_maud2021 + CPAg$adjSinkCost_maud2021 ) * 1e6 / ( CPAg$incap * 1e3 )
  ##LCC for plots for write-up (based on a X year project lifespan)
  fixedOM <- ifelse ( resource == "off" & lcoe.year < 2040 , 92 , ifelse ( resource == "off" & lcoe.year >= 2040 , 80.3 , ifelse ( resource == "pv" , 17.6 , 25.9 ) ) )
  
  if ( resource == "off" ) {
    CPAg$bulk_aud2021_mwh               <- ( ( CPAg$CAPEX_maud2021 * crfVRE + ( CPAg$gridConCost_maud2021 * vinOffMult ) * crfTX + ( CPAg$adjBulkCost_maud2021 * vinOffMult ) * crfTX ) * 1e6  / ( CPAg$incap ) + fixedOM ) / (  8760 * ( CPAg$m_cf_noloss * ifelse ( CPAg$resource == "pv" , pvGrossUp , 1 ) * ( 1 - ( CPAg$spurLength_km * txloss.dc ) / 100 ) * ( 1 - convLoss.dc ) ) )
    CPAg$sink_aud2021_mwh               <- ( ( CPAg$CAPEX_maud2021 * crfVRE + ( CPAg$gridConCost_maud2021 * vinOffMult ) * crfTX + ( CPAg$adjSinkCost_maud2021 * vinOffMult ) * crfTX ) * 1e6 / ( CPAg$incap ) + fixedOM ) / (  8760 * ( CPAg$m_cf_noloss * ifelse ( CPAg$resource == "pv" , pvGrossUp , 1 ) * ( 1 - ( CPAg$spurLength_km * txloss.dc ) / 100 ) * ( 1 - convLoss.dc ) ) )
  } 
  if ( !( resource == "off" ) ) {
    CPAg$bulk_aud2021_mwh               <- ( ( CPAg$CAPEX_maud2021 * crfVRE + CPAg$gridConCost_maud2021 * crfTX + CPAg$adjBulkCost_maud2021 * crfTX ) * 1e6  / ( CPAg$incap ) + fixedOM ) / (  8760 * ( CPAg$m_cf_noloss * ifelse ( CPAg$resource == "pv" , pvGrossUp , 1 ) * ( 1 - ( CPAg$spurLength_km * txloss.ac ) / 100 ) ) )
    CPAg$sink_aud2021_mwh               <- ( ( CPAg$CAPEX_maud2021 * crfVRE + CPAg$gridConCost_maud2021 * crfTX + CPAg$adjSinkCost_maud2021 * crfTX ) * 1e6 / ( CPAg$incap ) + fixedOM ) / (  8760 * ( CPAg$m_cf_noloss * ifelse ( CPAg$resource == "pv" , pvGrossUp , 1 ) * ( 1 - ( CPAg$spurLength_km * txloss.ac ) / 100 ) ) )
  }
  
  #NZAu names
  GEO           <- read.xlsx ( paste ( "../d0_1source/NZAu_geographies_ap.xlsx" , sep = ""  ) , sheet = 1  , colNames = TRUE ,  skipEmptyRows = TRUE , skipEmptyCols = TRUE  )
  GEO           <- GEO[,2:3]
  names ( GEO ) <- c ( "NZAu_maj" , "m_NZAu_maj" )
  CPAg          <- merge ( CPAg , GEO  , by = "m_NZAu_maj"  , all.x =  TRUE )
  
  #add settings
  CPAg$TXspurType                <- ifelse ( CPAg$resource == "off" , sapply ( CPAg$incap , function(x)  txOffType[ which ( txOffMax >= x )[1] ] ) , sapply ( CPAg$incap , function(x) txType[ which ( txMax >= x )[1] ] ) )
  CPAg$TXspurTypeMax_MW          <- ifelse ( CPAg$resource == "off" , sapply ( CPAg$incap , function(x)  txOffMax[ which ( txOffMax >= x )[1] ] )  , sapply ( CPAg$incap , function(x)  txMax[ which ( txMax >= x )[1] ] ) )
  CPAg$TXspurCost_aud2021_km     <- ifelse ( CPAg$resource == "off" , sapply ( CPAg$incap , function(x)  txOffCost[ which ( txOffMax >= x )[1] ] ) , sapply ( CPAg$incap , function(x) txCost[ which ( txMax >= x )[1] ] ) )
  CPAg$TXbulkSinkType            <- ifelse ( CPAg$incap > 1200 , "500kV_HVAC_double__3040MW" , "330kV_HVAC_double__1200MW" )
  
  ##--B. EXPORT and filters
  ##straight line export cost with minimum build multiplier (from cost surfaces)
  CPAg$export_MinMult <- min ( min ( subset ( CPAg$sinkCost , CPAg$sinkCost  > 0 ) / subset ( CPAg$sinkLength_m , CPAg$sinkCost  > 0 ) ) , 
                               min ( subset ( CPAg$bulkCost , CPAg$bulkCost  > 0 ) / subset ( CPAg$bulkLength_m , CPAg$bulkCost  > 0 ) ) ,
                               min ( subset ( CPAg$spurCost , CPAg$spurCost  > 0 ) / subset ( CPAg$spurLength_m , CPAg$spurCost  > 0 ) ) )
  ##generate EXPORT use flag and HACK cost
  CPAg$export <- 0
  if (  resource == "off" ) { 
    CPAg$export                           <- ifelse ( CPAg$d_nodeOff < 350 & CPAg$m_cf_noloss > 0.45 , 1 , CPAg$export ) ##& !CPAg$m_NZAu_maj %in% c ( 13 , 14 , 15 )
    CPAg$export_FINlineCost_maud2021      <- ifelse ( CPAg$export == 0 , 0 , CPAg$export_lineCost_maud2021 * CPAg$export_MinMult )
                                                      ##( sapply ( CPAg$incap , function(x) txOffCost[ which ( txOffMax >= x )[1] ] ) * CPAg$d_nodeOff  ) * CPAg$export_MinMult )
    }
  if ( !resource == "off" ) { 
    CPAg$export                           <- ifelse ( CPAg$d_nodeOn  < 200 & CPAg$m_popden  < 0.1 , 1 , CPAg$export )
    #CPAg$export                           <- ifelse ( CPAg$export == 1 & CPAg$resource == "wind" & CPAg$d_pvExp > 0   , 0 , CPAg$export )  #removed v5
    #CPAg$export                           <- ifelse ( CPAg$export == 1 & CPAg$resource == "pv"   & CPAg$d_windExp > 0 , 0 , CPAg$export )  #removed v5
    CPAg$export_FINlineCost_maud2021      <- ifelse ( CPAg$export == 0 , 0 , CPAg$export_lineCost_maud2021 * CPAg$export_MinMult ) 
                                                      ##( sapply ( CPAg$incap , function(x) txCost[ which ( txMax >= x )[1] ] ) * CPAg$d_nodeOn ) * CPAg$export_MinMult )
  }
  ##special case for WA central & sa where export overlaps with domestic
  CPAg$export                             <- ifelse ( CPAg$d_sink  < 60  & CPAg$subNzau == "wa-central" , 0 , CPAg$export )
  CPAg$export                             <- ifelse ( CPAg$d_sink  < 100 & CPAg$subNzau == "sa"         , 0 , CPAg$export )
  
  #basic metrics
  CPAg$export_aud2021_kw                  <- ifelse ( CPAg$export == 0 , 0 , (   CPAg$CAPEX_maud2021 + CPAg$export_FINlineCost_maud2021 + CPAg$export_subCost_maud2021 ) * 1e6 / ( CPAg$incap * 1e3 ) )
  
  if ( resource == "off" ) {
    CPAg$export_aud2021_mwh                 <- ifelse ( CPAg$export == 0 , 0 , ( ( CPAg$CAPEX_maud2021 * crfVRE + ( CPAg$export_FINlineCost_maud2021 * vinOffMult ) * crfTX + ( CPAg$export_subCost_maud2021 * vinOffMult ) * crfTX ) / CPAg$incap * 1e6  ) / (  8760 * ( CPAg$m_cf_noloss * ifelse ( CPAg$resource == "pv" , pvGrossUp , 1 ) * ( 1 - ( CPAg$exportLength_km * txloss.dc ) / 100 ) * ( 1 - convLoss.dc ) ) ) )
  }
  if ( !( resource == "off" ) ) {
    CPAg$export_aud2021_mwh                 <- ifelse ( CPAg$export == 0 , 0 , ( ( CPAg$CAPEX_maud2021 * crfVRE + CPAg$export_FINlineCost_maud2021 * crfTX + CPAg$export_subCost_maud2021 * crfTX ) / CPAg$incap * 1e6  ) / (  8760 * ( CPAg$m_cf_noloss * ifelse ( CPAg$resource == "pv" , pvGrossUp , 1 ) * ( 1 - ( CPAg$exportLength_km * txloss.ac ) / 100 ) ) ) )
  }
  
  ##ADDITIONAL EXCLUSIONS (LENGTH, OFFSHORE LENGTH and DEPTH, POPDEN, THREATENED SPECIES, LOAD DEST)
  ##supply curve filters 
  ##export - filter on capacity factors
  CPAf   <- subset ( CPAg ,  ( CPAg$resource == "wind" & CPAg$m_cf_noloss < 0.28 & export == 1 ) )
  CPAg   <- subset ( CPAg , !( CPAg$resource == "wind" & CPAg$m_cf_noloss < 0.28 & export == 1 ) )
  if ( nrow ( CPAf ) > 0 ) { CPAf$filter <- "wind site with a Capacity Factor less than 0.28 (export)" }
  ##offshore - distance to land
  #TEM    <- subset ( CPAg , !CPAg$d_land < 100   ) 
  #CPAg   <- subset ( CPAg ,  CPAg$d_land < 100   )
  #if ( nrow ( TEM ) > 0 ) { 
  #  TEM$filter <- "more than 100km straight line from land"
  #  CPAf       <- rbind ( CPAf , TEM )
  #}
  ##offshore - depth greater than 1km
  TEM    <- subset ( CPAg , !CPAg$m_elev > -1000 )
  CPAg   <- subset ( CPAg ,  CPAg$m_elev > -1000 )
  if ( nrow ( TEM ) > 0 ) { 
    TEM$filter <- "ocean floor is deeper than 1000m"
    CPAf       <- rbind ( CPAf , TEM )
  }
  ##threatened species richness
  #TEM    <- subset ( CPAg , !CPAg$m_threatSpecies < 10 )
  #CPAg   <- subset ( CPAg ,  CPAg$m_threatSpecies < 10 )
  #if ( nrow ( TEM ) > 0 ) { 
  #  TEM$filter <- "more than an average of 10 threatened species across entire land parcel"
  #  CPAf       <- rbind ( CPAf , TEM )
  #}
  ##population density greater than 100 people/km2
  TEM    <- subset ( CPAg , !CPAg$m_popden < 100 )
  CPAg   <- subset ( CPAg ,  CPAg$m_popden < 100 )
  if ( nrow ( TEM ) > 0 ) { 
    TEM$filter <- "population density greater than 100 people/km2"
    CPAf       <- rbind ( CPAf , TEM )
  }
  ##arbitrary line lengths to cut down on sites before applying population filter and sending to Ryan
  if ( resource == "off" ) {
    TEM    <- subset ( CPAg , !(   ( CPAg$export == 0 & CPAg$spurLength_km < 1000 ) | ( CPAg$export == 1 ) ) )
    #TEMb   <- subset ( CPAg ,  (   ( CPAg$export == 0 & CPAg$spurLength_km < 1000 ) | ( CPAg$export == 1 ) ) )
    CPAg   <- subset ( CPAg ,  (   ( CPAg$export == 0 & CPAg$spurLength_km < 1000 ) | ( CPAg$export == 1 ) ) ) 
    if ( nrow ( TEM ) > 0 ) { 
      TEM$filter <- "offshore spur length is longer than 1000km"
      CPAf       <- rbind ( CPAf , TEM )
    }
  }
  if ( ! ( resource == "off" ) ) {
    TEM    <- subset ( CPAg , !(     CPAg$export == 0 & CPAg$spurLength_km < 400   | ( CPAg$export == 1 ) ) )
    CPAg   <- subset ( CPAg ,  ( ( ( CPAg$export == 0 & CPAg$spurLength_km < 400 ) | ( CPAg$export == 1 ) ) ) )
    if ( nrow ( TEM ) > 0 ) { 
      TEM$filter <- "onshore spur length is longer than 400km" 
      CPAf       <- rbind ( CPAf , TEM )
    }
  }
  
  rm ( TEM )
  
  ##added for costoCap
  #CPAg$costOcap <- costOcap
  
  ##--C. Bulk v Sink filter vs export
  
  ##FILTER BY POPULATION TOTAL for bulk first
  #prepare columns
  CPAgs               <- CPAg[ , c ( "NZAu_maj" , "OIDcom" , "resource" , "export" , "m_cf_noloss" , "egen" , "incap" , "CAPEX_maud2021"  ,
                                     "spur_lineCost_maud2021" , "spur_subCost_maud2021" , "adjBulkCost_maud2021" , "adjSinkCost_maud2021" , "export_lineCost_maud2021" , "export_subCost_maud2021" , "export_FINlineCost_maud2021" ,
                                     "bulk_aud2021_kw" , "sink_aud2021_kw" , "export_aud2021_kw" , "bulk_aud2021_mwh" , "sink_aud2021_mwh" , "export_aud2021_mwh" ,
                                     "spurLength_km" , "bulkLength_km" , "sinkLength_km" , "exportLength_km" ,
                                     "bulkSA2aggOID" ,"bulkSA2aggPOP" , "sinkSA2oid" , "sinkSA2pop" , "exportPortName" , "exportReg" , "d_nodeOn" , "d_nodeOff" , "m_elev" ,
                                     "subOID" , "spurOID" , "bulkOID" , "sinkOID" , "exportOID" , "filter" , "TXspurType" , "TXspurTypeMax_MW" , "m_node" , "gridConCost_maud2021" ,
                                     "spurCost" , "bulkCost" , "sinkCost" , "exportCost" , "TXbulkSinkType" , "m_windOld_maj" , "m_windOld_cov" , "m_pvOld_maj" , "m_pvOld_cov" ) ] #, "costOcap" ) ]
  #names ( CPAgs )
  
  ##prepare gis
  LOADS                <- read.csv  ( paste ( "../d0_1source/t1_destLoad.csv" , sep = "" ) , header = TRUE , stringsAsFactors = FALSE ) 
  LOADS                <- LOADS[, c ( 6 , 3:2 , 5 , 9 )]
  LOADS                <- subset ( LOADS , !LOADS$type == "export")
  names ( LOADS )[1:3] <- c ( "SA2oid" , "m_NZAu_maj" , "SA2pop" )
  LOADS                <- merge ( LOADS , GEO , by = "m_NZAu_maj" , all.x = TRUE )
  LOADS                <- LOADS[, c ( 2 , 6 , 3:5 )]
  names ( LOADS )[2]   <- "SA2nzau"     
  TEM                  <- subset ( CPAgs , CPAgs$export == 0 )
  TEMa                 <- aggregate ( incap ~ bulkSA2aggOID  , TEM , FUN = sum  )
  names ( TEMa )       <- c ( "SA2oid" , "incapBulk_mw" )
  LOADS                <- merge ( LOADS , TEMa , by = "SA2oid" , all.x = TRUE )
  TEMb                 <- aggregate ( incap ~ sinkSA2oid     , TEM , FUN = sum  )
  names ( TEMb )       <- c ( "SA2oid" , "incapSink_mw" )
  LOADS                <- merge ( LOADS , TEMb , by = "SA2oid" , all.x = TRUE )
  LOADS$incapBulk_mw[is.na ( LOADS$incapBulk_mw )] <- 0
  LOADS$incapSink_mw[is.na ( LOADS$incapSink_mw )] <- 0
  rm ( TEMa , TEMb , TEM)
  #LOADS$BulkTOT_mw     <- sum ( LOADS$incapBulk_mw , na.rm = TRUE )
  #LOADS$SinkTOT_mw     <- sum ( LOADS$incapSink_mw , na.rm = TRUE )
  LOADS$target_mw      <- LOADS$SA2pop * resShare / 1e3  # x kw per person in any community
  LOADS$target_mw      <- ifelse ( LOADS$type == "sink" & LOADS$target_mw < 20000 , 20000 , LOADS$target_mw )
  LOADS$target_mw      <- ifelse ( LOADS$SA2oid == 14 , LOADS$incapSink_mw  , LOADS$target_mw )  #needed??
  
  
  
  ##for each SA2 for which a bulk entry exists, take bulk amount
  #i<-1 #debug
  CPAsort <- subset ( CPAgs , CPAgs$export == 0 )
  for (i in 1:nrow ( LOADS ) ) {
    if ( LOADS$incapBulk_mw[i] + LOADS$incapSink_mw[i] > 0 ) {
      TE                     <- subset ( CPAsort , ( CPAsort$bulkSA2aggOID == LOADS$SA2oid[i] | CPAsort$sinkSA2oid == LOADS$SA2oid[i] ) & CPAsort$export == 0 ) #& CPAgs$NZAu_maj == LOADS$SA2nzau[i] )
      if ( nrow ( TE ) > 0 ) {
        TE$TXcost_maud2021     <- TE$gridConCost_maud2021 + ifelse ( TE$bulkSA2aggOID == LOADS$SA2oid[i] , TE$adjBulkCost_maud2021 , TE$adjSinkCost_maud2021 )
        TE$lcoe2050_maud2021_mwh <- ifelse ( TE$bulkSA2aggOID == LOADS$SA2oid[i] , TE$bulk_aud2021_mwh , TE$sink_aud2021_mwh )
        TE$TXlength_km         <- TE$spurLength_km + ifelse ( TE$bulkSA2aggOID == LOADS$SA2oid[i] , TE$bulkLength_km , TE$sinkLength_km )
        TE$bin                 <- ifelse ( TE$bulkSA2aggOID == LOADS$SA2oid[i] , 1 , 2 )
        TE$SA2oid              <- ifelse ( TE$bulkSA2aggOID == LOADS$SA2oid[i] , TE$bulkSA2aggOID , TE$sinkSA2oid )
        TE$NZAu_site           <- TE$NZAu_maj
        TE$NZAu_maj            <- LOADS$SA2nzau[i]
        TE$TXeq                <- paste ( "spur line costs + spur subtation costs + " , ifelse ( TE$bulkSA2aggOID == LOADS$SA2oid[i] , "bulkCost" , "sinkCost"  ) , sep = ""  )                 
        TE$TXcost_maud2021_spur <- TE$gridConCost_maud2021 
        TE$TXcost_maud2021_s2l  <- ifelse ( TE$bulkSA2aggOID == LOADS$SA2oid[i] , TE$adjBulkCost_maud2021 , TE$adjSinkCost_maud2021 )
  
        TE                     <- TE[order( TE$TXlength_km , na.last = TRUE , decreasing = FALSE ),]  #why by TX length and not lcoe? or cost?
        TE$cumCap              <- cumsum ( TE$incap )
        if ( nrow ( TE ) > 0 ) { TE$cumCap[1] <- 0 }
        TE           <- subset ( TE , TE$cumCap <= LOADS$target_mw[i] )
        TE           <- TE[, !names ( TE) %in% c ( "cumCap" ) ]
        if (  exists ( "DOME" ) ) { DOME <- rbind ( DOME , TE ) }
        if ( !exists ( "DOME" ) ) { DOME <- TE }
        CPAsort <- subset ( CPAsort , !( CPAsort$OIDcom %in% DOME$OIDcom ) )
      }
    }
  }
  
  ##add back in all offshore sites removed from supply curve
  if ( resource == "off" ) { 
    TE <- CPAsort
    rm ( CPAsort )
    TE$TXcost_maud2021     <- TE$gridConCost_maud2021 + TE$adjSinkCost_maud2021
    TE$lcoe2050_maud2021_mwh <- TE$sink_aud2021_mwh
    TE$TXlength_km         <- TE$spurLength_km + TE$sinkLength_km
    TE$bin                 <- 3
    TE$SA2oid              <- TE$sinkSA2oid
    TE$NZAu_site           <- TE$NZAu_maj
    TE$NZAu_maj             <- sapply ( TE$SA2oid , function (x) LOADS$SA2nzau[ which ( x == LOADS$SA2oid )] )
    TE$TXeq                 <- paste ( "spur line costs + spur subtation costs + " , "sinkCost" , sep = ""  )
    TE$TXcost_maud2021_spur <- TE$gridConCost_maud2021 
    TE$TXcost_maud2021_s2l  <- TE$adjSinkCost_maud2021
    DOME <- rbind ( DOME , TE ) 
  }
    
  ##add back in all onshore sites removed from supply curve
  if ( noPOPfilt == 1 & !resource == "off") { 
    TE <- CPAsort
    rm ( CPAsort )
    TE$TXcost_maud2021     <- TE$gridConCost_maud2021 + TE$adjSinkCost_maud2021
    TE$lcoe2050_maud2021_mwh <- TE$sink_aud2021_mwh
    TE$TXlength_km         <- TE$spurLength_km + TE$sinkLength_km
    TE$bin                 <- 3
    TE$SA2oid              <- TE$sinkSA2oid
    TE$NZAu_site           <- TE$NZAu_maj
    TE$NZAu_maj            <- sapply ( TE$SA2oid , function (x) LOADS$SA2nzau[ which ( x == LOADS$SA2oid )] )
    TE$TXeq                <- paste ( "spur line costs + spur subtation costs + " , "sinkCost" , sep = ""  )
    TE$TXcost_maud2021_spur <- TE$gridConCost_maud2021
    TE$TXcost_maud2021_s2l  <- TE$adjSinkCost_maud2021
    DOME <- rbind ( DOME , TE ) 
  }
  
  #debug
  #a <- subset ( CPAgs , CPAgs$NZAu_maj == "wa-south" & export == 0 )
  #b <- subset ( DOME , DOME$NZAu_maj == 'wa-south' )
  
  
  ##simple LCC cutoff
  CPAe    <- subset ( DOME , !( DOME$lcoe2050_maud2021_mwh < ifelse (  DOME$resource == "off" , offCut , onCut ) ) )
  DOME    <- subset ( DOME ,    DOME$lcoe2050_maud2021_mwh < ifelse (  DOME$resource == "off" , offCut , onCut ) )
  if ( nrow ( CPAe ) > 0 ) {   CPAe$filter <- paste ( "simple LCC for domestic more expensive that cut-off specifed by EER of $" , offCut , "/mWh for offshore and $" , onCut , "/mwh for onshore" , sep = "" ) }
  chk       <- aggregate ( incap ~ NZAu_maj , DOME , FUN = sum )
  chk$incap <- round ( chk$incap / 1e3 , 1 )
  
  #export
  ##set up SA2 for export sites
  LODE                <- read.csv  ( paste ( "../d0_1source/t1_destLoad.csv" , sep = "" ) , header = TRUE , stringsAsFactors = FALSE  , fileEncoding = "UTF-8-BOM") 
  LODE                <- subset ( LODE , LODE$type == "export")
  LODE                <- LODE[, c ( 6 , 10 )]
  names ( LODE )[1]   <- "SA2oid"
  ##process
  EXPO                     <- subset ( CPAgs , CPAgs$export == 1 )
  EXPO$TXcost_maud2021     <- EXPO$export_FINlineCost_maud2021 + EXPO$export_subCost_maud2021
  EXPO$lcoe2050_maud2021_mwh <- EXPO$export_aud2021_mwh
  EXPO$TXlength_km         <- EXPO$exportLength_km # ifelse ( resource == "off" ,  EXPO$d_nodeOff , EXPO$d_nodeOn )
  EXPO$bin                 <- 4
  EXPO                     <- merge ( EXPO , LODE , by = "exportPortName" , all.x = TRUE )
  EXPO                     <- EXPO[, c ( 2:29 , 1 , 30:ncol(EXPO))] 
  EXPO$NZAu_site           <- EXPO$NZAu_maj
  EXPO$NZAu_maj            <- tolower( paste ( "ex-" , EXPO$exportReg , sep = "" ) )
  EXPO$TXeq                <- "export actual path + project substation - no destination substation"
  EXPO$TXcost_maud2021_spur <- EXPO$export_FINlineCost_maud2021 + EXPO$export_subCost_maud2021 
  EXPO$TXcost_maud2021_s2l  <- 0
  
  TE     <- subset ( EXPO , !( EXPO$lcoe2050_maud2021_mwh < ifelse (  EXPO$resource == "off" , offCut , onCut ) ) )
  EXPO   <- subset ( EXPO ,    EXPO$lcoe2050_maud2021_mwh < ifelse (  EXPO$resource == "off" , offCut , onCut ) )
  if ( nrow ( TE ) > 0 ) {   
    TE$filter <- paste ( "simple LCC for domestic more expensive that cut-off specifed by EER of $" , offCut , "/mWh for offshore and $" , onCut , "/mwh for onshore" , sep = "" ) 
    CPAe      <- rbind ( CPAe , TE )
  }
  che       <- aggregate ( incap ~ NZAu_maj , EXPO , FUN = sum )
  che$incap <- round ( che$incap / 1e3 , 1 )
  cht       <- rbind ( chk , che )
  names ( cht ) <- c ( "nzau" , "supply_gw")
  cht           <- cht[order( cht$supply_gw , decreasing = FALSE ),]
  
  rm ( TE , i )
  
  ##combine into single supply curve and align columns with Ryan's script
  ##col_to_keep = ['OIDcom', 'm_cf_noloss', 'incap', 'NZAu_maj', 'spurLength_km', 'spur_lineCost_maud2021', 'spur_subCost_maud2021', 'adjBulkCost_maud2021' , 'lcoe2050_maud2021_mwh']
  ALL                        <- rbind ( DOME, EXPO )
  
  ##add $ per kW to SC and create additional table
  ALL$txAll_aud_kw    <- ALL$TXcost_maud2021 * 1e6 / ( ALL$incap * 1e3 )
  checo               <- aggregate ( incap ~ NZAu_maj , subset ( ALL , ALL$export == 0 & ALL$txAll_aud_kw < ifelse ( resource == "pv" , 350 , 800 ) ) , FUN = sum )  
  checo$incap         <- round ( checo$incap / 1e3 , 1 )                                     
  names ( checo )     <- c ( "nzau" , "supply_eco_gw")
  checo               <- merge ( cht , checo , by = "nzau" , all.x = TRUE )
  checo$supply_eco_gw <- ifelse ( is.na ( checo$supply_eco_gw ) , 0 , checo$supply_eco_gw )
  
  ##why are these here??
  #ALL$spurLength_km          <- ifelse ( ALL$export == 1 , ALL$exportLength_km , ALL$spurLength_km )
  #if (  ( resource == "off" ) ) { ALL$spurLength_km     <- ifelse ( ALL$export == 1 , ALL$d_nodeOff , ALL$spurLength_km ) }
  #if ( !( resource == "off" ) ) { ALL$spurLength_km     <- ifelse ( ALL$export == 1 , ALL$d_nodeOn  , ALL$spurLength_km ) }
  #ALL$spur_lineCost_maud2021 <- ifelse ( ALL$export == 1 , ALL$export_FINlineCost_maud2021 , ALL$spur_lineCost_maud2021 )
  #ALL$spur_subCost_maud2021  <- ifelse ( ALL$export == 1 , ALL$export_subCost_maud2021    , ALL$spur_subCost_maud2021  )
  #ALL$adjBulkCost_maud2021   <- ifelse ( ALL$export == 1 , 0 , ALL$adjBulkCost_maud2021 ) 
  
  #simplify for EER
  ALLs <- ALL[, c ( "OIDcom" , "m_cf_noloss" , "incap" , "NZAu_maj" , "export" , "bin" , "TXlength_km" , "TXcost_maud2021" , "m_elev" , "NZAu_site", "txAll_aud_kw" , "TXcost_maud2021_spur" , "TXcost_maud2021_s2l" , "spurLength_km" ,  "TXspurType" , "TXspurTypeMax_MW" , "TXbulkSinkType", "SA2oid" , "lcoe2050_maud2021_mwh")]
  ALLs <- ALLs[order( ALLs$txAll_aud_kw, decreasing = FALSE),]
  write.csv ( ALLs , paste ( "../d0_3results/biodiversity/_" , resource ,  "Supply_" , outVer , "_case" , case , "_" , CapYear , "_forSC_wBugfix.csv" , sep = "" ) , row.names = FALSE )
  
  ##--D. Add crf's for stage 10
  ALL$crfVRE <- crfVRE
  ALL$crfTX  <- crfTX
   
  ##--E. Save workbook
  if ( wbYes == 1 ) {
    wb            <- createWorkbook(creator = "AP")
    addWorksheet  ( wb, sheetName = paste ( resource , "_summary" , sep = "" ) )
    writeData     ( wb, sheet     = paste ( resource , "_summary" , sep = "" ) , rowNames = FALSE , colNames = TRUE , checo  )
    addWorksheet  ( wb, sheetName = paste ( resource , "_Allsimple" , sep = "" ) )
    writeData     ( wb, sheet     = paste ( resource , "_Allsimple" , sep = "" ) , rowNames = FALSE , colNames = TRUE , ALLs  )
    addWorksheet  ( wb, sheetName = paste ( resource , "_All" , sep = "" ) )
    writeData     ( wb, sheet     = paste ( resource , "_All" , sep = "" ) , rowNames = FALSE , colNames = TRUE , ALL  )
    addWorksheet  ( wb, sheetName = paste ( resource , "_Domestic" , sep = "" ) )
    writeData     ( wb, sheet     = paste ( resource , "_Domestic" , sep = "" ) , rowNames = FALSE , colNames = TRUE , DOME  )
    addWorksheet  ( wb, sheetName = paste ( resource , "_Export" , sep = "" ) )
    writeData     ( wb, sheet     = paste ( resource , "_Export" , sep = "" ) , rowNames = FALSE , colNames = TRUE , EXPO )
    addWorksheet  ( wb, sheetName = paste ( resource , "_SupplyShort" , sep = "" ) )
    writeData     ( wb, sheet     = paste ( resource , "_SupplyShort" , sep = "" ) , rowNames = FALSE , colNames = TRUE , CPAgs )
    addWorksheet  ( wb, sheetName = paste ( resource , "_SupplyGood" , sep = "" ) )
    writeData     ( wb, sheet     = paste ( resource , "_SupplyGood" , sep = "" ) , rowNames = FALSE , colNames = TRUE , CPAg )
    addWorksheet  ( wb, sheetName = paste ( resource , "_SupplyCutFiltered" , sep = "" ) )
    writeData     ( wb, sheet     = paste ( resource , "_SupplyCutFiltered" , sep = "" ) , rowNames = FALSE , colNames = TRUE , CPAf )
    addWorksheet  ( wb, sheetName = paste ( resource , "_SupplyCutTechProb" , sep = "" ) )
    writeData     ( wb, sheet     = paste ( resource , "_SupplyCutTechProb" , sep = "" ) , rowNames = FALSE , colNames = TRUE , CPAp )
    addWorksheet  ( wb, sheetName = paste ( resource , "_SupplyCutEconProb" , sep = "" ) )
    writeData     ( wb, sheet     = paste ( resource , "_SupplyCutEconProb" , sep = "" ) , rowNames = FALSE , colNames = TRUE , CPAe )
    addWorksheet  ( wb, sheetName = paste ( resource , "_LoadsWB" , sep = "" ) )
    writeData     ( wb, sheet     = paste ( resource , "_LoadsWB" , sep = "" ) , rowNames = FALSE , colNames = TRUE , LOADS )
    saveWorkbook  ( wb, file      = paste ( "../d0_3results/biodiversity/_" , resource ,  "Supply_" , outVer , "_case" , case , "_" , CapYear , "_forSC_wBugfix.xlsx" , sep = ""  ) , overwrite = TRUE ) 
    rm ( wb )
  }
  
  cht
  paste ( "Domestic capacity = " , round ( sum ( chk$incap) / 1e3 , 3 ) , "TW")
  paste ( "Export capacity = "   , round ( sum ( che$incap) / 1e3 , 3 ) , "TW")
  paste ( "Economic capacity domestic= " , round ( sum ( checo$supply_eco_gw ) / 1e3 , 3 ) , "TW")
  paste ( "Total capacity = "    , round ( sum ( cht$supply_gw) / 1e3 , 3 ) , "TW")
  
  a <- subset ( ALLs , ALLs$export == 0 & ALLs$txAll_aud_kw <= ifelse ( resource == "pv" , 350 , 1000 ) )
  paste ( "Total cap of = " , round ( sum ( a$incap ) / 1e6 , 3 ) , "TW, with mean interconnection TX cost per kW = " , round ( mean ( a$txAll_aud_kw , 1 ) ) , "AUD/kW" )
  paste ( "Mean TX to load cost = " , round ( mean ( a$txAll_aud_kw , 1 ) ) , "AUD/kW" )
  #paste ( "Median TX to load cost = " , round ( median ( a$txAll_aud_kw , 1 ) ) , "AUD/kW" )
  b <- aggregate ( incap ~ NZAu_maj , a , FUN = sum )
  b$incap <- round ( b$incap / 1e3 , 1 )
  b
  
  #c <- subset ( ALL , ALL$export == 0 )
  c <- aggregate ( incap ~ SA2oid , ALL , FUN = sum )
  c
  
  print ( paste ( "Finished supply curve creation for " , inVer , sep = "" ) )
  rm ( DOME , EXPO, a , b , c )
}

rm ( ADJ , v )
