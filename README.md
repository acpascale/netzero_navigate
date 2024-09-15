# netzero_navigate

This repository contains data, code and outputs for the manuscript on nativagiting conflicts with natural capital in net-zeo emissions transitions.  

## Source files

All (non-GIS) source files needed to reproduce analyses here. 

## Code folder

All scripts to reproduce code-based analyses here. These include scripts developed by the repository owner, scripts provided by Evolved Energy Research (EER), and portions of scripts representing a fork of a MapRE repository. Scripts provided by EER are marked with "_eer" at the end of the file name (*_eer). Code representing the fork of the MapRE repository are marked with comments within files. Credit details and development of code and methods are provided at the bottom of this readme (and in main code file). 

**Note that stages 1-3 cannot be run without downloading files owned by other organizations, and placing them in the appropriate GIS location. See "/d0_2code/parameters/mpv1_[x].csv" , "/d0_2code/parameters/mvp0_paper_setup.csv" , and "mpv3_paper_all.csv" files.  Users should paramterize the "/d0_2code/parameters/mvp0_paper_setup.csv" file to start with stage 4. Stage 3 outputs have been placed in the appropriate GIS folder so that stages four to eight can be run. Stage eight outputs are also in this folder if one wants to skip stages 1-8 all together.

Additional code (not used in paper, but extended functionality to mapping of selected projects and transmission) will be added over time as a Fork of this directory.

## Results folder

All (non-GIS) results are saved into this folder.  

## GIS folder

Paper GIS source and output files are contained in the arcGIS geodatabase's (*.gdb) in this folder

Layers sourced from other organizations have not been provided - see **Note in [Code Folder](#Code-folder).  

Pre-seeded results (netNav_results.gdb) and additional GIS database (netNav_baseAdd.gdb) are available for download here: https://drive.google.com/drive/folders/15eRm0PjM5-2UG7W5wiJL8qs9y2ONUB7Q?usp=sharing

## Tables and Figures 

Files for all paper Figures (png, 300dpi). Excel workbook with all paper Tables. 

## Credits
Suggested Citation (to be updated): 
Andrew Pascale, James Watson, Dominic Davis et al. Negotiating risks to natural capital and stakeholder values in net-zero transitions, 05 September 2024, PREPRINT (Version 1) available at Research Square [https://doi.org/10.21203/rs.3.rs-4971429/v1]


## Additional credits
1. The process described in provided code was seeded by the TNC's Power of Place California project (PoPC)
	1. Wu, Grace C., Emily Leslie, Douglas Allen, Oluwafemi Sawyerr, D. Richard Cameron, Erica Brand, Brian Cohen, Marcela Ochoa, and Arne Olsen. “Power of Place, Land Conservation and Clean Energy Pathways for California,” 2019.

2. Original source code for stages 1-3 of the process was cloned from this gitHub Repo (https://github.com/cetlab-ucsb/mapre) on ~3 April 2021 for use on Net-Zero Australia. Projects prior to NZAu used toolbox versions of MapRE run in ArcMap.
	1. Deshmukh, Ranjit, Grace Wu, and USDOE. “MapRE GIS Tools & Data (MapRE).” United States, March 10, 2016. https://doi.org/10.11578/dc.20210416.67.
	2. Wu, Grace C., Ranjit Deshmukh, Kudakwashe Ndhlukula, Tijana Radojicic, Jessica Reilly-Moman, Amol Phadke, Daniel M. Kammen, and Duncan S. Callaway. “Strategic Siting and Regional Grid Interconnections Key to Low-Carbon Futures in African Countries.” Proceedings of the National Academy of Sciences 114, no. 15 (April 11, 2017): E3004–12. https://doi.org/10.1073/pnas.1611845114.

3. The process was developed by the author, with collaborators listed as co-authors, on these projects
	1. Larson, Eric, Chris Greig, Jesse Jenkins, Erin Mayfield, Andrew Pascale, Chuan Zhang, Joshua Drossman, et al. “Net-Zero America: Potential Pathways, Infrastructure, and Impacts.” Final Report. Princeton, NJ: Princeton University, October 29, 2021. https://netzeroamerica.princeton.edu/.
		1. Realizes working version of least-cost transmission routing and costing process - discussed as an area for further work by PoPC.
		2. For process details see Pascale, A, Jesse Jenkins. "Annex F: Integrated Transmission Line Mapping and Costing" (https://netzeroamerica.princeton.edu/img/NZA%20Annex%20F%20-%20HV%20Transmission.pdf)
	2. Wu, Grace C., Ryan A. Jones, Emily Leslie, James H. Williams, Andrew Pascale, Erica Brand, Sophie S. Parker, et al. “Minimizing Habitat Conflicts in Meeting Net-Zero Energy Targets in the Western United States.” Proceedings of the National Academy of Sciences 120, no. 4 (January 24, 2023): e2204098120. https://doi.org/10.1073/pnas.2204098120.
		1. Introduces more complex transmission routing surfaces, linking of mapped transmission costs to CPAs, and seperation of transmission siting process into two steps: a) routing step, b) costing step
	3. Patankar, Neha, Xiili Sarkela-Basset, Greg Schivley, Emily Leslie, and Jesse Jenkins. “Land Use Trade-Offs in Decarbonization of Electricity Generation in the American West.” Energy and Climate Change 4 (December 1, 2023): 100107. https://doi.org/10.1016/j.egycc.2023.100107.
	4. Patankar, Neha, Xiili Sarkela-Basset, Greg Schivley, Emily Leslie, and Jesse Jenkins. “Corrigendum to ‘Land Use Trade-Offs in Decarbonization of Electricity Generation in the American West’ [Energy and Climate Change 4 (2023) 100107].” Energy and Climate Change, March 21, 2024, 100130. https://doi.org/10.1016/j.egycc.2024.100130.
		1. Allows the use of only a single 'costing' surface for all transmission line types (designed and manually implemented by A Pascale) 
		2. Methods developed and implemented manually on prior projects are coded into python/QGIS for use in REPEAT by REPEAT code team
		3. REPEAT also develops new ways of bundling CPAs, allowing multiple transmission options, each with a different load destination
	5. Davis, Dominic, Andrew C. Pascale, Bishal Bharadaj, et al. “Methods, Assumptions, Scenarios & Sensitivities,” April 19, 2023. https://www.netzeroaustralia.net.au/wp-content/uploads/2023/04/Net-Zero-Australia-Methods-Assumptions-Scenarios-Sensitivities.pdf.
		1. Full process (stages 1 to 7 in supplied code) is developed in python + arcPy and successfully implemented for use on Net Zero Australia project
			1. Stages 1 to 3 use MapRE code that is cloned from public repository (see item 2)
			2. Stages 4 to 7 comprise transmission focused steps that were previously run manually
		2. Full functionality of REPEAT project grouping was not possible to do on NZAu due to limits on time and computing infrastructure, but two transmission options are routed for each CPA, a) nearest load (bulk) and b) nearest regional sink (sink)
		3. Code for stage 4 was provided to TNC Power of Place National project (8 Sept 2022), and was used - with modification - to run spur TX routing for that project
		4. For demonstrations of use of provided code for mapping and additional analyses during downscaling see
			1. Pascale, Andrew, Utkarsh Kiri, Dominic Davis, and Simon Smart. “Downscaling – Solar, Wind and Electricity Transmission Siting.” In Net Zero Australia, 2023. https://www.netzeroaustralia.net.au/wp-content/uploads/2023/04/Downscaling-Solar-wind-electricity-transmission-siting.pdf.
			2. Pascale, Andrew, Dominic Davis, James EM Watson, Simon Smart, Michael Brear, Julian McCoy, Maria Lopez Peralta, et al. “Downscaling – Net-Zero Transitions, Australian Communities, the Land and Sea.” In Net Zero Australia, 2023. https://www.netzeroaustralia.net.au/wp-content/uploads/2023/04/Downscaling-Land-use-impacts-on-Australian-communities-the-land-sea.pdf.
4. CODE CLEANED, REWRITTEN, AND PLACED IN SINGLE FILE FOR USE ON Natural Capital paper and training for UoM
	1. Deep clean on MapRE code (Stages 1 to 3), fixing bugs, updating functions, simplifying code, and rewriting to implement new functionality (e.g. heat maps and individual layer exports from stage 1)
		1. Notes: Improve memory handling; deleted (most) unused code; no longer supports CSP; rewrote to make exclusion layer overlay maps and simplify code; remove shapefile support for projects; added median and variety calculations.
	2. Add optional functions found in code stages A1 to A6, which demonstrate functions for preparing inputs to transmission routing process (e.g. cost surfaces, generic substations, etc)
	2. Modify structure and imrpove documentation for planned training at UoM in April 2024 
	3. Provided, with training, to UoM Boundless project in April 2024 (it is hoped that at some time in the future, their fork of this code - which is fully in python, and aligns with best practice python inplementation, will become publically available).
	 
5. Implement code to fix bugs identified by Yimin Zhang (UoM): fixes in sink transmission costing and in availability of offshore wind projects (these bugs impact prior NZAu results).

6. Added EER (https://www.evolved.energy/) supply curve binning code to repository. Repository version represents code that has modified (by first author) to recreate code and parameters lost by EER following NZAu project and has been extended to reflect adjusted focus of journal paper.


## Code and Software Submission Requirements
see https://www.nature.com/documents/nr-software-policy.pdf

### System Requirements
1. Users will need environments in which R, python, and arcPy code can be run.
	1. The last base R release the code was tested on is version 4.4.0, which was run via RStudio 2024.04.2 Build 764.
	2. A python 3.11 interpreter based on an acrgispro-py3 clone was run in PyCharm 2024.1.2 (Community Edition) Build #PC-241.17011.127, built on May 28, 2024.
2. R code requires the following packages (last version the code was tested on): openxlsx (4.2.5.2), reshape2 (1.4.4).
3. Ordinary python imports (e.g. os, numpy, pandas, etc) are listed in each relevant file. Python code additionaly requires the installation of the scikit-learn package, with the last version the code was tested on being 1.4.2 .
4. No non-standard hardware is required.

### Installation guide
1. As long as directory structure is maintained and parameter files are altered for each specific run environemnt, there are no custom installation instructions.

### Demo
1. Stages 1-3 and some optional stages (in 1_stage1to8.py file) cannot be run without downloading files owned by other organizations, and placing them in the appropriate GIS location. 
	1. See "/d0_2code/parameters/mpv1_[x].csv", "/d0_2code/parameters/mvp0_paper_setup.csv" , and "mpv3_paper_all.csv" files. 
	2. If not downloading external files, users should paramterize the 'Start Stage row" in the "/d0_2code/parameters/mvp0_paper_setup.csv" file to start with stage 4. 
2. Expected outputs of all stages (including 1 and 2) have been placed in the appropriate GIS and data folders so that stages four to eight can be run, along with later code files ("2_stage9.r" , "3_stage10_eer.py", "4_stage11.r").
   1. Pre-seeded results (netNav_results.gdb) and additional GIS database (netNav_baseAdd.gdb) are available for download here: https://drive.google.com/drive/folders/15eRm0PjM5-2UG7W5wiJL8qs9y2ONUB7Q?usp=sharing
3. For R files, it is suggested that a base directory [base path here] is set in the appropriate line of code in each file to ease use: setwd("[base path here]/netzero_navigate/d0_2code")
4. Expected run time to complete all stages for all resources and cases may span 6-48 hours depending on computer specifications. Expected run times decrease to minutes (<1 hour) when starting with stage 8 or beyond. 

### Instructions for use
1. Install code interpreters and set up R and python code environments to access interpreters. Install additional packages.
2. Parameterize "/d0_2code/parameters/mpv1_[x].csv", "/d0_2code/parameters/mvp0_paper_setup.csv" , and "mpv3_paper_all.csv" files for directory structure of each user's system, along with base paths for each code chunk (see item 4 in last section).
3. Run code in sequential order, "1_[x].py" , "2_[x].r" , "3_[x].py", "4_[x].r". Warnings will occur in "3_[x].py" but will not impact duplication of results.
4. We have not provided detailed instructions for reproducing the manual analyses run using generic ArcGIS pro packages (e.g. ZonalStatisticsAsTable - https://pro.arcgis.com/en/pro-app/latest/tool-reference/spatial-analyst/zonal-statistics-as-table.htm).