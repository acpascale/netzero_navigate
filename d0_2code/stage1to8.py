
# -*- coding: utf-8 -*-
"""
Created on Fri Jul 23 11:17:10 2021 -- last NZAU edit 30 August 2022, NZx 29/11/2023 -- last paper edit 23 August 2024

@author: ACP
"""
###Suggested citation (will be updated on pre-print and publication):
##Pascale, A., Watson, J., Davis, D., Smart, S., Braer, M., Jones,R., Greig, C. Negotiating risks to natural capital and stakeholder values in net-zero transitions. In progress. (2024).
# _______________________________________________________________________________________________________________________#

###START CODE
# _______________________________________________________________________________________________________________________#
# mapVRE+ GLOBAL SETUP#

import arcpy, os, sys, csv, time
from arcpy import env
from arcpy.sa import *
import pandas as pd
import re
from collections import OrderedDict
from datetime import datetime
#import numpy as np

#ScriptStartTimer
ScriStart_time = time.time()

#set up base and working directories
baseDir    = os.getcwd()
gispath    = baseDir + "\\d0_4gis\\"
resultpath = baseDir + "\\d0_3results\\"
scriptpath = baseDir + "\\d0_2code\\"
logpath    = baseDir + "\\d0_3results\\"
os.chdir ( scriptpath )
sys.path.append ( scriptpath )

# FIXED PARAMETERS
days = 365
hourdy = 24
houryr = days * hourdy

#read in scenarios and cases -- this has inelegance due to newbie-ish coding
mastercsv_ = pd.read_csv( scriptpath + "\\parameters\\" + "mvp0_setup.csv" , header=None)

#set the scenarios and cases to run--should be based on rows with entries in row 1, but using workaround
mastercsv = mastercsv_.iloc[3:len(mastercsv_.index),pd.to_numeric(mastercsv_.iloc[1,2]):(pd.to_numeric(mastercsv_.iloc[2,2])+1)]

# END mapVRE+ GLOBAL SETUP#
# _______________________________________________________________________________________________________________________#

#d#column = 3
for column in mastercsv:
    ColStart_time = time.time()
    #_______________________________________________________________________________________________________________________#
    # mapVRE+ STAGE 0 - Setup#

    ###REFERENCES
    #https://pro.arcgis.com/en/pro-app/latest/tool-reference/environment-settings/maintain-attachments.htm
    #https://pro.arcgis.com/en/pro-app/latest/tool-reference/environment-settings/parallel-processing-factor.htm
    #https://pro.arcgis.com/en/pro-app/3.1/help/analysis/geoprocessing/basics/the-in-memory-workspace.htm
    
    data = mastercsv[column].reset_index(drop=True)

    # Note that the Stage/Option assinments below note the first time the variables are used in a full run. Variables are often used across multiple stage/options.
    # RUN PARAMETERS AND OUTPUT FILE NAMING#
    startStage     = int(data[0]) # int(input("Start from which modelling stage Bx? x= "))
    endStage       = int(data[1]) # int(input("End on which modelling stage Bx? y= "))
    redoBase_route = int(data[2])
    redoBase_cost  = int(data[3])
    redoSurf_exist = int(data[4])
    redoSubs       = int(data[5])
    redoSurf_spur  = int(data[6])
    redoSurf_bulk  = int(data[7])
    redoSurf_sink  = int(data[8])
    redoSurf_exp   = int(data[9])
    Resource       = data[10]
    Version        = data[11]
    Subversion     = data[12]
    exCase         = data[13]
    # WORKSPACE INPUTS #
    RootDir        = gispath + data[14]
    OutputGDB      = gispath + data[15]
    ScratchGDB     = gispath + data[16]
    TemplateRaster = gispath + data[17]
    CountryBounds  = gispath + data[18]
    ResourceInput  = gispath + data[19]
    ResourceType   = data[20]
    PowerDensity   = float(data[21])
    prefix         = Resource + "_v" + Version + "_" + Subversion + "_pd" + re.sub('\.','d', str(PowerDensity) ) + "_"
    # STAGE 1 variables #
    Stage1CSVInput = scriptpath + data[22]
    csvOUT         = resultpath + data[23]
    redoLayers     = int(data[24])
    heatmaps       = int(data[25])
    S1Output       = ScratchGDB + "\\_" + prefix + "S1" + "_case" + exCase
    ifTrue         = 1
    ifFalse        = 0
    # STAGE 2 variables #
    FishnetSize    = int(data[26])
    MinContigArea  = float(data[27])
    #MaxArea        = float(data[28]) #FishnetSize**2   ###NOT USED IN REWRITE, BUT KEPT IN CASE NEEDED LATER FOR SOME REASON - CURRENTLY FISHNET SIZE DETERMINeS THIS
    FishnetDir     = RootDir
    S2Output       = ScratchGDB + "\\_" + prefix + "S2" + "_case" + exCase
    # STAGE 3 variables #
    Stage3CSVInput = scriptpath + data[29]
    S3Output       = ScratchGDB + "\\_" + prefix + "S3"  + "_case" + exCase

    LandUseDiscnt  = float(data[30])
    # OPTION A1 variables - Redo routing surfaces to existing TX #
    gdbTX          = gispath + data[31]
    existTX        = gispath + data[32]
    elevSurf       = gispath + data[33]
    routeSurf      = gispath + data[34]
    # OPTION A2 variables - Redo generalized substations using CPAs and existing substations #
    W              = gispath + data[35]
    O              = gispath + data[36]
    P              = gispath + data[37]
    routeField     = data[38]
    subBuf         = data[39]
    #routeType      = "EACH_CELL"
    # OPTION A3 variables - Redo routing surfaces to substations (for spur lines) #
    destTX         = gispath + data[40]
    # OPTION A4 variables - Redo routing surfaces to MSA locations #
    destBulk       = gispath + data[41]
    # OPTION A5 variables - Redo routing surfaces to MSA locations #
    destSink       = gispath + data[42]
    # OPTION A6 variables - Redo routing surfaces to export Node locations #
    destExport     = gispath + data[43]
    # STAGE 4 variables - Create Spur Lines to TX grid #
    S4Output       = OutputGDB + "\\_" + prefix + "S4"  + "_case" + exCase
    routeBuf       = data[44]
    costSurf       = gispath + data[45]
    destLand       = gispath + data[46]
    regNZAu        = gispath + data[47]
    regAUS         = gispath + data[48]
    # STAGE 5 variables - Create bulk TX Lines to from selected grid feature to nearest MSA (this only does one, not multiple MSAs) #
    S5Output       = OutputGDB + "\\_" + prefix + "S5"  + "_case" + exCase
    bulkField      = data[49]
    # STAGE 6 variables - Create sink TX Lines to nearest regional sink (typically largest and nearest regional MSA - does not need to be in same region) #
    S6Output       = OutputGDB + "\\_" + prefix + "S6"  + "_case" + exCase
    # STAGE 7 variables - Create spur TX Lines from cpa to nearest export node #
    S7Output       = OutputGDB + "\\_" + prefix + "S7"  + "_case" + exCase
    # STAGE 8 variables - Combine all infrastrcture to project#
    S8Output       = OutputGDB + "\\_" + prefix + "S8"  + "_case" + exCase

    #set up logging -- a bit clumsy, should pass logfile name as well
    # from https://community.esri.com/t5/geoprocessing-questions/write-all-add-messages-to-text-file/td-p/1013387
    logfile = open(logpath + prefix + "case" + exCase + "_log.txt", 'a' )
    def WriteMsg(strMsg):
        arcpy.AddMessage(strMsg)
        logfile.write(strMsg + "\n")
        return

    WriteMsg("Column Run for column " + str(column) + " in masterCSV parameter file." )
    WriteMsg( "mapVRE+ Setup done" )
    WriteMsg("Sase directory: " + baseDir)

    #get date and time
    #from https://www.programiz.com/python-programming/datetime/current-datetime
    now = datetime.now()
    dt_fin = now.strftime("%d/%m/%Y %H:%M:%S")

    #Report on setup
    WriteMsg("Run = " + prefix )
    WriteMsg(dt_fin)
    WriteMsg("MapVRE+:Start Stage = " + str(startStage))
    WriteMsg("MapVRE+:End Stage = " + str(endStage))
    WriteMsg("Selected RUN STAGES:")
    if startStage <= 1 and endStage >= 1:
        WriteMsg("STAGE 1 - COMBINE EXCLUSION LAYERS and REMOVE EXCLUSIONS FROM SOLAR AND WIND RESOURCES [fork of MapRE B1]")
    if startStage <= 2 and endStage >= 2:
        WriteMsg("STAGE 2 - SEPARATE RESOURCE LAYER INTO PROJECT SITES OF SPECIFIED SIZE/CAPACITY [fork of MapRE B2]")
    if startStage <= 3 and endStage >= 3:
        WriteMsg("STAGE 3 - DETERMINE BASE PROJECT ATTRIBUTES such as PROJECT CAPACITY,ANNUAL LOSSLESS GENERATION, and USER DEFINED ATTRIBUTES [fork of MapRE B3]")
    if startStage <= 4 and endStage >= 4:
        WriteMsg("STAGE 4 - SPUR LINE GENERATION FOR ALL CPAs to a) existing TX or b) MSA [NZAu developed from manual processes used for NZA,PoPW, REPEAT]")
    if startStage <= 5 and endStage >= 5:
        WriteMsg("STAGE 5 - BULK LINE GENERATION connecting all spur lines (not already connected to a MSA) to nearest MSA [NZAu developed from manual processes used for NZA,PoPW, REPEAT]")
    if startStage <= 6 and endStage >= 6:
        WriteMsg("STAGE 6 - SINK LINE GENERATION connecting all spur lines (not already connected to a MSA) to nearest sink MSA [NZAu developed from manual processes used for NZA,PoPW, REPEAT]")
    if startStage <= 7 and endStage >= 7:
        WriteMsg("STAGE 7 - EXPORT SINK LINE GENERATION connecting all export specific CPAs with EXPORT power aggregation nodes [NZAu]")
    if startStage <= 8 and endStage >= 8:
        WriteMsg("STAGE 8 - COMBINE INFRASTRUCTURE linked to each projects into a project layer with all relevant OIDs")
    WriteMsg("MapVRE+:Redo base route surface for all TX - "  + ( "NO" if redoBase_route == 0 else "YES" ) )
    WriteMsg("MapVRE+:Redo base cost surface for all TX - "   + ( "NO" if redoBase_cost == 0 else "YES" ) )
    WriteMsg("MapVRE+:Redo existing tx cost surface - "       + ( "NO" if redoSurf_exist == 0 else "YES" ) )
    WriteMsg("MapVRE+:Redo available substation locations - " + ( "NO" if redoSubs == 0 else "YES" ) )
    WriteMsg("MapVRE+:Redo spur tx cost surface - "           + ( "NO" if redoSurf_spur == 0 else "YES" ) )
    WriteMsg("MapVRE+:Redo bulk tx cost surface - "           + ( "NO" if redoSurf_bulk == 0 else "YES" ) )
    WriteMsg("MapVRE+:Redo sink tx cost surface - "           + ( "NO" if redoSurf_sink == 0 else "YES" ) )
    WriteMsg("MapVRE+:Redo export spur tx cost surface - "    + ( "NO" if redoSurf_exp == 0 else "YES" ) )

    #Set Environment
    arcpy.CheckOutExtension("Spatial")
    arcpy.CheckOutExtension("GeoStats")
    arcpy.env.overwriteOutput = True
    arcpy.env.workspace = ScratchGDB
    arcpy.env.extent = TemplateRaster
    arcpy.env.mask = TemplateRaster
    arcpy.env.snapRaster = TemplateRaster
    arcpy.env.cellSize = TemplateRaster
    arcpy.env.scratchWorkspace = ScratchGDB
    env.outputCoordinateSystem = TemplateRaster
    arcpy.env.parallelProcessingFactor = "0"
    arcpy.env.maintainAttachments = True

    # mapVRE+ SETUP END STAGE 0
    #_______________________________________________________________________________________________________________________#

    #_______________________________________________________________________________________________________________________#
    # STAGE 1 # COMBINE EXCLUSION LAYERS and REMOVE EXCLUSIONS FROM SOLAR AND WIND RESOURCES #

    ###FUNCTIONS CALLED and REFERENCES
    #https://pro.arcgis.com/en/pro-app/3.0/tool-reference/spatial-analyst/is-null.htm
    #https://community.esri.com/t5/python-snippets-questions/conbining-rasters-with-con-isnull/td-p/700027
    # IsNull(in_raster)
    #https://pro.arcgis.com/en/pro-app/3.1/tool-reference/spatial-analyst/con-.htm
    # Con(in_conditional_raster, in_true_raster_or_constant, {in_false_raster_or_constant}, {where_clause})
    #https://pro.arcgis.com/en/pro-app/3.1/tool-reference/data-management/copy-raster.htm
    # arcpy.management.CopyRaster(in_raster, out_rasterdataset, {config_keyword}, {background_value}, {nodata_value}, {onebit_to_eightbit}, {colormap_to_RGB}, {pixel_type}, {scale_pixel_value}, {RGB_to_Colormap}, {format}, {transform}, {process_as_multidimensional}, {build_multidimensional_transpose})
    #https://pro.arcgis.com/en/pro-app/latest/tool-reference/data-management/delete.htm
    # arcpy.management.Delete(in_data, {data_type})
    #https://pro.arcgis.com/en/pro-app/3.1/arcpy/spatial-analyst/raster-calculator.htm
    # RasterCalculator (rasters, input_names, expression, {extent_type}, {cellsize_type})
    #https://pro.arcgis.com/en/pro-app/latest/tool-reference/conversion/raster-to-polygon.htm
    # arcpy.conversion.RasterToPolygon(in_raster, out_polygon_features, {simplify}, {raster_field}, {create_multipart_features}, {max_vertices_per_feature})
    #https://pro.arcgis.com/en/pro-app/latest/tool-reference/spatial-analyst/zonal-statistics-as-table.htm
    # ZonalStatisticsAsTable(in_zone_data, zone_field, in_value_raster, out_table, {ignore_nodata}, {statistics_type}, {process_as_multidimensional}, {percentile_values}, {percentile_interpolation_type}, {circular_calculation}, {circular_wrap_value}, {out_join_layer})
    #https://pro.arcgis.com/en/pro-app/latest/tool-reference/data-management/copy-rows.htm
    # arcpy.management.CopyRows(in_rows, out_table, {config_keyword})

    if startStage <= 1 and endStage >= 1:
        WriteMsg("S1:Starting S1")
        start_time = time.time()

        WriteMsg( "S1:Running " + Resource + " case " + exCase + ": process Layers = " + str(redoLayers) + ", heatmaps = " + str(heatmaps)  )

        def getFields(data):
            fieldList = []
            fields = arcpy.ListFields(data)
            for field in fields:
                fieldList.append(field.name)
            return fieldList

        #GET INPUTS FROM CSV FILE
        with open(Stage1CSVInput + "_case" + exCase + ".csv" , "rt") as csvfile:
            reader = csv.reader(csvfile, delimiter=',')
            fields = next(reader)
            inputData = []
            for row in reader:
                inputData.append(dict(zip(fields, row)))

        #inputDataPath is a dictionary of all the input datasets
        inputDataPath = {}

        #populate the inputDataPath for each of the data categories.
        for dataCategory in fields:
            inputDataPath.update({dataCategory: [inputData[0][dataCategory], gispath + inputData[1][dataCategory], inputData[2][dataCategory]]})

        #d#constraint = 'slope'
        #d#i = 27
        cntRas = 0
        exList = []
        evList = []
        if redoLayers == 1:
            for i,constraint in enumerate(inputDataPath):
                if inputDataPath[constraint][0] == "yes":
                    WriteMsg( "S1:Starting raster calculation for " + constraint)
                    cntRas += 1
                    outSav = ScratchGDB + "\\ext" + str(i) + "_" + constraint
                    if "<" in inputDataPath[constraint][2]:
                        ras = Con(IsNull(inputDataPath[constraint][1]), inputDataPath[constraint][1], 100, "Value=0")
                    else:
                        ras = Con(IsNull(inputDataPath[constraint][1]), inputDataPath[constraint][1], 0, "Value=0")
                    arcpy.management.CopyRaster(ras, outSav + "Ful")
                    arcpy.management.Delete(ras)
                    WriteMsg("S1:DONE-full")
                    if "<" in inputDataPath[constraint][2]:
                        ras = Con(outSav + "Ful", inputDataPath[constraint][1], 100, str(inputDataPath[constraint][2]))
                    else:
                        ras = Con(outSav + "Ful", inputDataPath[constraint][1], ifFalse, str(inputDataPath[constraint][2]))
                    arcpy.management.CopyRaster(ras, outSav + "Lim")
                    arcpy.management.Delete(ras)
                    arcpy.management.Delete(outSav + "Ful")
                    WriteMsg("S1:DONE-limited")
                    ras = Con(outSav + "Lim", ifTrue, ifFalse, str(inputDataPath[constraint][2]))
                    arcpy.management.CopyRaster(RasterCalculator ([ras], "x", "INT(x)"), outSav + "Bin" + "_" + Resource)
                    arcpy.management.Delete(ras)
                    arcpy.management.Delete(outSav + "Lim")
                    tab = ZonalStatisticsAsTable( regAUS , "ISO_SUB", outSav + "Bin" + "_" + Resource, ScratchGDB + "\\tab", "DATA", "SUM")
                    #arcpy.management.CopyRows(tab, csvOUT + constraint + "_" + Resource + ".csv")
                    #arcpy.management.Delete(csvOUT + constraint + "_" + Resource + ".csv.xml")
                    #arcpy.management.Delete(csvOUT + "schema.ini")
                    arcpy.management.Delete(tab)
                    WriteMsg("S1:DONE-binary")
                    exList.append(outSav + "Bin" + "_" + Resource)
                    evList.append("v" + str(cntRas))
                    eform = "INT (v1" if cntRas == 1 else ( eform + "+v" + str(cntRas) )
            WriteMsg("S1:Finished exclusion raster overlay loop")

        #code for using if need to rerun layers
        if redoLayers == 0:
            for i,constraint in enumerate(inputDataPath):
                if inputDataPath[constraint][0] == "yes":
                    cntRas += 1
                    outSav = ScratchGDB + "\\ext" + str(i) + "_" + constraint
                    exList.append(outSav + "Bin" + "_" + Resource)
                    evList.append("v" + str(cntRas))
                    eform = "INT (v1" if cntRas == 1 else ( eform + "+v" + str(cntRas) )

        if heatmaps == 1:
            ras = RasterCalculator(exList, evList, eform + ")")
            WriteMsg("S1:Finished raster calculator for exclusion heatmaps")
            arcpy.management.CopyRaster( ras, ScratchGDB + "\\exclusionHeatMap_ras_" + Resource + "_case" + exCase + "_layers" + str(cntRas))
            arcpy.management.Delete(ras)
            WriteMsg("S1:Finished exclusion raster heatmap")
            ras = Con( ScratchGDB + "\\exclusionHeatMap_ras_" + Resource + "_case" + exCase + "_layers" + str(cntRas), ifTrue, ifFalse, "Value>0")
            arcpy.management.CopyRaster(ras, ScratchGDB + "\\exclusionFlat_ras_" + Resource + "_case" + exCase + "_layers" + str(cntRas))
            tab = ZonalStatisticsAsTable(regAUS, "ISO_SUB", ScratchGDB + "\\exclusionFlat_ras_" + Resource + "_case" + exCase + "_layers" + str(cntRas), ScratchGDB + "\\tab", "DATA", "SUM")
            #arcpy.management.CopyRows(tab, csvOUT + Resource + "_case" + exCase + "_layers" + str(cntRas) + ".csv")
            #arcpy.management.Delete(csvOUT + Resource + "_case" + exCase + "_layers" + str(cntRas) + ".csv.xml")
            #arcpy.management.Delete(csvOUT + "schema.ini")
            arcpy.management.Delete(tab)
            WriteMsg("S1:Finished exclusion raster flatmap")
            ##generate S1 output
            ras = OutputGDB + "\\exclusionFlat_ras_" + Resource + "_case" + exCase + "_layers" + str(cntRas)
            rass = SetNull(ras, 1, "Value=1")
            #arcpy.management.CopyRaster( rass, S1Output + "_ras")
            arcpy.conversion.RasterToPolygon( rass , S1Output , "NO_SIMPLIFY" , "Value" , "MULTIPLE_OUTER_PART" )
            #arcpy.conversion.RasterToPolygon( S1Output + "_ras", S1Output  , "NO_SIMPLIFY", "Value", "MULTIPLE_OUTER_PART")
            #arcpy.management.Delete( ras )
            arcpy.management.Delete( rass )
            #arcpy.management.Delete(S1Output + "_ras")   ##raster is not used for the rest of teh processes, not saving and deleting the raster
            WriteMsg( "S1: Finished flattened S1 output")
        if heatmaps == 0:
            WriteMsg("S1: If any layers were redone, or heatmaps != 1, Note that no (new) S1 output will be created - Stage 1 must be run again with heatmaps == 1")

        #delete memory at end of stage
        arcpy.management.Delete("memory")
        end_time = time.time()
        WriteMsg("S1:Memory cache deleted, END mapVRE+ S1 taking " + str ( round ( (end_time - start_time)/60 , 1 ) ) + " minutes.")

    # END STAGE 1 #
    #_______________________________________________________________________________________________________________________#

    #_______________________________________________________________________________________________________________________#
    # STAGE 2 # SEPARATE RESOURCE LAYER INTO PROJECT SITES OF SPECIFIED SIZE/CAPACITY #

    ###FUNCTIONS CALLED and REFERENCES
    #https://pro.arcgis.com/en/pro-app/latest/tool-reference/data-management/create-fishnet.htm
    # arcpy.management.CreateFishnet(out_feature_class, origin_coord, y_axis_coord, cell_width, cell_height, number_rows, number_columns, {corner_coord}, {labels}, {template}, {geometry_type})
    #https://pro.arcgis.com/en/pro-app/latest/tool-reference/conversion/export-features.htm
    # arcpy.conversion.ExportFeatures(in_features, out_features, {where_clause}, {use_field_alias_as_name}, {field_mapping}, {sort_field})
    #https://pro.arcgis.com/en/pro-app/latest/tool-reference/analysis/intersect.htm
    # arcpy.analysis.Intersect(in_features, out_feature_class, {join_attributes}, {cluster_tolerance}, {output_type})
    #https://pro.arcgis.com/en/pro-app/latest/tool-reference/analysis/clip.htm
    # arcpy.analysis.Clip(in_features, clip_features, out_feature_class, {cluster_tolerance})
    #https://pro.arcgis.com/en/pro-app/latest/tool-reference/analysis/erase.htm
    # arcpy.analysis.Erase(in_features, erase_features, out_feature_class, {cluster_tolerance})
    #https://pro.arcgis.com/en/pro-app/latest/tool-reference/data-management/multipart-to-singlepart.htm
    # arcpy.management.MultipartToSinglepart(in_features, out_feature_class)
    #https://pro.arcgis.com/en/pro-app/latest/tool-reference/data-management/add-field.htm
    # arcpy.management.AddField(in_table, field_name, field_type, {field_precision}, {field_scale}, {field_length}, {field_alias}, {field_is_nullable}, {field_is_required}, {field_domain})
    #https://pro.arcgis.com/en/pro-app/latest/tool-reference/data-management/calculate-field.htm
    # arcpy.management.CalculateField(in_table, field, expression, {expression_type}, {code_block}, {field_type}, {enforce_domains})
    #https://pro.arcgis.com/en/pro-app/latest/tool-reference/data-management/delete-field.htm
    # arcpy.management.DeleteField(in_table, drop_field, {method})
    #https://pro.arcgis.com/en/pro-app/latest/tool-reference/data-management/delete.htm
    # arcpy.management.Delete(in_data, {data_type})
    #https://pro.arcgis.com/en/pro-app/latest/tool-reference/feature-analysis/dissolve-boundaries.htm
    # arcpy.sfa.DissolveBoundaries(inputLayer, outputName, {dissolveFields}, {summaryFields})
    # https://support.esri.com/en-us/knowledge-base/error-usessoidentityifportalowned-was-not-found-failed-000022251
    #https://pro.arcgis.com/en/pro-app/latest/tool-reference/data-management/merge.htm
    # arcpy.management.Merge(inputs, output, {field_mappings}, {add_source})

    if startStage <= 2 and endStage >= 2:
        WriteMsg("S2:Starting S2 with " + S1Output )
        start_time = time.time()

        fishnetSizeStr = str(FishnetSize).replace(".", "_")
        Fishnet = FishnetDir + "\\" + "fishnet_" + fishnetSizeStr + "km"

        if not (arcpy.Exists(Fishnet)):
            #Create fishnet if one does not already exist:
            WriteMsg("S2:Creating fishnet " + fishnetSizeStr + " km in size to memory")
            extent = Raster(TemplateRaster).extent
            XMin = extent.XMin  # left
            YMin = extent.YMin  # Bottom
            origin = str(XMin) + " " + str(YMin)
            YMax = extent.YMax  # top
            ycoord = str(XMin) + " " + str(YMax)
            fish = arcpy.CreateFishnet_management( r"memory\fishnet_" + fishnetSizeStr + "km" , origin, ycoord, FishnetSize * 1000, FishnetSize * 1000,  "", "", "", "NO_LABELS", extent, "POLYGON")
            WriteMsg("S2:Fishnet Generated")
            arcpy.conversion.ExportFeatures(fish, Fishnet)
            WriteMsg("S2:Creating template extent fishnet " + fishnetSizeStr  + " km in size to file: " + Fishnet)

        fish = arcpy.conversion.ExportFeatures(Fishnet, r"memory\fishnet_" + fishnetSizeStr + "km")
        WriteMsg("S2:Copying fishnet to memory :" + Fishnet)

        # COPY SUITABLE SITES FEATURE CLASS TO MEMORY
        sites = arcpy.conversion.ExportFeatures(S1Output, r"memory\suitableSites")
        WriteMsg("S2:Suitable sites in memory :" + S1Output)

        #Intersect sites with fishnet
        fished = arcpy.Intersect_analysis([sites, fish], r"memory\fished", "NO_FID")
        if Resource != "off":
            fishclip = arcpy.Clip_analysis(fished, CountryBounds, ScratchGDB + "\\fishclip")
            WriteMsg("S2:Finished intersecting total site area with fishnet and clipping to country bounds")
        else:
            fishclip = arcpy.analysis.Erase(fished, CountryBounds, ScratchGDB + "\\fishclip")
            WriteMsg("S2:Finished intersecting total site area with fishnet and clipping to offshore")

        #intermediate dump of memory in preperation for final processing steps
        arcpy.management.Delete("memory")
        WriteMsg("S2:Intermediate dump of memory cache")

        fishclipS = arcpy.management.MultipartToSinglepart(ScratchGDB + "\\fishclip", r"memory\fishclipSingle")
        arcpy.management.DeleteField(fishclipS, ["Shape_Area"], method="KEEP_FIELDS")
        fishclipSS = arcpy.conversion.ExportFeatures(fishclipS, ScratchGDB + "\\fishclipS")
        arcpy.management.Delete(fishclipS)
        arcpy.management.Delete(fishclip)
        WriteMsg("S2:Sites Multipart to single")
        arcpy.management.AddField(fishclipSS, "areakm", "DOUBLE")
        arcpy.management.CalculateField(fishclipSS, "areakm", "!Shape_Area!/1000000" , "PYTHON3" )
        arcpy.conversion.ExportFeatures(fishclipSS, ScratchGDB + "\\fishclipA" ,  " \"areakm\" >= " + str(MinContigArea) )
        WriteMsg("S2:Sites part A: remove all singlepart sites below minimum contiguous field threshold")

        ##THIS SECTION IS NOT WORKING DUE TO A CERTIFICATE ISSUE??? BUT IS MEANT TO ALLOW SOME SMALLER SITES ON BOUNDARIES OF FISHNET TO BECOME AVAILABLE WHEN AGGREGATED
        #arcpy.conversion.ExportFeatures(fishclipSS, ScratchGDB + "\\fishclipB", " \"areakm\" < " + str(MinContigArea))
        #arcpy.management.Delete(fishclipSS)
        #arcpy.sfa.DissolveBoundaries( ScratchGDB + "\\fishclipB" , ScratchGDB + "\\fishclipC")  ##need to run manually in arcGIS until fix portal problem
        #arcpy.management.Delete(ScratchGDB + "\\fishclipB")
        #arcpy.conversion.ExportFeatures( ScratchGDB + "\\fishclipC" , ScratchGDB + "\\fishclipD", " \"areakm\" >= " + str(MinContigArea))
        #arcpy.management.Delete(ScratchGDB + "\\fishclipC")
        #arcpy.management.Merge( [ScratchGDB + "\\fishclipA", ScratchGDB + "\\fishclipD"] , S2Output )
        #arcpy.management.Delete(ScratchGDB + "\\fishclipA")
        #arcpy.management.Delete(ScratchGDB + "\\fishclipD")
        #WriteMsg("S2:S2 Output can be found at:" + S2Output)

        #d#TEMP section until the above works
        arcpy.management.Delete(fishclipSS)
        arcpy.conversion.ExportFeatures( ScratchGDB + "\\fishclipA" , S2Output )
        arcpy.management.Delete(ScratchGDB + "\\fishclipA")
        WriteMsg("S2:S2 Output can be found at:" + S2Output)

        #delete memory at end of stage
        arcpy.management.Delete("memory")
        end_time = time.time()
        WriteMsg("S2:Memory cache deleted, END mapVRE+ S2 taking " + str ( round ( (end_time - start_time)/60 , 1 ) ) + " minutes.")

    # END STAGE 2 #
    #_______________________________________________________________________________________________________________________#

    #_______________________________________________________________________________________________________________________#
    # STAGE 3 # DETERMINE BASE PROJECT ATTRIBUTES such as PROJECT CAPACITY,ANNUAL LOSSLESS GENERATION, and USER DEFINED ATTRIBUTES #

    ###FUNCTIONS CALLED and REFERENCES
    #https://pro.arcgis.com/en/pro-app/latest/tool-reference/conversion/polygon-to-raster.htm
    # arcpy.conversion.PolygonToRaster(in_features, value_field, out_rasterdataset, {cell_assignment}, {priority_field}, {cellsize}, {build_rat})
    #https://pro.arcgis.com/en/pro-app/latest/tool-reference/analysis/near.htm
    # arcpy.analysis.Near(in_features, near_features, {search_radius}, {location}, {angle}, {method}, {field_names}, {distance_unit})
    #https://pro.arcgis.com/en/pro-app/latest/tool-reference/data-management/add-field.htm
    # arcpy.management.AddField(in_table, field_name, field_type, {field_precision}, {field_scale}, {field_length}, {field_alias}, {field_is_nullable}, {field_is_required}, {field_domain})
    #https://pro.arcgis.com/en/pro-app/latest/tool-reference/data-management/calculate-field.htm
    # arcpy.management.CalculateField(in_table, field, expression, {expression_type}, {code_block}, {field_type}, {enforce_domains})
    #https://pro.arcgis.com/en/pro-app/latest/tool-reference/data-management/delete-field.htm
    # arcpy.management.DeleteField(in_table, drop_field, {method})
    #https://pro.arcgis.com/en/pro-app/latest/tool-reference/spatial-analyst/zonal-statistics-as-table.htm
    # ZonalStatisticsAsTable(in_zone_data, zone_field, in_value_raster, out_table, {ignore_nodata}, {statistics_type}, {process_as_multidimensional}, {percentile_values}, {percentile_interpolation_type}, {circular_calculation}, {circular_wrap_value}, {out_join_layer})
    #https://pro.arcgis.com/en/pro-app/latest/tool-reference/data-management/join-field.htm
    # arcpy.management.JoinField(in_data, in_field, join_table, join_field, {fields}, {fm_option}, {field_mapping}, {index_join_fields})

    if startStage <= 3 and endStage >= 3:
        WriteMsg("S3:Starting S3 with " + S2Output )
        start_time = time.time()

        #COPY SUITABLE SITES FEATURE CLASS TO MEMORY AND TO RASTER for use in analyses
        projects = arcpy.conversion.ExportFeatures(S2Output, r"memory\suitableSites")
        projects_ras = arcpy.conversion.PolygonToRaster( S2Output, "OBJECTID" , r"memory\projects_ras" )
        WriteMsg("S3:Suitable sites in memory; suitable site raster in memory for analyses with OBJECTID saved as raster value")

        #READ ATTRIBUTES FOR ANALYSIS
        with open(Stage3CSVInput, "rt") as csvfile:
            reader = csv.reader(csvfile, delimiter=',')
            fields = next(reader)
            inputData = []
            for row in reader:
                inputData.append(dict(zip(fields, row)))
        #inputDataPath is a dictionary of all the input datasets
        inputDataPath = OrderedDict()
        #populate the inputDataPath for each of the data categories.
        for dataCategory in fields:
            inputDataPath[dataCategory] = [inputData[0][dataCategory],  inputData[1][dataCategory], gispath + inputData[2][dataCategory]]
        WriteMsg("S3:Attribute list read from " + Stage3CSVInput)

        #SELECTED ATTRIBUTE ANALYSIS
        #d#dataCategory = "d_trans"
        for dataCategory in inputDataPath:
            if inputDataPath[dataCategory][0] == "yes" and inputDataPath[dataCategory][1] == "distance":
                afeature = inputDataPath[dataCategory][2]
                afieldName = dataCategory
                arcpy.analysis.Near(projects, afeature )
                arcpy.management.AddField(projects, afieldName, "DOUBLE")
                arcpy.management.CalculateField(projects, afieldName, "!NEAR_DIST!/1000" ,  "PYTHON3")
                arcpy.management.DeleteField(projects, "NEAR_DIST")
                arcpy.management.DeleteField(projects, "NEAR_FID")
                WriteMsg(afieldName + " distance calculation complete")

        #d#dataCategory = "m_elev"
        for dataCategory in inputDataPath:
            if inputDataPath[dataCategory][0] == "yes" and inputDataPath[dataCategory][1] == "mean":
                afeature = inputDataPath[dataCategory][2]
                afieldName = dataCategory
                tab = ZonalStatisticsAsTable(projects_ras, "Value", afeature, r"memory\zonalStats", "DATA", "MEAN")
                arcpy.management.JoinField(projects, "OBJECTID" ,  r"memory\zonalStats", "Value", "MEAN")
                arcpy.management.AddField(projects, afieldName, "DOUBLE")
                arcpy.management.CalculateField(projects, afieldName, "!MEAN!", "PYTHON3")
                arcpy.management.DeleteField(projects, "MEAN")
                arcpy.management.Delete(tab)
                WriteMsg("Mean Zonal stats for " + afieldName + " is complete")

        #d#dataCategory = "m_AUSs_maj"
        for dataCategory in inputDataPath:
            if inputDataPath[dataCategory][0] == "yes" and inputDataPath[dataCategory][1] == "majority":
                afeature = inputDataPath[dataCategory][2]
                afieldName = dataCategory
                afeature_int = Int(afeature)
                tab = ZonalStatisticsAsTable(projects_ras, "Value", afeature_int, r"memory\zonalStats", "DATA", "MAJORITY")
                arcpy.management.JoinField(projects, "OBJECTID" ,  r"memory\zonalStats", "Value", "MAJORITY")
                arcpy.management.AddField(projects, afieldName, "DOUBLE")
                arcpy.management.CalculateField(projects, afieldName, "!MAJORITY!", "PYTHON3")
                arcpy.management.DeleteField(projects, "MAJORITY")
                arcpy.management.Delete(tab)
                WriteMsg("Majority Zonal stats for " + afieldName + " is complete")

        #d#dataCategory = "m_slope_med"
        for dataCategory in inputDataPath:
            if inputDataPath[dataCategory][0] == "yes" and inputDataPath[dataCategory][1] == "median":
                afeature = inputDataPath[dataCategory][2]
                afieldName = dataCategory
                tab = ZonalStatisticsAsTable(projects_ras, "Value", afeature, r"memory\zonalStats", "DATA", "MEDIAN")
                arcpy.management.JoinField(projects, "OBJECTID" ,  r"memory\zonalStats", "Value", "MEDIAN")
                arcpy.management.AddField(projects, afieldName, "DOUBLE")
                arcpy.management.CalculateField(projects, afieldName, "!MEDIAN!", "PYTHON3")
                arcpy.management.DeleteField(projects, "MEDIAN")
                arcpy.management.Delete(tab)
                WriteMsg("Median Zonal stats for " + afieldName + " is complete")

        #d#dataCategory = "m_landuse_var"
        for dataCategory in inputDataPath:
            if inputDataPath[dataCategory][0] == "yes" and inputDataPath[dataCategory][1] == "variety":
                afeature = inputDataPath[dataCategory][2]
                afieldName = dataCategory
                tab = ZonalStatisticsAsTable(projects_ras, "Value", afeature, r"memory\zonalStats", "DATA", "VARIETY")
                arcpy.management.JoinField(projects, "OBJECTID" ,  r"memory\zonalStats", "Value", "VARIETY")
                arcpy.management.AddField(projects, afieldName, "DOUBLE")
                arcpy.management.CalculateField(projects, afieldName, "!VARIETY!", "PYTHON3")
                arcpy.management.DeleteField(projects, "VARIETY")
                arcpy.management.Delete(tab)
                WriteMsg("Variety Zonal stats for " + afieldName + " is complete")

        #d#dataCategory = "m_windOld_cov"
        for dataCategory in inputDataPath:
            if inputDataPath[dataCategory][0] == "yes" and inputDataPath[dataCategory][1] == "coverage":
                afeature   = inputDataPath[dataCategory][2]
                aras       = IsNull(afeature)
                afieldName = dataCategory
                tabA = ZonalStatisticsAsTable(projects_ras, "Value", aras, r"memory\zonalStatsA", "DATA", "MAJORITY_PERCENT")
                tabB = ZonalStatisticsAsTable(projects_ras, "Value", aras, r"memory\zonalStatsB", "DATA", "MAJORITY")
                arcpy.management.JoinField(projects, "OBJECTID" ,  r"memory\zonalStatsA", "Value", "MAJORITY_PERCENT")
                arcpy.management.JoinField(projects, "OBJECTID" ,  r"memory\zonalStatsB", "Value", "MAJORITY")
                arcpy.management.AddField(projects, afieldName, "DOUBLE")
                arcpy.management.CalculateField(projects, afieldName, "float(!MAJORITY_PERCENT!) if !MAJORITY! is 0 else 100 - float(!MAJORITY_PERCENT!)" , "PYTHON3")
                arcpy.management.DeleteField(projects, "MAJORITY_PERCENT")
                arcpy.management.DeleteField(projects, "MAJORITY")
                arcpy.management.Delete(tabA)
                arcpy.management.Delete(tabB)
                arcpy.management.Delete(aras)
                WriteMsg("Variety Zonal stats for " + afieldName + " is complete")

        #ADD average values for RESOURCE (currently only takes CF) and then specify type
        tab = ZonalStatisticsAsTable(projects_ras, "Value", ResourceInput, r"memory\RQ", "DATA", "MEAN")
        arcpy.JoinField_management(projects, "OBJECTID" ,  r"memory\RQ", "Value", "MEAN")
        if ResourceType == "Capacity Factor":
            arcpy.management.AddField(projects, "m_cf", "DOUBLE")
            arcpy.management.CalculateField(projects, "m_cf", "!MEAN!", "PYTHON3")
        else:
            WriteMsg("Add handler for resource type = " + ResourceType )
        arcpy.management.DeleteField(projects, "MEAN")
        arcpy.management.Delete(tab)
        WriteMsg("Zonal stats for lossless " + ResourceType + " is complete (check if CF is lossless!?)")

        #create fields in fieldList if not already in original projects
        fieldList = ["m_cf_noloss" , "pDensity" , "luDiscount" , "incap",  "hourYr" , "egen"]
        for each in fieldList:
            arcpy.management.AddField(projects, each, "DOUBLE")

        ####m+:add legacy lossless cf... potentially to be changed if cd provided in layer includes losses.. add losses field and then calculate in feature set
        ###CF = CF_noloss * (1 - losses)
        ###reset m_cf as capacity factor after losses
        ###row.setValue("m_cf", CF)
        ###row.setValue("m_cf_noloss", CF_noloss)
        arcpy.management.CalculateField(projects, "m_cf_noloss", "!m_cf!", "PYTHON3")
        arcpy.management.CalculateField(projects, "pDensity", PowerDensity , "PYTHON3")
        arcpy.management.CalculateField(projects, "luDiscount", LandUseDiscnt , "PYTHON3")
        arcpy.management.CalculateField(projects, "incap", "!pDensity! * !luDiscount! * !areakm!", "PYTHON3")
        arcpy.management.CalculateField(projects, "hourYR", houryr , "PYTHON3")
        arcpy.management.CalculateField(projects, "egen", "!incap! * !m_cf! * !hourYR!" , "PYTHON3")
        WriteMsg("Added estimations for nameplate capacity (incap), annual simple project generation (egen)")
        WriteMsg("The Capacity Factor provided is assumed to be lossless - check the input layer for assumptions underlying, and adjust this code and supply curve code if not lossless, m_cf -> m_cf_lossless")

        ####ADD OID for later Calcs
        #if Resource == "pv":
        #    arcpy.management.AddField(projects, "OIDpv", "LONG")
        #    arcpy.management.CalculateField(projects, "OIDpv", "!OBJECTID!", "PYTHON3")
        #if Resource == "wind":
        #    arcpy.management.AddField(projects, "OIDwind", "LONG")
        #    arcpy.management.CalculateField(projects, "OIDwind", "!OBJECTID!", "PYTHON3")
        #if Resource == "off":
        #    arcpy.management.AddField(projects, "OIDoff", "LONG")
        #    arcpy.management.CalculateField(projects, "OIDoff", "!OBJECTID!", "PYTHON3")
        #WriteMsg("Added resource specific OID - if needed (to be checked)")

        #save S3output and csvs for key datasets
        arcpy.conversion.ExportFeatures(projects, S3Output)
        arcpy.management.CopyRows(projects, ScratchGDB + "\\" + prefix + "S3_case" + exCase )
        #arcpy.conversion.ExportTable(ScratchGDB + "\\" + prefix + "S3_case" + exCase , csvOUT + prefix + "S3_case" + exCase + "_cpa" + ".csv" )
        #arcpy.management.Delete(csvOUT + prefix + "S3_case" + exCase + "_cpa" + ".csv.xml")
        #arcpy.management.Delete(csvOUT + "schema.ini")
        #arcpy.management.Delete(ScratchGDB + "\\" + prefix + "S3_case" + exCase )
        WriteMsg("S3:Initial S3 Site Output can be found at:" + S3Output)
        #WriteMsg("S3:CSV for initial S3 site Output can be found at:" + csvOUT + prefix + "S3_case" + exCase + "_cpa.csv")

        #delete memory at end of stage
        arcpy.management.Delete("memory")
        end_time = time.time()
        WriteMsg("S3:Memory cache deleted, END mapVRE+ S3 taking " + str ( round ( (end_time - start_time)/60 , 1 ) ) + " minutes.")

    # END STAGE 3 #
    #_______________________________________________________________________________________________________________________#

    #_______________________________________________________________________________________________________________________#
    # OPTIONS # THIS STAGE IS A CONTAINER FOR OPTIONS TO REDO COST SURFACES USED IN OPTION A2 which creates proxy substation locations using existing transmission lines and CPAs #

    #-----------------------------#
    # OPTION A0 -- RASTER CALCULATOR string with which to make routing and costing surfaces #
    # Contributing surfaces must be manually 'costed'

    ###FUNCTIONS CALLED and REFERENCES
    #https://pro.arcgis.com/en/pro-app/3.1/arcpy/spatial-analyst/raster-calculator.htm
    # RasterCalculator (rasters, input_names, expression, {extent_type}, {cellsize_type})
    #https://pro.arcgis.com/en/pro-app/3.1/tool-reference/spatial-analyst/con-.htm
    # Con(in_conditional_raster, in_true_raster_or_constant, {in_false_raster_or_constant}, {where_clause})

    if redoBase_cost == 1 or redoBase_route == 1:
        start_time = time.time()
        WriteMsg( "Starting OptionA0: Generating new base route and/or cost surface for all TX work" )

        #set workspace to location of manually generated 'cost' rasters
        arcpy.env.workspace = gdbTX

        #calculate each surface
        if redoBase_route == 1:
            routeNoLim = RasterCalculator( ["_1r_GA_2020_AustralianCriticalMineralsOperatingMinesAndDeposits_3577_buf1Km_ras250m" , "_207rc_GA_2015_LandUse_DLCDv21_2015_3577_250m_wOff_scrub" , "_206rc_GA_2015_LandUse_DLCDv21_2015_3577_250m_wOff_desert" ,  "_205r_GA_2015_LandUse_DLCDv21_2015_3577_250m_wOff_waterSaltWetlands" ,  "_204rc_GA_CycloneHazard_TCHA_RP100_3577_ras250m_kmhr_above145" , "_202rc_GA_2021_Foundation_TXsubstations_3577_ras250m" ,  "_200rc_AUS_State_ausAlb_ras_aemo_routeCost_full" , "_10rc_GA_DEM2009_elevation_3577_250m_slopeDegrees_aemo" , "_9r_CAPD_terrMarine_buf_1km" ,  "_6r_GA_2016_TransInfra_airPnts_3577_merge3_buf1km_ras" ,  "_2rc_GA_2016_AREMI_builtUpAreas_3577_ras250m_aemo" ,  "_203rc_NZAu_UrbanRegional_mult_medHighLow_onOff_reclass2_div1e4" , "_4r_Defense_buf0km_ProhibPrac" , "_7r_DLCD_Farms_IRR_rainCrop_250m" , "_209r_GA_wTX132up_Rail_NatRoads_conveyors_OGWpipes_Buf250m_ras250m_isNull_5pref" ] , \
            ["a" , "b" , "c" , "d" , "e" , "f" , "g" , "h" , "i" , "j" , "k" , "l" , "m" , "n" , "o" ] , "a/100000 * b/100000 * c/100000 * d/100000 * e/100000 * f/100000 * g/100000 * h/100000 * i/100000 * j/100000 * k/100000 * l/10000 * m/100000 * n/100000 * o" )
            arcpy.management.CopyRaster(routeNoLim, ScratchGDB + "\\routeNoLim")
            WriteMsg("A0: Uncapped routing layer calculated")

            #reclassify routing surface to maximum of 700 or chosen roof; can parameterize the 'roof' and the maximum raster value. routeNoLim.maximum will return max, but takes a long time
            routeLim = Con ( ScratchGDB + "\\routeNoLim" , 700 , ScratchGDB + "\\routeNoLim" , "Value>=700" )
            arcpy.management.CopyRaster( routeLim, gdbTX + "\\routeCapped700_nzau")
            WriteMsg("A0: Routing layer capped at 700 and saved")
            arcpy.management.Delete( ScratchGDB + "\\routeNoLim" )
            arcpy.management.Delete(routeLim)
            arcpy.management.Delete("memory")

        if redoBase_cost == 1:
            routeBaseCost = RasterCalculator( ["_2rc_GA_2016_AREMI_builtUpAreas_3577_ras250m_aemo" , "_10rc_GA_DEM2009_elevation_3577_250m_slopeDegrees_aemo" , "_200rc_AUS_State_ausAlb_ras_aemo_routeCost_full" , "_202rc_GA_2021_Foundation_TXsubstations_3577_ras250m" , "_203rc_NZAu_UrbanRegional_mult_medHighLow_onOff_reclass2_div1e4" , "_204rc_GA_CycloneHazard_TCHA_RP100_3577_ras250m_kmhr_above145" , "_206rc_GA_2015_LandUse_DLCDv21_2015_3577_250m_wOff_desert" , "_207rc_GA_2015_LandUse_DLCDv21_2015_3577_250m_wOff_scrub"] , \
            ["a" , "b" , "c" , "d" , "e" , "f" , "g" , "h" ] , "a/100000 * b/100000 * c/100000 * d/100000 * e/10000 * f/100000 * g/100000 * h/100000" )
            arcpy.management.CopyRaster( routeBaseCost , gdbTX + "\\cost_nzau")
            WriteMsg("A0: Uncapped costing layer calculated and saved")
            arcpy.management.Delete("memory")

        #reset workspace location after generating surfaces
        arcpy.env.workspace = ScratchGDB

        end_time = time.time()
        WriteMsg("Option A0: Memory cache deleted, END Option A0 taking " + str ( round ( (end_time - start_time)/60 , 1 ) ) + " minutes.")

    # END OPTION A0 #
    #-----------------------------#
    #-----------------------------#
    # OPTION A1 -- REDO Existing TX routing cost surfaces #

    ###FUNCTIONS CALLED and REFERENCES
    #https://pro.arcgis.com/en/pro-app/latest/tool-reference/spatial-analyst/distance-accumulation.htm
    # DistanceAccumulation(in_source_data, {in_barrier_data}, {in_surface_raster}, {in_cost_raster}, {in_vertical_raster}, {vertical_factor}, {in_horizontal_raster}, {horizontal_factor}, {out_back_direction_raster}, {out_source_direction_raster}, {out_source_location_raster}, {source_initial_accumulation}, {source_maximum_accumulation}, {source_cost_multiplier}, {source_direction}, {distance_method})

    if redoSurf_exist == 1:
        start_time = time.time()
        WriteMsg( "Starting OptionA1: Generating dir and dist routing surfaces to use when routing spurs to a Transmission lines (no existing substations)" )

        #set location for routing cost surfaces for existing TX and generate
        Dir = ( gdbTX + "\\" + "eTXDir" )
        Dis = ( gdbTX + "\\" + "eTXDis" )
        DistAcc = DistanceAccumulation(existTX, in_cost_raster=routeSurf, in_surface_raster=elevSurf, out_back_direction_raster=Dir)
        DistAcc.save(Dis)

        #delete memory at end of stage
        arcpy.management.Delete("memory")
        end_time = time.time()
        WriteMsg("Option A1: Memory cache deleted, END Option A1 taking " + str ( round ( (end_time - start_time)/60 , 1 ) ) + " minutes.")

    # END OPTION A1 #
    #-----------------------------#
    # OPTION A2 -- REDO SUBSTATION SUPERSET - This is selected if end points to be used for spur TX routing are not limited to existing substations, and are determined instead by cpa availability #

    ###FUNCTIONS CALLED and REFERENCES
    #https://pro.arcgis.com/en/pro-app/latest/arcpy/functions/addmessage.htm
    # AddMessage (message)
    #https://pro.arcgis.com/en/pro-app/latest/tool-reference/conversion/export-features.htm
    # arcpy.conversion.ExportFeatures(in_features, out_features, {where_clause}, {use_field_alias_as_name}, {field_mapping}, {sort_field})
    #https://pro.arcgis.com/en/pro-app/latest/tool-reference/data-management/get-count.htm
    # arcpy.management.GetCount(in_rows)
    #https://pro.arcgis.com/en/pro-app/latest/tool-reference/data-management/merge.htm
    # arcpy.management.Merge(inputs, output, {field_mappings}, {add_source})
    #https://pro.arcgis.com/en/pro-app/latest/tool-reference/data-management/feature-to-point.htm
    # arcpy.management.FeatureToPoint(in_features, out_feature_class, {point_location})
    #https://pro.arcgis.com/en/pro-app/latest/tool-reference/spatial-analyst/optimal-path-as-line.htm
    # OptimalPathAsLine(in_destination_data, in_distance_accumulation_raster, in_back_direction_raster, out_polyline_features, {destination_field}, {path_type}, {create_network_paths})
    #https://pro.arcgis.com/en/pro-app/latest/tool-reference/analysis/intersect.htm
    # arcpy.analysis.Intersect(in_features, out_feature_class, {join_attributes}, {cluster_tolerance}, {output_type})
    #https://pro.arcgis.com/en/pro-app/latest/tool-reference/data-management/multipart-to-singlepart.htm
    # arcpy.management.MultipartToSinglepart(in_features, out_feature_class)
    #https://pro.arcgis.com/en/pro-app/latest/tool-reference/analysis/pairwise-buffer.htm
    # arcpy.analysis.PairwiseBuffer(in_features, out_feature_class, buffer_distance_or_field, {dissolve_option}, {dissolve_field}, {method}, {max_deviation})
    #https://pro.arcgis.com/en/pro-app/latest/tool-reference/analysis/pairwise-dissolve.htm
    # arcpy.analysis.PairwiseDissolve(in_features, out_feature_class, {dissolve_field}, {statistics_fields}, {multi_part}, {concatenation_separator})
    #https://pro.arcgis.com/en/pro-app/latest/tool-reference/data-management/feature-to-point.htm
    # arcpy.management.FeatureToPoint(in_features, out_feature_class, {point_location})
    #https://pro.arcgis.com/en/pro-app/latest/tool-reference/analysis/spatial-join.htm
    #arcpy.analysis.SpatialJoin(target_features, join_features, out_feature_class, {join_operation}, {join_type}, {field_mapping}, {match_option}, {search_radius}, {distance_field_name})
    #https://pro.arcgis.com/en/pro-app/latest/tool-reference/data-management/add-field.htm
    # arcpy.management.AddField(in_table, field_name, field_type, {field_precision}, {field_scale}, {field_length}, {field_alias}, {field_is_nullable}, {field_is_required}, {field_domain})
    #https://pro.arcgis.com/en/pro-app/latest/tool-reference/data-management/calculate-field.htm
    # arcpy.management.CalculateField(in_table, field, expression, {expression_type}, {code_block}, {field_type}, {enforce_domains})
    #https://pro.arcgis.com/en/pro-app/latest/tool-reference/data-management/delete-field.htm
    # arcpy.management.DeleteField(in_table, drop_field, {method})
    #https://pro.arcgis.com/en/pro-app/latest/tool-reference/data-management/delete.htm
    # arcpy.management.Delete(in_data, {data_type})

    if redoSubs == 1:
        start_time = time.time()
        WriteMsg( "OptionA2: Generating 'selected' NEW substation locations for existing TX connections. THIS SHOULD ONLY BE RUN AFTER Step 3 is run for all resources AND IF the existing substation set is not adequate to task." )

        ###PROJECT AGGREGATION AND USE CENTREPOINTS AND SELECTED EXISTING TX FEATURE TO GENERATE SPUR LINES
        #Load VRE projects to use for auto-substation generation into memory
        S3W = arcpy.conversion.ExportFeatures(( W , r"memory\projectsW" ))  ## memory\
        if arcpy.management.GetCount(S3W)[0] != "0":
            WriteMsg( "OptionA2: Wind projects points found - " + W  )
        S3O = arcpy.conversion.ExportFeatures(( O , r"memory\projectsO" ))  ## memory\
        if arcpy.management.GetCount(S3O)[0] != "0":
            WriteMsg( "OptionA2: Offshore Wind projects points found - " + O )
        S3P = arcpy.conversion.ExportFeatures(( P , r"memory\projectsP" ))  ## memory\
        if arcpy.management.GetCount(S3P)[0] != "0":
            WriteMsg( "OptionA2: PV projects points found - " + P )

        #Merge all available projects into one dataset and release projects from memory
        BSA = arcpy.management.Merge([S3W, S3O, S3P], r"memory\projectsA")
        arcpy.management.Delete([S3W, S3O, S3P])
        WriteMsg(  "OptionA2: Merge all available projects into one dataset and release projects from memory" )

        #Shrink project polygons to center points
        BSApts = arcpy.management.FeatureToPoint(BSA, r"memory\projectApts", "INSIDE")  ## could also be saved to gdb ( scratchGDB + "\\AllprojPoints" )
        WriteMsg(  "OptionA2: Shrink project polygons to center points" )

        #Generate spur lines
        routes = OptimalPathAsLine( BSApts, gdbTX + "\\" + "eTXDis" , gdbTX + "\\" + "eTXDir" , r"memory\routes", routeField, "EACH_CELL" )
        WriteMsg( "OptionA2: generate least cost spur lines for all projects to the selected existing TX lines")

        ###SUBSTATIONS
        #generate substaions from intersection of cpas with existing TX
        subA = arcpy.analysis.Intersect([existTX, BSA], r"memory\subA", "ONLY_FID", "", "POINT")
        WriteMsg( "OptionA2: Substation generation process A completed ( CPA and TX )")

        #generate substaions from intersection of spur lines with existingTX
        subB = arcpy.analysis.PairwiseIntersect([existTX, routes], r"memory\subB", "ONLY_FID", "", "POINT")
        WriteMsg( "OptionA2: Substation generation process B completed ( Spur lines and TX )")

        #combine Substations from A and B processes and make sure all polygons are single part rather than multi-plart
        SU = arcpy.management.Merge([subA, subB], r"memory\subAB")
        SUU = arcpy.management.MultipartToSinglepart(SU, r"memory\subs")
        ###add in load (bulk/sink) center points as additional options -- can use selected substation from each MSA if have available, place link in the gdb
        SUB = arcpy.management.Merge([SUU, destBulk], r"memory\subABb")
        arcpy.conversion.ExportFeatures( SUB, gdbTX + "\\subs_super" )
        WriteMsg( "OptionA2: Substation locations generated with added centerpoints from load locations")

        #limit substations to just one within a 2km radius [buffer, dissolve, feature to point]
        subsBUF = arcpy.analysis.PairwiseBuffer(SUB, r"memory\subsBUF", subBuf )
        WriteMsg( "OptionA2: Buffer of all substations to " + str(subBuf) )
        subsDIS = arcpy.analysis.PairwiseDissolve(subsBUF, r"memory\subsDIS", "", "", "SINGLE_PART")
        subsS = arcpy.management.FeatureToPoint(subsDIS, r"memory\superSUBS", "INSIDE")  ## memory\
        WriteMsg( "OptionA2: Dissolve all touching (buffered) substations into a single point")

        #add aspects to subststaion (NZAu region, regAUS , closest SA2)
        fms = arcpy.FieldMappings()
        fms.addTable(subsS)
        fms.addTable( regNZAu )
        subsSw = arcpy.analysis.SpatialJoin(subsS, regNZAu , r"memory\subsSw", "JOIN_ONE_TO_ONE", "KEEP_ALL", fms, "CLOSEST")
        arcpy.management.DeleteField( subsSw, ["SUM_AREA", "SUM_TOTPOP_CY", "ORIG_FID", "TARGET_FID", "Join_Count"] )
        WriteMsg( "OptionA2: Subs - Spatial joins: NZAu")

        fms = arcpy.FieldMappings()
        fms.addTable(subsSw)
        fms.addTable(regAUS)
        subsSww = arcpy.analysis.SpatialJoin(subsSw, regAUS, r"memory\subsSww", "JOIN_ONE_TO_ONE", "KEEP_ALL", fms, "CLOSEST")
        arcpy.management.DeleteField(subsSww, ["TARGET_FID", "Join_Count", "ID", "AREA", "TOTPOP_CY", "ISO2_CC", "ISO3_CC", "ISO_CODE", "Shape_Length", "Shape_Area"])
        WriteMsg( "OptionA2: Subs - Spatial joins: states")

        fms = arcpy.FieldMappings()
        fms.addTable(subsSww)
        fms.addTable(destBulk)
        subsSwww = arcpy.analysis.SpatialJoin(subsSww, destBulk, r"memory\subsSwww", "JOIN_ONE_TO_ONE", "KEEP_ALL", fms, "CLOSEST", "", "sub2SA2_m")
        arcpy.management.DeleteField(subsSwww, ["TARGET_FID", "Join_Count", "geo", "SA2", "TOTPOP", "Shape_Length", "Shape_Area", "ORIG_FID"])
        arcpy.management.AddField(subsSwww, "subSA2aggOID", "LONG")
        arcpy.management.AddField(subsSwww, "subSA2aggPOP", "DOUBLE")
        arcpy.management.CalculateField(subsSwww, "subSA2aggOID", "!aggSA2oid!")
        arcpy.management.CalculateField(subsSwww, "subSA2aggPOP", "!SUM_TOTPOP_CY!")
        arcpy.management.DeleteField(subsSwww, ["aggSA2oid", "SUM_TOTPOP_CY"])
        WriteMsg( "OptionA2: Subs - Spatial joins: SA2")

        #add unique ID to substation and save
        arcpy.management.AddField(subsSwww, "subOID", "LONG")
        arcpy.management.CalculateField( subsSwww, "subOID", "!OBJECTID!")
        arcpy.conversion.ExportFeatures( subsSwww , gdbTX + "\\subs" )
        WriteMsg( "OptionA2: SUBS final superset")
        WriteMsg( "OptionA2: Finished generating substation subset for all spur connections" )

        #delete memory at end of stage
        arcpy.management.Delete("memory")
        end_time = time.time()
        WriteMsg("Option A2: Memory cache deleted, END mapVRE+ Option A2 taking " + str ( round ( (end_time - start_time)/60 , 1 ) ) + " minutes.")
        
    # END OPTION A2 #

    #-----------------------------#
    # OPTION A3 -- REDO Spur TX routing cost surfaces #

    ###FUNCTIONS CALLED and REFERENCES
    #https://pro.arcgis.com/en/pro-app/latest/tool-reference/spatial-analyst/distance-accumulation.htm
    # DistanceAccumulation(in_source_data, {in_barrier_data}, {in_surface_raster}, {in_cost_raster}, {in_vertical_raster}, {vertical_factor}, {in_horizontal_raster}, {horizontal_factor}, {out_back_direction_raster}, {out_source_direction_raster}, {out_source_location_raster}, {source_initial_accumulation}, {source_maximum_accumulation}, {source_cost_multiplier}, {source_direction}, {distance_method})

    if redoSurf_spur == 1:
        start_time = time.time()
        WriteMsg( "Option A3: Used to generate spur routing surfaces to pre-determined (either existing or proxies created in A1 and A2) substation or transmission line locations on/near existing TX" )

        #set location for routing cost surfaces for existing TX and generate
        Dir = ( gdbTX + "\\" + "spurDir" )
        Dis = ( gdbTX + "\\" + "spurDis" )
        DistAcc = DistanceAccumulation(destTX, in_cost_raster=routeSurf, in_surface_raster=elevSurf, out_back_direction_raster=Dir)
        DistAcc.save(Dis)

        #delete memory at end of stage
        arcpy.management.Delete("memory")
        end_time = time.time()
        WriteMsg("Option A3: Memory cache deleted, END mapVRE+ Option A3 taking " + str ( round ( (end_time - start_time)/60 , 1 ) ) + " minutes.")

    # END OPTION A3 #
    #-----------------------------#
    # OPTION A4 -- REDO bulk TX routing cost surfaces #

    ###FUNCTIONS CALLED and REFERENCES
    #https://pro.arcgis.com/en/pro-app/latest/tool-reference/spatial-analyst/distance-accumulation.htm
    # DistanceAccumulation(in_source_data, {in_barrier_data}, {in_surface_raster}, {in_cost_raster}, {in_vertical_raster}, {vertical_factor}, {in_horizontal_raster}, {horizontal_factor}, {out_back_direction_raster}, {out_source_direction_raster}, {out_source_location_raster}, {source_initial_accumulation}, {source_maximum_accumulation}, {source_cost_multiplier}, {source_direction}, {distance_method})

    if redoSurf_bulk == 1:
        start_time = time.time()
        WriteMsg( "Option A4: Used to generate bulk routing surfaces to pre-determined bulk load locations" )

        #set location for routing cost surfaces for existing TX and generate
        Dir = ( gdbTX + "\\" + "bulkDir" )
        Dis = ( gdbTX + "\\" + "bulkDis" )
        DistAcc = DistanceAccumulation(destBulk, in_cost_raster=routeSurf, in_surface_raster=elevSurf, out_back_direction_raster=Dir)
        DistAcc.save(Dis)

        #delete memory at end of stage
        arcpy.management.Delete("memory")
        end_time = time.time()
        WriteMsg("Option A4: Memory cache deleted, END mapVRE+ Option A4 taking " + str ( round ( (end_time - start_time)/60 , 1 ) ) + " minutes.")

    # END OPTION A4 #
    #-----------------------------#
    #-----------------------------#
    # OPTION A5 -- REDO sink TX routing cost surfaces #

    ###FUNCTIONS CALLED and REFERENCES
    #https://pro.arcgis.com/en/pro-app/latest/tool-reference/spatial-analyst/distance-accumulation.htm
    # DistanceAccumulation(in_source_data, {in_barrier_data}, {in_surface_raster}, {in_cost_raster}, {in_vertical_raster}, {vertical_factor}, {in_horizontal_raster}, {horizontal_factor}, {out_back_direction_raster}, {out_source_direction_raster}, {out_source_location_raster}, {source_initial_accumulation}, {source_maximum_accumulation}, {source_cost_multiplier}, {source_direction}, {distance_method})

    if redoSurf_sink == 1:
        start_time = time.time()
        WriteMsg( "Option A5: Used to generate sink routing surfaces to pre-determined regional sink load locations" )

        #set location for routing cost surfaces for existing TX and generate
        Dir = ( gdbTX + "\\" + "sinkDir" )
        Dis = ( gdbTX + "\\" + "sinkDis" )
        DistAcc = DistanceAccumulation(destSink, in_cost_raster=routeSurf, in_surface_raster=elevSurf, out_back_direction_raster=Dir)
        DistAcc.save(Dis)

        #delete memory at end of stage
        arcpy.management.Delete("memory")
        end_time = time.time()
        WriteMsg("Option A5: Memory cache deleted, END mapVRE+ Option A5 taking " + str ( round ( (end_time - start_time)/60 , 1 ) ) + " minutes.")

    # END OPTION A5 #
    #-----------------------------#
    #-----------------------------#
    # OPTION A6 -- REDO export TX routing cost surfaces #

    ###FUNCTIONS CALLED and REFERENCES
    #https://pro.arcgis.com/en/pro-app/latest/tool-reference/spatial-analyst/distance-accumulation.htm
    # DistanceAccumulation(in_source_data, {in_barrier_data}, {in_surface_raster}, {in_cost_raster}, {in_vertical_raster}, {vertical_factor}, {in_horizontal_raster}, {horizontal_factor}, {out_back_direction_raster}, {out_source_direction_raster}, {out_source_location_raster}, {source_initial_accumulation}, {source_maximum_accumulation}, {source_cost_multiplier}, {source_direction}, {distance_method})

    if redoSurf_exp == 1:
        start_time = time.time()
        WriteMsg( "Option A6: Used to generate export routing surfaces to selected export aggregation node locations" )

        #set location for routing cost surfaces for existing TX and generate
        if Resource == "off":
            Dir = ( gdbTX + "\\" + "exportOffDir" )
            Dis = ( gdbTX + "\\" + "exportOffDis" )
        else:
            Dir = ( gdbTX + "\\" + "exportOnDir" )
            Dis = ( gdbTX + "\\" + "exportOnDis" )
        DistAcc = DistanceAccumulation(destExport, in_cost_raster=routeSurf, in_surface_raster=elevSurf, out_back_direction_raster=Dir)
        DistAcc.save(Dis)

        #delete memory at end of stage
        arcpy.management.Delete("memory")
        end_time = time.time()
        WriteMsg("Option A6: Memory cache deleted, END mapVRE+ Option A6 taking " + str ( round ( (end_time - start_time)/60 , 1 ) ) + " minutes.")

    # END OPTION A6 #
    #-----------------------------#
    # END OPTIONS SECTION#
    #_______________________________________________________________________________________________________________________#
    #_______________________________________________________________________________________________________________________#
    # STAGE 4 #

    ###FUNCTIONS CALLED and REFERENCES
    #https://pro.arcgis.com/en/pro-app/latest/tool-reference/data-management/feature-to-point.htm
    # arcpy.management.FeatureToPoint(in_features, out_feature_class, {point_location})
    #https://pro.arcgis.com/en/pro-app/latest/tool-reference/spatial-analyst/optimal-path-as-line.htm
    # OptimalPathAsLine(in_destination_data, in_distance_accumulation_raster, in_back_direction_raster, out_polyline_features, {destination_field}, {path_type}, {create_network_paths})
    #https://pro.arcgis.com/en/pro-app/latest/tool-reference/conversion/export-features.htm
    # arcpy.conversion.ExportFeatures(in_features, out_features, {where_clause}, {use_field_alias_as_name}, {field_mapping}, {sort_field})
    #https://pro.arcgis.com/en/pro-app/latest/tool-reference/analysis/pairwise-buffer.htm
    # arcpy.analysis.PairwiseBuffer(in_features, out_feature_class, buffer_distance_or_field, {dissolve_option}, {dissolve_field}, {method}, {max_deviation})
    #https://pro.arcgis.com/en/pro-app/latest/tool-reference/spatial-analyst/extract-by-mask.htm
    # ExtractByMask(in_raster, in_mask_data)
    #https://pro.arcgis.com/en/pro-app/latest/tool-reference/spatial-analyst/optimal-path-as-line.htm
    # OptimalPathAsLine(in_destination_data, in_distance_accumulation_raster, in_back_direction_raster, out_polyline_features, {destination_field}, {path_type}, {create_network_paths})
    #https://pro.arcgis.com/en/pro-app/latest/tool-reference/analysis/spatial-join.htm
    # arcpy.analysis.SpatialJoin(target_features, join_features, out_feature_class, {join_operation}, {join_type}, {field_mapping}, {match_option}, {search_radius}, {distance_field_name})
    #https://pro.arcgis.com/en/pro-app/latest/tool-reference/data-management/add-field.htm
    # arcpy.management.AddField(in_table, field_name, field_type, {field_precision}, {field_scale}, {field_length}, {field_alias}, {field_is_nullable}, {field_is_required}, {field_domain})
    #https://pro.arcgis.com/en/pro-app/latest/tool-reference/data-management/calculate-field.htm
    # arcpy.management.CalculateField(in_table, field, expression, {expression_type}, {code_block}, {field_type}, {enforce_domains})
    #https://pro.arcgis.com/en/pro-app/latest/tool-reference/data-management/delete-field.htm
    # arcpy.management.DeleteField(in_table, drop_field, {method})
    #https://pro.arcgis.com/en/pro-app/latest/tool-reference/data-management/delete.htm
    # arcpy.management.Delete(in_data, {data_type})

    if startStage <= 4 and endStage >= 4:
        arcpy.management.Delete("memory")
        WriteMsg( "S4:Starting S4 with " + S3Output )
        start_time = time.time()

        #process substation dataset fof joining with spur lines - NOT ROBUIST CODE!!! and DOES NOT HANDLE OTHER DATA SETS
        subs = arcpy.conversion.ExportFeatures(destTX, r"memory\subsClean")
        if destTX == (gispath + "NZAu0_Base.gdb\GA_2021_Foundation_TXsubstations_3577"):
            WriteMsg("S4: Using GA dataset of existing substations, added subOID and removed all unneeded columns")
            WriteMsg("S4: this will fail during supply curve generation, unless a few fields are added in this script -- see A2 Option ('Sub2SA2_m' , 'subSA2aggOID' , 'subSA2aggPop' )" )
            arcpy.management.AddField(subs, "subOID", "LONG")
            arcpy.management.CalculateField(subs, "subOID", "!OBJECTID!")
            arcpy.management.DeleteField(subs, ["OBJECTID" , "Shape" , "subOID" ] , "KEEP_FIELDS")
            #arcpy.conversion.ExportFeatures(subs, ScratchGDB + "\\subsClean")
        elif destTX == ( gispath + "NZAu6_TX_v2.gdb\subs"):
            WriteMsg("S4: Using pre-procesed generalized substations, removed all unneeded columns")
            arcpy.management.DeleteField(subs, ["Shape" , "subOID" , "sub2SA2_m" , "nzau" , "subSA2aggOID" , "subSA2aggPOP"], "KEEP_FIELDS")
        else:
            WriteMsg("S4: Using unknown destination layer for spur generation, if the attribute 'subOID' is not unique for every row or is not part of layer, then this or following processes will fail")
            WriteMsg("S4: In addition, use of this substation dataset will fail during supply curve generation, unless a few fields are added in this script -- see A2 Option ('Sub2SA2_m' , 'subSA2aggOID' , 'subSA2aggPop' )")

        #Get projects for transmission, clean attributes, and make points
        projects = arcpy.conversion.ExportFeatures( S3Output , r"memory\projects")
        arcpy.management.DeleteField( projects, ["Id", "gridcode", "Shape_Length_1", "Shape_Area_1", "ORIG_FID", "NEAR_FID", "l_tra", "l_road", "l_sub", "lt_sub", "lt_tra", "l_gen"])
        projectPts = arcpy.management.FeatureToPoint( projects, r"memory\projectPts", "INSIDE")
        arcpy.conversion.ExportFeatures( projectPts , S4Output + "_points" )

        #Spur line Route
        routes = OptimalPathAsLine( projectPts, gdbTX + "\\" + "spurDis", gdbTX + "\\" + "spurDir" , r"memory\routes" , routeField, "EACH_CELL")
        WriteMsg( "S4: Spur line routes done")

        #Surface for cost
        spursBuf = arcpy.analysis.PairwiseBuffer( routes, r"memory\spursBuf", routeBuf )
        arcpy.conversion.ExportFeatures( spursBuf, ScratchGDB + "\\spurRoutesBuf" )
        WriteMsg("S4: Pairwise Buffer for constrained cost surface done")
        constCost = ExtractByMask( costSurf , ScratchGDB + "\\spurRoutesBuf" )
        #constCost.save ( r"C:\Users\uqapasca\WorkdeskUQ\NZAu\d0_4gis\scratchNZAu.gdb\interTX_costConstrained" )
        WriteMsg("S4: Extract by Mask for constrained cost surface done")
        DistAcc = DistanceAccumulation(destTX, in_cost_raster=constCost, in_surface_raster=elevSurf, out_back_direction_raster=r"memory\SCdir_temp")
        DistAcc.save(r"memory\SCdis_temp")
        WriteMsg("S4: Generated constrained cost surface for entire spur")

        #Spur line Cost (unitless multiplier?); Assign nearest substation to spur lines and create substation subset for further processing
        spurs = OptimalPathAsLine( projectPts , r"memory\SCdis_temp", r"memory\SCdir_temp", r"memory\spurs", routeField, "EACH_CELL")
        fms = arcpy.FieldMappings()
        fms.addTable(spurs)
        fms.addTable(subs)
        spursW = arcpy.analysis.SpatialJoin(spurs, subs, r"memory\spursW", "JOIN_ONE_TO_ONE", "KEEP_ALL", fms, "CLOSEST")
        arcpy.management.DeleteField( spursW , ["TARGET_FID", "Join_Count", "SA2", "ISO_SUB", "geo", "spur2sub_m", "FIRST_geo", "FIRST_SA2", "type"])
        arcpy.conversion.ExportFeatures( spursW , S4Output + "_spurs" )
        WriteMsg("S4: Spur line paths with costs generated and assigned closest substation")

        #Create substation subset for further use/processing
        fms = arcpy.FieldMappings()
        fms.addTable(subs)
        fms.addTable(spurs)
        subsW = arcpy.analysis.SpatialJoin(subs, spurs, r"memory\subsW", "JOIN_ONE_TO_ONE", "KEEP_COMMON", fms, "WITHIN_A_DISTANCE", "200 Meters")
        arcpy.management.DeleteField(subsW, ["TARGET_FID", "Join_Count", "SA2", "ISO_SUB", "geo", "PathCost", "DestID"])
        #######TBD MAYBE
        ####### add loop here for substations that fall on top of project centrepoints and add to substation subset -- need to include a note of the project ID to re-integrate later on
        #######
        arcpy.conversion.ExportFeatures( subsW, S4Output + "_subs" )
        WriteMsg("S4: Exported Subststaions - Only those accessed")

        #save csvs for key datasets
        #arcpy.management.CopyRows( S4Output + "_points" , csvOUT + prefix + "S3_case" + exCase + "_points.csv" )
        #arcpy.management.CopyRows( S4Output + "_subs"   , csvOUT + prefix + "S3_case" + exCase + "_subs.csv" )  ##this can be removed once substation script is added!? or after new downscaling trialed
        #arcpy.management.CopyRows( S4Output + "_spurs"  , csvOUT + prefix + "S3_case" + exCase + "_spurs.csv" )
        #arcpy.management.Delete( csvOUT + prefix + "S3_case" + exCase + "_points.csv.xml")
        #arcpy.management.Delete( csvOUT + prefix + "S3_case" + exCase + "_subs.csv.xml")
        #arcpy.management.Delete( csvOUT + prefix + "S3_case" + exCase + "_spurs.csv.xml")
        #arcpy.management.Delete( csvOUT + "schema.ini")
        WriteMsg("S4: Site CentrePoints can be found at:" + S4Output + "_points" )
        WriteMsg("S4: Accessed substations can be found at:" + S4Output + "_subs" )
        WriteMsg("S4: Spur lines can be found at:" + S4Output + "_spurs" )
        #WriteMsg("S4: Saved csvs ( _points , _spurs , _subs )")

        #landfall for offshore
        if Resource == "off":
            WriteMsg("S4: Generating constrained cost surface for landfall")
            #Surface for landfall
            DistAcc = DistanceAccumulation( destLand, in_cost_raster=constCost, in_surface_raster=elevSurf, out_back_direction_raster=r"memory\SROdir_temp")
            DistAcc.save(r"memory\SROdis_temp")
            #Landfall distance
            landfall = OptimalPathAsLine( projectPts, r"memory\SROdis_temp", r"memory\SROdir_temp", r"memory\landfall", routeField, "EACH_CELL")
            arcpy.conversion.ExportFeatures(  landfall , S4Output + "_landfall" )
            WriteMsg("S4: Landfall routes for offshore wind can be found at:" + S4Output + "_landfall")
            WriteMsg("S4: Landfall costs done , saving to _land csv")
            #save csvs for key datasets
            #arcpy.management.CopyRows( S4Output + "_landfall" , csvOUT + prefix + "S4_case" + exCase + "_land.csv" )
            #arcpy.management.Delete( csvOUT + prefix + "S4_case" + exCase + "_land.csv.xml")
            #arcpy.management.Delete(csvOUT + "schema.ini")

        #delete memory at end of stage
        arcpy.management.Delete("memory")
        end_time = time.time()
        WriteMsg("S4: Memory cache deleted, END mapVRE+ S4 taking " + str ( round ( (end_time - start_time)/60 , 1 ) ) + " minutes.")

    # END STAGE 4 #
    # _______________________________________________________________________________________________________________________#
    #_______________________________________________________________________________________________________________________#
    # STAGE 5  - Routing of bulk TX from spur line connection to grid feature to nearest MSA #

    ###FUNCTIONS CALLED and REFERENCES
    #https://pro.arcgis.com/en/pro-app/latest/tool-reference/data-management/feature-to-point.htm
    # arcpy.management.FeatureToPoint(in_features, out_feature_class, {point_location})
    #https://pro.arcgis.com/en/pro-app/latest/tool-reference/spatial-analyst/optimal-path-as-line.htm
    # OptimalPathAsLine(in_destination_data, in_distance_accumulation_raster, in_back_direction_raster, out_polyline_features, {destination_field}, {path_type}, {create_network_paths})
    #https://pro.arcgis.com/en/pro-app/latest/tool-reference/conversion/export-features.htm
    # arcpy.conversion.ExportFeatures(in_features, out_features, {where_clause}, {use_field_alias_as_name}, {field_mapping}, {sort_field})
    #https://pro.arcgis.com/en/pro-app/latest/tool-reference/analysis/pairwise-buffer.htm
    # arcpy.analysis.PairwiseBuffer(in_features, out_feature_class, buffer_distance_or_field, {dissolve_option}, {dissolve_field}, {method}, {max_deviation})
    #https://pro.arcgis.com/en/pro-app/latest/tool-reference/spatial-analyst/extract-by-mask.htm
    # ExtractByMask(in_raster, in_mask_data)
    #https://pro.arcgis.com/en/pro-app/latest/tool-reference/spatial-analyst/optimal-path-as-line.htm
    # OptimalPathAsLine(in_destination_data, in_distance_accumulation_raster, in_back_direction_raster, out_polyline_features, {destination_field}, {path_type}, {create_network_paths})
    #https://pro.arcgis.com/en/pro-app/latest/tool-reference/analysis/spatial-join.htm
    # arcpy.analysis.SpatialJoin(target_features, join_features, out_feature_class, {join_operation}, {join_type}, {field_mapping}, {match_option}, {search_radius}, {distance_field_name})

    if startStage <= 5 and endStage >= 5:
        WriteMsg("S5: Starting S5 with " + S4Output )
        start_time = time.time()

        #load projects for transmission
        S4points = arcpy.conversion.ExportFeatures(  S4Output + "_points" , r"memory\projects" )
        #Spur lines from S4
        S4spurs = arcpy.conversion.ExportFeatures( S4Output + "_spurs" , r"memory\spurs" )
        #Selected substation locations
        sub = arcpy.conversion.ExportFeatures( S4Output + "_subs" , r"memory\sub" )
        subs = arcpy.management.AddXY ( sub )

        ###BULK TX -- run HV TX lines from selected substations to nearest load destination
        #Bulk line Route
        routes = OptimalPathAsLine( subs , gdbTX + "\\bulkDis" , gdbTX + "\\bulkDir" , r"memory\routes", bulkField , "EACH_CELL")
        WriteMsg("S5: Bulk line routes done")
        #Surface for cost
        Buf = arcpy.analysis.PairwiseBuffer( routes, r"memory\Buf", routeBuf )
        arcpy.conversion.ExportFeatures( Buf, ScratchGDB + "\\bulkRoutesBuf" )
        WriteMsg("S5: Pairwise Buffer for bulk route constrained cost surface done")
        constCost = ExtractByMask( costSurf, ScratchGDB + "\\bulkRoutesBuf" )
        WriteMsg("S5: Extract by Mask for bulk route constrained cost surface done")
        DistAcc = DistanceAccumulation (destBulk, in_cost_raster=constCost, in_surface_raster=elevSurf, out_back_direction_raster=r"memory\LCdir_temp")
        DistAcc.save(r"memory\LCdis_temp")
        WriteMsg("S5: Generated constrained cost surface for bulk lengths")

        #Bulk line Cost, unitless multiplier
        bulk = OptimalPathAsLine ( subs, r"memory\LCdis_temp", r"memory\LCdir_temp", r"memory\bulk", bulkField, "EACH_CELL")
        WriteMsg("S5: Bulk line costs done")
        #join an SA2 destination to all bulk tx lines
        fms = arcpy.FieldMappings()
        fms.addTable(bulk)
        fms.addTable(destBulk)
        bulkW = arcpy.analysis.SpatialJoin( bulk, destBulk, r"memory\bulkW", "JOIN_ONE_TO_ONE", "KEEP_ALL", fms, "CLOSEST")
        arcpy.management.DeleteField(bulkW, ["TARGET_FID", "Join_Count", "geo", "SA2", "FIRST_geo", "FIRST_SA2", "TOTPOP", "Shape_Area", "Shape_Length", "ORIG_FID"])
        arcpy.management.AddField(bulkW, "subOID  ", "LONG")
        arcpy.management.AddField(bulkW, "bulkCost", "DOUBLE")
        arcpy.management.AddField(bulkW, "bulkSA2aggOID", "LONG")
        arcpy.management.AddField(bulkW, "bulkSA2aggPOP", "DOUBLE")
        arcpy.management.CalculateField(bulkW, "bulkSA2aggOID", "!aggSA2oid!")
        arcpy.management.CalculateField(bulkW, "bulkSA2aggPOP", "!SUM_TOTPOP_CY!")
        arcpy.management.CalculateField(bulkW, "bulkCost", "!PathCost!")
        arcpy.management.CalculateField(bulkW, "subOID", "!DestID!")
        arcpy.management.DeleteField(bulkW, ["aggSA2oid", "SUM_TOTPOP_CY", "PathCost", "DestID", "type"])
        arcpy.conversion.ExportFeatures( bulkW , S5Output + "_bulk" )
        WriteMsg("S5: Spatial joins: SA2 to bulk lines")

        #arcpy.management.CopyRows( S5Output + "_bulk" , csvOUT + prefix + "S5_case" + exCase + "_bulk.csv" )
        #arcpy.management.Delete( csvOUT + prefix + "S5_case" + exCase + "_bulk.csv.xml")
        #arcpy.management.Delete( csvOUT + "schema.ini")
        WriteMsg("S5: Bulk transmission lines from substations to nearest load can be found at:" + S5Output + "_bulk")
        #WriteMsg("S5: Saved csvs ( _bulk )" )

        # delete memory at end of stage
        arcpy.management.Delete("memory")
        end_time = time.time()
        WriteMsg("S5: Memory cache deleted, END mapVRE+ S5 taking " + str(round((end_time - start_time) / 60, 1)) + " minutes.")

    # END STAGE 5 #
    # _______________________________________________________________________________________________________________________#
    #_______________________________________________________________________________________________________________________#
    # STAGE 6 - Routing of sink TX from spur line connection to grid feature to nearest sink MSA #

    ###FUNCTIONS CALLED and REFERENCES
    #https://pro.arcgis.com/en/pro-app/latest/tool-reference/data-management/feature-to-point.htm
    # arcpy.management.FeatureToPoint(in_features, out_feature_class, {point_location})
    #https://pro.arcgis.com/en/pro-app/latest/tool-reference/spatial-analyst/optimal-path-as-line.htm
    # OptimalPathAsLine(in_destination_data, in_distance_accumulation_raster, in_back_direction_raster, out_polyline_features, {destination_field}, {path_type}, {create_network_paths})
    #https://pro.arcgis.com/en/pro-app/latest/tool-reference/conversion/export-features.htm
    # arcpy.conversion.ExportFeatures(in_features, out_features, {where_clause}, {use_field_alias_as_name}, {field_mapping}, {sort_field})
    #https://pro.arcgis.com/en/pro-app/latest/tool-reference/analysis/pairwise-buffer.htm
    # arcpy.analysis.PairwiseBuffer(in_features, out_feature_class, buffer_distance_or_field, {dissolve_option}, {dissolve_field}, {method}, {max_deviation})
    #https://pro.arcgis.com/en/pro-app/latest/tool-reference/spatial-analyst/extract-by-mask.htm
    # ExtractByMask(in_raster, in_mask_data)
    #https://pro.arcgis.com/en/pro-app/latest/tool-reference/spatial-analyst/optimal-path-as-line.htm
    # OptimalPathAsLine(in_destination_data, in_distance_accumulation_raster, in_back_direction_raster, out_polyline_features, {destination_field}, {path_type}, {create_network_paths})
    #https://pro.arcgis.com/en/pro-app/latest/tool-reference/analysis/spatial-join.htm
    # arcpy.analysis.SpatialJoin(target_features, join_features, out_feature_class, {join_operation}, {join_type}, {field_mapping}, {match_option}, {search_radius}, {distance_field_name})

    if startStage <= 6 and endStage >= 6:
        WriteMsg("S6:Starting S6 with " + S4Output )
        start_time = time.time()

        #Load substations for transmission
        sub = arcpy.conversion.ExportFeatures( S4Output + "_subs" , r"memory\projects")
        subs = arcpy.management.AddXY(sub)

        ###run HV TX lines from all substations to nearest Sink destination
        #Sink line Route
        routes = OptimalPathAsLine( subs , gdbTX + "\\sinkDis" , gdbTX + "\\sinkDir" , r"memory\routes", bulkField, "EACH_CELL")
        WriteMsg("S6: Sink line routes done")
        #Surface for cost
        Buf = arcpy.analysis.PairwiseBuffer (routes, r"memory\Buf", routeBuf )
        arcpy.conversion.ExportFeatures( Buf,  ScratchGDB + "\\sinkRoutesBuf" )
        WriteMsg("S6: Pairwise Buffer for sink route constrained cost surface done")
        constCost = ExtractByMask( costSurf, ScratchGDB + "\\sinkRoutesBuf" )
        WriteMsg("S6: Extract by Mask for sink route constrained cost surface done")
        DistAcc = DistanceAccumulation ( destSink, in_cost_raster=constCost, in_surface_raster=elevSurf, out_back_direction_raster=r"memory\SinkCdir_temp")
        DistAcc.save(r"memory\SinkCdis_temp")
        WriteMsg("S6: Generated constrained cost surface for sink lengths")

        ###Sink line Cost, unitless multiplier
        sink = OptimalPathAsLine (subs, r"memory\SinkCdis_temp", r"memory\SinkCdir_temp", r"memory\sink", bulkField, "EACH_CELL")
        WriteMsg("S6: Sink lines done")
        #join an SA2 destination to all sink tx lines
        fms = arcpy.FieldMappings()
        fms.addTable(sink)
        fms.addTable(destSink)
        sinkW = arcpy.analysis.SpatialJoin( sink, destSink, r"memory\sinkW", "JOIN_ONE_TO_ONE", "KEEP_ALL", fms, "CLOSEST")
        arcpy.management.DeleteField(sinkW, ["TARGET_FID", "Join_Count", "geo", "SA2", "FIRST_geo", "FIRST_SA2", "TOTPOP", "Shape_Area", "Shape_Length"])
        arcpy.management.AddField(sinkW, "subOID", "LONG")
        arcpy.management.AddField(sinkW, "sinkCost", "DOUBLE")
        arcpy.management.AddField(sinkW, "sinkSA2oid", "LONG")
        arcpy.management.AddField(sinkW, "sinkSA2pop", "DOUBLE")
        arcpy.management.CalculateField(sinkW, "sinkCost", "!PathCost!")
        arcpy.management.CalculateField(sinkW, "subOID", "!DestID!")
        arcpy.management.CalculateField(sinkW, "sinkSA2oid", "!aggSA2oid!")
        arcpy.management.CalculateField(sinkW, "sinkSA2pop", "!SUM_TOTPOP_CY!")
        arcpy.management.DeleteField(sinkW, ["PathCost", "DestID", "aggSA2oid", "ORIG_FID", "SUM_TOTPOP_CY", "type"])
        WriteMsg("S6: Spatial joins: SA2 to sink lines")

        #save sinks
        arcpy.conversion.ExportFeatures( sinkW, S6Output + "_sink" )
        #arcpy.management.CopyRows( S6Output + "_sink" , csvOUT + prefix + "S6_case" + exCase + "_sink.csv" )
        #arcpy.management.Delete( csvOUT + prefix + "S6_case" + exCase + "_sink.csv.xml")
        #arcpy.management.Delete(csvOUT + "schema.ini")
        WriteMsg("S6: Sink transmission lines from substations to nearest regional sink load can be found at:" + S6Output + "_sink")
        #WriteMsg("S6: Save csvs ( _sink )" )

        #delete memory at end of stage
        arcpy.management.Delete("memory")
        end_time = time.time()
        WriteMsg("S6: Memory cache deleted, END mapVRE+ S6 taking " + str(round((end_time - start_time) / 60, 1)) + " minutes.")

    # END STAGE 6 #
    # _______________________________________________________________________________________________________________________#
    #_______________________________________________________________________________________________________________________#
    # STAGE 7 - EXPORT SPUR TX ROUTING FROM CPAs to EXport aggregation nodes#

    ###FUNCTIONS CALLED and REFERENCES
    #https://pro.arcgis.com/en/pro-app/latest/tool-reference/data-management/feature-to-point.htm
    # arcpy.management.FeatureToPoint(in_features, out_feature_class, {point_location})
    #https://pro.arcgis.com/en/pro-app/latest/tool-reference/spatial-analyst/optimal-path-as-line.htm
    # OptimalPathAsLine(in_destination_data, in_distance_accumulation_raster, in_back_direction_raster, out_polyline_features, {destination_field}, {path_type}, {create_network_paths})
    #https://pro.arcgis.com/en/pro-app/latest/tool-reference/conversion/export-features.htm
    # arcpy.conversion.ExportFeatures(in_features, out_features, {where_clause}, {use_field_alias_as_name}, {field_mapping}, {sort_field})
    #https://pro.arcgis.com/en/pro-app/latest/tool-reference/analysis/pairwise-buffer.htm
    # arcpy.analysis.PairwiseBuffer(in_features, out_feature_class, buffer_distance_or_field, {dissolve_option}, {dissolve_field}, {method}, {max_deviation})
    #https://pro.arcgis.com/en/pro-app/latest/tool-reference/spatial-analyst/extract-by-mask.htm
    # ExtractByMask(in_raster, in_mask_data)
    #https://pro.arcgis.com/en/pro-app/latest/tool-reference/spatial-analyst/optimal-path-as-line.htm
    # OptimalPathAsLine(in_destination_data, in_distance_accumulation_raster, in_back_direction_raster, out_polyline_features, {destination_field}, {path_type}, {create_network_paths})
    #https://pro.arcgis.com/en/pro-app/latest/tool-reference/analysis/spatial-join.htm
    # arcpy.analysis.SpatialJoin(target_features, join_features, out_feature_class, {join_operation}, {join_type}, {field_mapping}, {match_option}, {search_radius}, {distance_field_name})

    if startStage <= 7 and endStage >= 7:
        WriteMsg("S7:Starting S7 with " + S3Output )
        start_time = time.time()

        #Load projects for transmission
        #set resource specific items
        if Resource == "off":
            whereA = "\"d_nodeOff\" <= " + str(500)
            projectPts = arcpy.conversion.ExportFeatures(S4Output + "_points", r"memory\projects" , whereA)
            WriteMsg("S7: Offshore wind limited to " + str(arcpy.GetCount_management(projectPts)) + " projects.")
            exportDis = gdbTX + "\\exportOffDis"
            exportDir = gdbTX + "\\exportOffDir"
        elif Resource == "wind":
            whereA = "\"d_nodeOn\" <= " + str(250)
            projectPts = arcpy.conversion.ExportFeatures(S4Output + "_points", r"memory\projects" , whereA)
            WriteMsg("S7: Wind limited to " + str(arcpy.GetCount_management(projectPts)) + " projects.")
            exportDis = gdbTX + "\\exportOnDis"
            exportDir = gdbTX + "\\exportOnDir"
        else:
            whereA = "\"d_nodeOn\" <= " + str(250)
            projectPts = arcpy.conversion.ExportFeatures(S4Output + "_points", r"memory\projects" , whereA)
            WriteMsg("S7: Solar PV limited to " + str(arcpy.GetCount_management(projectPts)) + " projects.")
            exportDis = gdbTX + "\\exportOnDis"
            exportDir = gdbTX + "\\exportOnDir"

        ###Generate Export Spur line Route
        routes = OptimalPathAsLine( projectPts , exportDis, exportDir , r"memory\routes", routeField, "EACH_CELL")
        WriteMsg("S7: Export line routes done")
        #Surface for cost
        spursBuf = arcpy.analysis.PairwiseBuffer( routes, r"memory\spursBuf", routeBuf )
        arcpy.conversion.ExportFeatures( spursBuf, ScratchGDB + "\\exportRoutesBuf" )
        WriteMsg("S7: Pairwise Buffer for constrained cost surface done")
        constCost = ExtractByMask( costSurf, ScratchGDB + "\\exportRoutesBuf" )
        WriteMsg("S7: Extract by Mask for constrained cost surface done")
        DistAcc = DistanceAccumulation( destExport , in_cost_raster=constCost, in_surface_raster=elevSurf, out_back_direction_raster=r"memory\EXdir_temp")
        DistAcc.save(r"memory\EXdis_temp")
        WriteMsg("S7: Generated constrained cost surface for entire export line")

        ###Spur line Cost, unitless multiplier
        spursX = OptimalPathAsLine (projectPts , r"memory\EXdis_temp", r"memory\EXdir_temp", r"memory\spurs", routeField, "EACH_CELL")
        WriteMsg("S7: Export line costs done")
        #add data for nearest export node
        fms = arcpy.FieldMappings()
        fms.addTable(spursX)
        fms.addTable(destExport)
        spursXX = arcpy.analysis.SpatialJoin( spursX, destExport, r"memory\ptsW", "JOIN_ONE_TO_ONE", "KEEP_ALL", fms, "CLOSEST", "")
        arcpy.management.DeleteField( spursXX, ["TARGET_FID", "Join_Count", "Latitude", "Longitude", "ORIG_FID"])
        arcpy.conversion.ExportFeatures( spursXX, S7Output + "_export" )
        WriteMsg("S7: Export spur transmission lines from project to nearest hydrogen production load can be found at:" + S7Output + "_export")
        WriteMsg("S7: Export spurs - Spatial joins: Export node info")

        ##landfall for offshore
        if Resource == "off":
            WriteMsg("S7: Generating constrained cost surface for landfall")
            #Surface for landfall
            DistAcc = DistanceAccumulation (destLand, in_cost_raster=constCost, in_surface_raster=elevSurf, out_back_direction_raster=r"memory\SROdir_temp")
            DistAcc.save(r"memory\SROdis_temp")
            landfall = OptimalPathAsLine( projectPts, r"memory\SROdis_temp", r"memory\SROdir_temp", r"memory\landfall", routeField, "EACH_CELL")
            arcpy.conversion.ExportFeatures( landfall, S7Output + "_exportLandfall" )
            WriteMsg("S7: Export spur transmission line landfall distances from offshore wind project to landfall point can be found at:" + S7Output + "_exportLandfall")
            #arcpy.management.CopyRows( S7Output + "_exportLandfall" , csvOUT + prefix + "S7_case" + exCase + "_land.csv" )
            #arcpy.management.Delete( csvOUT + prefix + "S7_case" + exCase + "_land.csv.xml")
            #arcpy.management.Delete( csvOUT + "schema.ini")
            WriteMsg("S7: Landfall costs done")# and _land csv saved")

        #save csvs for key datasets
        #arcpy.management.CopyRows( S7Output + "_export" , csvOUT + prefix + "S7_case" + exCase + "_export.csv" )
        #arcpy.management.Delete(csvOUT + prefix + "S7_case" + exCase + "_export.csv.xml")
        #arcpy.management.Delete(csvOUT + "schema.ini")
        #WriteMsg("S7: Saved csvs ( _export )" )

        # delete memory at end of stage
        arcpy.management.Delete("memory")
        end_time = time.time()
        WriteMsg("S7: Memory cache deleted, END mapVRE+ S7 taking " + str(round((end_time - start_time) / 60, 1)) + " minutes.")

    # END STAGE 7 #
    # _______________________________________________________________________________________________________________________#
    #_______________________________________________________________________________________________________________________#
    # STAGE 8 - Combine CPAs with attributes from TX stages to use in costing/supply curve preperation#

    ###FUNCTIONS CALLED and REFERENCES
    ##https://pro.arcgis.com/en/pro-app/latest/tool-reference/data-management/add-join.htm
    ##arcpy.management.AddJoin(in_layer_or_view, in_field, join_table, join_field, {join_type})

    if startStage <= 8 and endStage >= 8:
        WriteMsg("S8:Starting S8 with " + S3Output )
        start_time = time.time()

        ###PREPARE PROJECTS for JOIN
        #Load projects for transmission
        projects = arcpy.conversion.ExportFeatures(S3Output, r"memory\projects")
        arcpy.management.AddField(projects , "type"   , "TEXT")
        arcpy.management.AddField(projects , "OIDcom" , "LONG")
        #set resource specific items
        if Resource == "off":
            arcpy.management.CalculateField( projects , "type"   , "'off'")
        #    arcpy.management.CalculateField( projects , "OIDcom" , "!OIDoff!")
        elif Resource == "wind":
            arcpy.management.CalculateField(projects, "type", "'wind'")
        #    arcpy.management.CalculateField( projects , "OIDcom" , "!OIDwind!")
        else:
           arcpy.management.CalculateField(projects, "type", "'pv'")
        #   arcpy.management.CalculateField( projects , "OIDcom" , "!OIDpv!")
        arcpy.management.CalculateField(projects, "OIDcom", "!OBJECTID!")
       # arcpy.management.DeleteField( projects, ["Shape", "type" , "OIDcom" , "incap" , "m_cf" , "areakm", "pDensity" , "luDiscount" , "hourYr" , "egen" , "d_sink" , \
       #                                          "d_load" , "d_export" , "d_nodeOn" , "d_nodeOff" , "m_elev" , "m_popden" , "m_landuse_maj" , "m_NZAU_maj" , \
       #                                          "m_locMult" , "m_node" ] , "KEEP_FIELDS")

        ###SPURS
        #prepare
        tx= arcpy.conversion.ExportFeatures( S4Output + "_spurs" , r"memory\spurs")
        arcpy.management.AddField( tx, "spurOID" , "LONG" )
        arcpy.management.AddField( tx, "OIDcom"  , "LONG" )
        arcpy.management.AddField( tx, "spurCost" , "FLOAT" )
        arcpy.management.AddField( tx, "spurLength_m"  , "FLOAT" )
        arcpy.management.CalculateField( tx, "spurOID", "!OBJECTID!")
        arcpy.management.CalculateField(tx, "OIDcom", "!DestID!")
        arcpy.management.CalculateField(tx, "spurCost" , "!PathCost!")
        arcpy.management.CalculateField(tx, "spurLength_m", "!Shape_Length!")
        arcpy.management.DeleteField(tx, ["DestID", "PathCost" ] )
        #join
        join = arcpy.AddJoin_management(projects, "OIDcom", tx, "OIDcom", "KEEP_ALL" )
        projSpurP = arcpy.conversion.ExportFeatures(join, r"memory\projSpurP")
        arcpy.management.RemoveJoin(join)
        arcpy.management.DeleteField(projSpurP, ["OBJECTID"] )
        arcpy.management.Delete(projects)
        arcpy.management.Delete(tx)
        WriteMsg("S8: Added " + S4Output + "_spurs to projects" )

        ###LANDFALL FOR OFF SPURS
        if Resource == "off":
            #prepare
            tx = arcpy.conversion.ExportFeatures(S4Output + "_landfall", r"memory\landF")
            arcpy.management.AddField(tx, "landOID", "LONG")
            arcpy.management.AddField(tx, "OIDcom", "LONG")
            arcpy.management.AddField(tx, "landfallCost", "FLOAT")
            arcpy.management.AddField(tx, "landfallLength_m", "FLOAT")
            arcpy.management.CalculateField(tx, "landOID", "!OBJECTID!")
            arcpy.management.CalculateField(tx, "OIDcom", "!DestID!")
            arcpy.management.CalculateField(tx, "landfallCost", "!PathCost!")
            arcpy.management.CalculateField(tx, "landfallLength_m", "!Shape_Length!")
            arcpy.management.DeleteField(tx, ["Shape", "OIDcom", "landOID", "landfallCost", "landfallLength_m"], "KEEP_FIELDS")
            #join
            join = arcpy.AddJoin_management(projSpurP, "OIDcom", tx, "OIDcom", "KEEP_ALL" )
            projSpur = arcpy.conversion.ExportFeatures(join, r"memory\projSpur")
            arcpy.management.RemoveJoin(join)
            arcpy.management.DeleteField(projSpur, ["OBJECTID"])
            arcpy.management.Delete(projSpurP)
            arcpy.management.Delete(tx)
            WriteMsg("S8: Added " + S4Output + "_landfall to off projects")
        else:
            projSpur = projSpurP

        ###BULK
        #prepare
        tx = arcpy.conversion.ExportFeatures( S5Output + "_bulk" , r"memory\bulk")
        arcpy.management.AddField( tx, "bulkOID" , "LONG" )
        #arcpy.management.AddField( tx, "bulkCost" , "FLOAT" )
        arcpy.management.AddField( tx, "bulkLength_m"  , "FLOAT" )
        arcpy.management.CalculateField( tx, "bulkOID", "!OBJECTID!")
        #arcpy.management.CalculateField(tx, "bulkCost" , "!bulkCost!")
        arcpy.management.CalculateField(tx, "bulkLength_m", "!Shape_Length!")
        #arcpy.management.DeleteField(tx, ["bulkCost" ] )
        #join
        join = arcpy.AddJoin_management(projSpur, "subOID", tx, "subOID", "KEEP_ALL" )
        projSpurBulk = arcpy.conversion.ExportFeatures(join, r"memory\projSpurBulk")
        arcpy.management.RemoveJoin(join)
        arcpy.management.DeleteField(projSpurBulk, ["OBJECTID", "subOID_1"] )
        arcpy.management.Delete(projSpur)
        arcpy.management.Delete(tx)
        WriteMsg("S8: Added " + S5Output + "_bulk to projects" )

        ###SINK
        #prepare
        tx = arcpy.conversion.ExportFeatures( S6Output + "_sink" , r"memory\sink")
        arcpy.management.AddField( tx, "sinkOID" , "LONG" )
        #arcpy.management.AddField( tx, "sinkLengthCostDist" , "FLOAT" )
        arcpy.management.AddField( tx, "sinkLength_m"  , "FLOAT" )
        arcpy.management.CalculateField( tx, "sinkOID", "!OBJECTID!")
        #arcpy.management.CalculateField(tx, "sinkLengthCostDist" , "!sinkCost!")
        arcpy.management.CalculateField(tx, "sinkLength_m", "!Shape_Length!")
        #arcpy.management.DeleteField(tx, ["sinkCost" ] )
        #join
        join = arcpy.AddJoin_management(projSpurBulk, "subOID", tx, "subOID", "KEEP_ALL" )
        projSpurBulkSink = arcpy.conversion.ExportFeatures(join, r"memory\projSpurBulkSink")
        arcpy.management.RemoveJoin(join)
        arcpy.management.DeleteField(projSpurBulkSink, ["OBJECTID", "subOID_1" , "Shape_Length_1"] )
        arcpy.management.Delete(projSpurBulk)
        arcpy.management.Delete(tx)
        WriteMsg("S8: Added " + S6Output + "_sinks to projects" )

        ###PREPARE EXPORT FOR JOIN and add to PROJ
        tx= arcpy.conversion.ExportFeatures( S7Output + "_export" , r"memory\export")
        arcpy.management.AddField( tx, "exportOID" , "LONG" )
        arcpy.management.AddField( tx, "OIDcom"  , "LONG" )
        arcpy.management.AddField(tx, "nodeID", "LONG")
        arcpy.management.AddField( tx, "exportCost" , "FLOAT" )
        arcpy.management.AddField( tx, "exportLength_m"  , "FLOAT" )
        arcpy.management.CalculateField( tx, "exportOID", "!OBJECTID!")
        arcpy.management.CalculateField(tx, "OIDcom", "!DestID!")
        arcpy.management.CalculateField(tx, "exportCost" , "!PathCost!")
        arcpy.management.CalculateField(tx, "exportLength_m", "!Shape_Length!")
        arcpy.management.CalculateField(tx, "nodeID", "!newID!")
        arcpy.management.DeleteField(tx, ["PathCost" , "DestID" , "newID" , "address" , "name" ] )
        #arcpy.conversion.ExportFeatures(tx, ScratchGDB + "\\A")
        #join
        join = arcpy.AddJoin_management(projSpurBulkSink, "OIDcom", tx, "OIDcom", "KEEP_ALL" )
        projWallp = arcpy.conversion.ExportFeatures(join, r"memory\projWallp")
        arcpy.management.RemoveJoin(join)
        arcpy.management.DeleteField(projWallp, ["OBJECTID", "OIDcom_1" , "OIDcom_12" , "Shape_Length_1" , "Shape_Length_12" , "Shape_Length_12_13"] )
        arcpy.management.Delete(projSpurBulkSink)
        arcpy.management.Delete(tx)
        WriteMsg("S8: Added " + S7Output + "_export to projects" )

        ###LANDFALL FOR OFF EXPORT
        if Resource == "off":
            #prepare
            tx = arcpy.conversion.ExportFeatures(S7Output + "_exportLandfall", r"memory\landF")
            arcpy.management.AddField(tx, "landOID", "LONG")
            arcpy.management.AddField(tx, "OIDcom", "LONG")
            arcpy.management.AddField(tx, "exportLandfallCost", "FLOAT")
            arcpy.management.AddField(tx, "exportLandfallLength_m", "FLOAT")
            arcpy.management.CalculateField(tx, "landOID", "!OBJECTID!")
            arcpy.management.CalculateField(tx, "OIDcom", "!DestID!")
            arcpy.management.CalculateField(tx, "exportLandfallCost", "!PathCost!")
            arcpy.management.CalculateField(tx, "exportLandfallLength_m", "!Shape_Length!")
            arcpy.management.DeleteField(tx, ["Shape", "OIDcom", "landOID", "exportLandfallCost", "exportLandfallLength_m"], "KEEP_FIELDS")
            #join
            join = arcpy.AddJoin_management(projWallp, "OIDcom", tx, "OIDcom", "KEEP_ALL" )
            projWall = arcpy.conversion.ExportFeatures(join, r"memory\projWall")
            arcpy.management.RemoveJoin(join)
            arcpy.management.DeleteField(projWall, ["OBJECTID"])
            arcpy.management.Delete(projWallp)
            arcpy.management.Delete(tx)
            WriteMsg("S8: Added " + S7Output + "_landfall to off projects")
        else:
            projWall = projWallp

        arcpy.conversion.ExportFeatures(projWall, S8Output )

        ###EXPORT TO RESULTS DIR
        arcpy.management.CopyRows(projWall, csvOUT + prefix + "S8_case" + exCase + ".csv")
        arcpy.management.Delete( csvOUT + prefix + "S8_case" + exCase + ".csv.xml")
        arcpy.management.Delete( csvOUT + "schema.ini")
        arcpy.management.Delete(projWall)

        # delete memory at end of stage
        arcpy.management.Delete("memory")
        end_time = time.time()
        WriteMsg("S8: Memory cache deleted, END mapVRE+ S8 taking " + str(round((end_time - start_time) / 60, 1)) + " minutes.")

    # END STAGE 8 #
    # _______________________________________________________________________________________________________________________#

    #_______________________________________________________________________________________________________________________#
    # STAGE 9 -  XYZ

    ###FUNCTIONS CALLED and REFERENCES


    if startStage <= 9 and endStage >= 9:
        WriteMsg("S9:Starting S9 with " + S8Output )
        start_time = time.time()

        # delete memory at end of stage
        arcpy.management.Delete("memory")
        end_time = time.time()
        WriteMsg("S9: Memory cache deleted, END mapVRE+ S9 taking " + str(round((end_time - start_time) / 60, 1)) + " minutes.")

    # END STAGE 9 #
    # _______________________________________________________________________________________________________________________#


    ##FINISH COLUMN RUN
    # delete memory at end of stage
    arcpy.management.Delete("memory")
    ColEnd_time = time.time()
    # str(arcpy.GetCount_management(S8Output)) +
    WriteMsg("Column Run: Memory cache deleted, END mapVRE+ Column Run for column " + str(column) + " taking " + str(round((ColEnd_time - ColStart_time) / 60, 1)) + " minutes on tasks for " + " " + Resource + " projects.")
    logfile.close()
# _______________________________________________________________________________________________________________________#
##FINISH COLUMN RUN
# delete memory at end of stage
arcpy.management.Delete("memory")
ScriEnd_time = time.time()
arcpy.AddMessage("All Column Runs Finished: Memory cache deleted, END script taking " + str(round((ScriEnd_time - ScriStart_time) / 60, 1)) + " minutes.")