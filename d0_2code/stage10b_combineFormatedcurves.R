##   Combine formatted curves
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
setwd("X:/WORK/NZAu_LandUsePaper_MAIN/d0_2code/eer_supplycurves/v5/")
source("clean.R")

##--B.Load Library for country manipulations
suppressMessages ( library ( "openxlsx"     , lib.loc=.libPaths() ) )      # worksheet functions
suppressMessages ( library ( "reshape2"     , lib.loc=.libPaths() ) )      # melt, dcast

#-----END 0.ADMIN---------------



#-----1.COMBINE--------------------

#match original formatted supply with Ryan's final curves -- 
#Ryan's LCOE approx appears to use a different formula than the one that I do, which messes up export curves for Solar PV
#I am using instead the re-run NZAU raw data with bug fixes applied and a uniform handling of LCOE for 2050
SCN               <- read.csv  ( paste ( "formatted/renewablesAU_case0" , ".csv" , sep = ""  ) , header=TRUE , stringsAsFactors = FALSE )

#FSC               <- read.csv  ( paste ( "final curves/" , aspect[1] , "_nzau" , ".csv" , sep = ""  ) , header=TRUE , stringsAsFactors = FALSE )
#FSC               <- FSC[, c ( 1 , 2 , 14 )]

#SCN               <- merge (  SCN , FSC , by = names ( FSC )[1:2] , all = TRUE )
#SCN$lcoe_approx   <- ifelse ( is.na ( SCN$lcoe_approx ) , 0 , SCN$lcoe_approx )
SCN$case          <- 0
#names ( SCN )[11] <- "LCOE2050"
#SCN$file_name     <- paste ( "_" , SCN$file_name , sep = "" )

for ( i in 1:3) {
  TEM              <- read.csv  ( paste ( "formatted/renewablesAU_case" , i , ".csv" , sep = ""  ) , header=TRUE , stringsAsFactors = FALSE )
  TEM$case         <- i
  SCN              <- rbind ( SCN , TEM )
}

write.csv( SCN , file = paste ( "formatted/renewablesAU_case" , 9 , ".csv" , sep = "" ) ,row.names = FALSE )

rm ( SCN, i , TEM )
#--------STOP AND RUN EER BINNING SCRIPT-----------------------------