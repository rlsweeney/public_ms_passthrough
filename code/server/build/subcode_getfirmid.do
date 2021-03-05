capture drop firmid 

gen firm_id = my_corp_id
gen firm_name = my_corp_name_clean
la var firm_id "Firm ID (cleaned)"
