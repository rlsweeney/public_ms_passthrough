* MAIN SAMPLE RESTRICTIONS
* RESTRICT TO ACTIVE FIRMS WITH LIGHT PRODUCTION 

drop if av_sales < 1000 & (prod == "_T" | prod == "_TP")
drop if av_sales < 500 & (prod == "_G" | prod == "_D")
drop if av_sales < 250 & (prod == "_O")

drop if av_frac_resale < .5
drop if av_frac_light < 0.5
