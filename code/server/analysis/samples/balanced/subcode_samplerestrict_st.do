* MAKE ADDITIONAL SAMPLE RESTRICTIONS

drop if av_sales < 100 & (prod == "_T" | prod == "_TP")
drop if av_sales < 50 & (prod == "_G" | prod == "_D")
drop if av_sales < 25 & (prod == "_O")

*could prob do a better job removing obs where it doesn't look like the firm is operating

*drop if av_mshare < .01
drop if av_frac_resale < .5
drop if av_frac_light < 0.5

drop if fepers < 96
