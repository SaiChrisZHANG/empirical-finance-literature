* Author: Sai Zhang (saizhang.econ@gmail.com)
* This file is used to produce figure  in Chapter 1 (see page ).

* The NYSE-listed stocks' monthly returns are downloaded from WRDS.
* links are here: https://wrds-www.wharton.upenn.edu/pages/get-data/center-research-security-prices-crsp/

global rootdir = "~/Desktop/LIT/empirical-finance-literature"
global datadir = "~/Desktop/LIT/empirical finance literature data"
global outdir = "${rootdir}/chapter1/outputs"
global indir = "${datadir}/chapter1"

use `"${indir}/monthly_NYSE_return.dta"', clear

* call a do file to generate the 17-industry SIC classification
do `"${rootdir}/chapter1/codes/sic_17classification.do"'

* ======================================
* generate annually-updated size deciles
* ======================================
tempfile size_decile
preserve
keep PERMNO date PRC SHROUT
keep if month(date) == 12
gen mkt_cap = PRC * SHROUT
* the diciles are for the next year
gen year = year(date) + 1
* generate the deciles
qui{
    cap drop size_decile
    gen size_decile = .
    forvalues i = 1/9{
        local j=10*`i'
        bys date: egen size_p`j' = pctile(mkt_cap), p(`j')
        sort date size_p`j'
        replace size_decile = `i' if mkt_cap <= size_p`j' & size_decile == .
        drop size_p`j'
    }
}
replace size_decile=10 if mi(size_decile)
keep PERMNO year size_decile
save `size_decile', replace
restore
* merge the deciles back
gen year = year(date)
merge m:1 PERMNO year using `size_decile'
drop if _merge==2
* no 2021 return information in the data set
drop _merge

* ======================================
* generate compounded returns
* ======================================
* Step 1: adjust returns for inflation with CPI
*         historical inflation rates are downloaded from WRDS (https://wrds-www.wharton.upenn.edu/pages/get-data/center-research-security-prices-crsp/annual-update/index-treasury-and-inflation/us-treasury-and-inflation-indexes/)
gen yyyymm = year(date)*100 + month(date)
merge m:1 yyyymm using `"${indir}/monthly_cpi_inflation.dta"', nogen
gen ret_adj = (1+RET)/(1+cpiret)-1

* Step 2: generate 2 equal-weighted portfolio average returns, equal-weighted and value-weighted market returns
*         one by the size deciles, one by the 17-industry classification
preserve
*** decile-size portfolio returns
bys size_decile date: egen mthret_size = mean(ret_adj)
keep mthret_size date size_decile
duplicates drop size_decile date, force

restore
preserve
*** insdustry portfolio returns
bys sic_17 date: egen mthret_sic = mean(ret_adj)
keep mthret_sic date sic_17
duplicates drop sic_17 date, force

restore
preserve
*** market average returns
sort PERMNO date
by PERMNO: gen mkt_cap_w = PRC[_n-1]*SHROUT[_n-1]
gen ret_adj_w = mkt_cap_w * ret_adj
bys date: egen mthret_mkt = mean(ret_adj)
bys date: egen up = total(ret_adj_w)
bys date: egen down = total(mkt_cap_w)
gen mthret_mkt_w = up/down
keep mthret_mkt mthret_mkt_w date
duplicates drop date, force
restore

* =========


postfile handle str32 varname b se using bse, replace
local regression_vars  // CREATE A LOCAL MACRO CONTAINING THE NAMES OF YOUR VARIABLES
foreach r of local regression_vars {
    post handle ("`r'") (_b[`r']) (_se[`r'])
}
postclose handle
