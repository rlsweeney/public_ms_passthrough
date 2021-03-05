# Code and Data for Muehlegger and Sweeney, "Pass-Through of Own and Rival Cost Shocks: Evidence from the U.S. Fracking Boom,"  (*ReStat* 2021)

A pdf of the main text is available [here](draft/MS_passthrough.pdf). The online appendix is available [here](draft/MS_passthrough-appendix.pdf). 

## Code 

The code in this repository was run using Stata 15 MP and [`reghdfe`](http://scorreia.com/software/reghdfe/). There are two sets of code files. 
- `code/server` contains files that rely on confidential EIA data (described below). Once these data are obtained, all of the `.do` files can be executed, in order, by updating the paths in `code/server/setup.do` to match your machine, and calling `RunAll.do`. 
- `code/offline` contains files that either just create figures and tables from previously processed analysis, or rely solely on publicly available data. All of the `.do` files can be executed, in order, by updating the paths in `code/offline/setup_offline.do` to match your machine, and calling `RunDraftFiles.do`. This file produces all of the figures and tables in the paper:
    - `mono_EIA_oil_production_PADD.png`
    - `mono_oil_spot_price.png`
    - `mono_EIA_PADD_price_diff_brent.png`
    - `mono_DomFPP_HL_spread_4020.png`
    - `RivalComp_YM_st.tex`
    - `RivalComp_YM_fp.tex`
    - `mono_CO2TaxCDF_FP.png`
    - `mono_CO2Tax_PT_Allshocks.png`
    - `StateLevelFEComp.tex`

## Data

### Confidential EIA Data
The core data for this paper were obtained via confidential data use agreement with the Energy Information Administration. These datasets are: 
- **Monthly Refinery Report (EIA-810) -** Collects information regarding the balance between the supply (beginning stocks, receipts, and production) and disposition (inputs, shipments, fuel use and losses, and ending stocks) of crude oil and refined products located at refineries. 1986-2015. 
- **Annual Refinery Report (EIA-820) -** Collects data on: fuel, electricity, and steam purchased for consumption at the refinery; refinery receipts of crude oil by method of transportation; current and projected capacities for atmospheric crude oil distillation, downstream charge, and production capacities. 1986-1995, 1997, 1999-2015.
- **Refiners' Monthly Cost Report (EIA-14) -** Collects data on the weighted cost of crude oil at the regional Petroleum for Administration Defense District (PADD) level at which the crude oil is booked into a refinery. 2002-2015.
- **Refiners'/Gas Plant Operators' Monthly Petroleum Product Sales Report (EIA-782A) -** Price and volume data at the State level for 14 petroleum products for various retail and wholesale marketing categories are reported by the universe of refiners and gas plant operators.  1986-2015.
- **Monthly Report of Prime Supplier Sales of Petroleum Products Sold for Local Consumption (EIA-782C) -** Prime supplier sales of selected petroleum products into the local markets of ultimate consumption are reported by refiners, gas plant operators, importers, petroleum product resellers, and petroleum product retailers that produce, import, or transport product across State boundaries and local marketing areas and sell the product to local distributors, local retailers, or end users. 1986-1990, 1992-2015.

Additional information on each survey is available [here](https://www.eia.gov/survey/). 

To request access to the confidential survey responses, researchers must submit a confidential data request to the EIA. The person who facilitated our agreement, Joseph Conklin, no longer works at EIA. Interested researchers should contact the survey manager listed for each survey at the link above and ask to be directed to the appropriate confidentiality officer.

If these files are obtained, update the `eiadir` global path in `code/server/setup.do` to point to the directory. Note that the exact file names will likely contain the researchers name and date, along with the survey name, in the filepath.

### Public data 
The confidential data is supplemented with a variety of publicly available datasets from the EIA and EPA. The raw versions of these files are included in this repository under `data/public_data`. 
- **EIA data -** includes public crude price series, financial reporting summaries, spot prices, and aggregate shipment data. Additional information on each dataset, as well as links to download updated data, are provided in the "Contents" tab of each excel file. 
- **EPA data -** annual greenhouse gas emissions by refinery were extracted from EPA's [FLIGHT Tool](http://ghgdata.epa.gov/ghgp) on 6/1/2017. The data are provided in a single excel file here for convenience. 

### Manually entered data and helper files 
To facilitate cleaning up the confidential EIA data, several "intermediate" helper files were created. These files serve as an alternative to typing `var label` and `rename` statements in the `.do` files. 
- `782 labels - updated pre 94.xls`, `820codes.xls`, and `product_code_bridge_810_fin.xls` assign interpretable names to surveys 782, 820 and 810 respectively. 
- `refinery_info_locations.dta` maps publicly available [EIA geolocation information](https://www.eia.gov/maps/map_data/Petroleum_Refineries_US_EIA.zip) to the confidential refinery data. It also links to the EPA GHG data. 
- `shipping_costs_by_ref.dta` computes the shipping cost to each state by refinery as described in Sweeney (2015). 
- `region_definitions.dta` processes EIA region and state names, and `state_demo_data.dta` brings in state level population and weather data. 


## Results files 

Although we no longer have access to the confidential EIA data, all of the regression results files (Stata `.ster` files) generated by the code above are available upon request. 