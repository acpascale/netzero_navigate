# clean.R - cleans variables and plots from working environment


# 1.Remove only selected variables if wanted, otherwise remove all
rm(list = setdiff ( ls() , "") )

# 2.Create basic plot, assign output to a variable and then remove variable
plot(1.1)
hide<-dev.off()
rm(hide)


#Update R
#1#install.packages("installr")
#2#open Rgui
#3#library ( "installr")
#4#updateR()]
#5#close Rgui
#6#in Rstudio
#7#packs = as.data.frame(installed.packages(.libPaths()[1]), stringsAsFactors = F)
#8#install.packages(packs$Package)
