* CREATE ADDITIONAL INSTRUMENTS BASED ON INTERACTIONS

foreach v of varlist *_DScap {
	di "`v'"
	gen `v'_HL = `v' * hl_spread_dom
}


foreach v of varlist *P24 {
	di "`v'"
	gen `v'_US = `v' * (p_wti - brent_cru)
}
