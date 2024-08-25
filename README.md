# netzero_navigate

This repository contains data, code and outputs for the manuscript on nativagiting conflicts with natural capital in net-zeo emissions transitions.  

## Source files

All (non-GIS) source files needed to reproduce analyses here

## Code folder

All scripts to reproduce code-based analyses here. These include scripts developed by the repository owner, scripts provided by Evolved Energy Research (EER), and portions of scripts representing a fork of a MapRE repository. Scripts provided by EER are marked with "_eer" at the end of the file name (*_eer). Code representing the fork of the MapRE repository are marked with comments within files. Credit details and development of code and methods are provided at the bottom of this readme (and in main code file). 

## Results folder

All (non-GIS) results are saved into this folder.  

## GIS folder

All GIS source and output files are contained in the arcGIS geodatabase's (*.gdb) in this folder

## Credits
Suggested Citation (to be updated): 
Pascale, A., Watson, J., Davis, D., Smart, S., Braer, M., Jones,R., Greig, C. Negotiating risks to natural capital and stakeholder values in net-zero transitions. In progress. (2024).

1. The process described in provided code was seeded by the TNC's Power of Place California project (PoPC)
	1. Wu, Grace C., Emily Leslie, Douglas Allen, Oluwafemi Sawyerr, D. Richard Cameron, Erica Brand, Brian Cohen, Marcela Ochoa, and Arne Olsen. “Power of Place, Land Conservation and Clean Energy Pathways for California,” 2019.

2. Original source code for stages 1-3 of the process was cloned from this gitHub Repo (https://github.com/cetlab-ucsb/mapre) on ~3 April 2021 for use on Net-Zero Australia. Projects prior to NZAu used toolbox versions of MapRE run in ArcMap.
	1. Deshmukh, Ranjit, Grace Wu, and USDOE. “MapRE GIS Tools & Data (MapRE).” United States, March 10, 2016. https://doi.org/10.11578/dc.20210416.67.
	2. Wu, Grace C., Ranjit Deshmukh, Kudakwashe Ndhlukula, Tijana Radojicic, Jessica Reilly-Moman, Amol Phadke, Daniel M. Kammen, and Duncan S. Callaway. “Strategic Siting and Regional Grid Interconnections Key to Low-Carbon Futures in African Countries.” Proceedings of the National Academy of Sciences 114, no. 15 (April 11, 2017): E3004–12. https://doi.org/10.1073/pnas.1611845114.

3. The process was developed by the author, with collaborators listed as co-authors, on these projects
	1. Larson, Eric, Chris Greig, Jesse Jenkins, Erin Mayfield, Andrew Pascale, Chuan Zhang, Joshua Drossman, et al. “Net-Zero America: Potential Pathways, Infrastructure, and Impacts.” Final Report. Princeton, NJ: Princeton University, October 29, 2021. https://netzeroamerica.princeton.edu/.
		1. realizes working version of least-cost transmission routing and costing process discussed as an area for further work by PoPC.
		2. for process details see Pascale, A, Jesse Jenkins. "Annex F: Integrated Transmission Line Mapping and Costing" (https://netzeroamerica.princeton.edu/img/NZA%20Annex%20F%20-%20HV%20Transmission.pdf)
	2. Wu, Grace C., Ryan A. Jones, Emily Leslie, James H. Williams, Andrew Pascale, Erica Brand, Sophie S. Parker, et al. “Minimizing Habitat Conflicts in Meeting Net-Zero Energy Targets in the Western United States.” Proceedings of the National Academy of Sciences 120, no. 4 (January 24, 2023): e2204098120. https://doi.org/10.1073/pnas.2204098120.
		1. extends methods developed for (a) to introduce more complex transmission routing surfaces, linking of mapped transmission costs to CPAs, and seperation of transmission siting process into two steps: a) routing step, b) costing step
	3. Patankar, Neha, Xiili Sarkela-Basset, Greg Schivley, Emily Leslie, and Jesse Jenkins. “Land Use Trade-Offs in Decarbonization of Electricity Generation in the American West.” Energy and Climate Change 4 (December 1, 2023): 100107. https://doi.org/10.1016/j.egycc.2023.100107.
	4. Patankar, Neha, Xiili Sarkela-Basset, Greg Schivley, Emily Leslie, and Jesse Jenkins. “Corrigendum to ‘Land Use Trade-Offs in Decarbonization of Electricity Generation in the American West’ [Energy and Climate Change 4 (2023) 100107].” Energy and Climate Change, March 21, 2024, 100130. https://doi.org/10.1016/j.egycc.2024.100130.
		1. extends methods developed for (b) by allowing use of only a single 'costing' surface for all transmission line types (designed and manually implemented by A Pascale) 
		2. prior methods and extension is coded into python/QGIS for use in REPEAT by REPEAT code team
		3. REPEAT also developed new ways of combining CPAs and transmission and grouping them for use in capacity extension models (see journal paper).
	5. Davis, Dominic, Andrew C. Pascale, Bishal Bharadaj, Richard Bolt, Michael Brear, Brendan Cullen, Robin Batterham, et al. “Methods, Assumptions, Scenarios & Sensitivities,” April 19, 2023. https://www.netzeroaustralia.net.au/wp-content/uploads/2023/04/Net-Zero-Australia-Methods-Assumptions-Scenarios-Sensitivities.pdf.
		1. full process from one to seven is developed in python and arcPy and successfully implemented for use on Net Zero Australia project
			1. MapRE code used in stages 1-3 was cloned from MapRE repo (see item 2)
			2. Transmission steps previously run manually were coded into steps 4-7 and into the optional functions found in code for A1 to A6
		2. full functionality of REPEAT project grouping was not possible to do on NZAu due to limits on time and computing infrastructure.
		3. Code for stage 4 was provided to TNC Power of Place National project (8 Sept 2022), and was used - with modification - to run spur TX routing for that project
		4. For demonstrations of use of provided code for mapping and additional analyses during downscaling see
			1. Pascale, Andrew, Utkarsh Kiri, Dominic Davis, and Simon Smart. “Downscaling – Solar, Wind and Electricity Transmission Siting.” In Net Zero Australia, 2023. https://www.netzeroaustralia.net.au/wp-content/uploads/2023/04/Downscaling-Solar-wind-electricity-transmission-siting.pdf.
			2. Pascale, Andrew, Dominic Davis, James EM Watson, Simon Smart, Michael Brear, Julian McCoy, Maria Lopez Peralta, et al. “Downscaling – Net-Zero Transitions, Australian Communities, the Land and Sea.” In Net Zero Australia, 2023. https://www.netzeroaustralia.net.au/wp-content/uploads/2023/04/Downscaling-Land-use-impacts-on-Australian-communities-the-land-sea.pdf.
4. CODE CLEANED, REWRITTEN, AND PLACED IN SINGLE FILE FOR USE ON Natural Capital paper and training for UoM
	1. deep clean on MapRE code, fixing bugs, updating functions, simplifying code, and rewriting to implement new functionality (e.g. heat maps and individual layer exports from stage 1)
		1. improve memory handling; deleted (most) unused code; no longer supports CSP; rewrote to make exclusion layer overlay maps and simplify code; remove shapefile support for projects; added median and variety calculations;
	2. provided as is to UoM Boundless project in April 2024
	 
5. Bug discovery and fixes supplied by Yimin Zhang (UoM): fixes in sink transmission costing and in availability of offshore wind projects (these bugs impact prior NZAu results)

6. Added EER (https://www.evolved.energy/) supply curve code to process and modified to recreate lost code and parameters and use for paper.

7. Code and data will be posted as is for use with a manuscript, but will be cleaned and combined into a single programming language, to aid user accessibility