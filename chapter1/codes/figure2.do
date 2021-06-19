* Author: Sai Zhang (saizhang.econ@gmail.com)
* This file is used to produce figure  in Chapter 1 (see page ).

* The NYSE-listed stocks' monthly returns are downloaded from WRDS.
* links are here: https://wrds-www.wharton.upenn.edu/pages/get-data/center-research-security-prices-crsp/

global rootdir = "~/Desktop/LIT/empirical-finance-literature"
global datadir = "~/Desktop/LIT/empirical finance literature data"
global outdir = "${rootdir}/chapter1/outputs"
global indir = "${datadir}/chapter1"

use `"${indir}/monthly_NYSE_return.dta"', clear

* generate the 17-industry SIC classification
do `"${rootdir}/chapter1/codes/sic_17classification.do"'

* generate annually-updated size deciles
preserve
keep PERMNO date PRC SHROUT
keep if month(date) == 12
gen mkt_cap = PRC * SHROUT
* the diciles are for the next year
gen year = year(date) + 1

gen DECILE = .

forvalues i = 1/9{
    local j=10*`i'
    bys datadate: egen ME_p`j' = pctile(MElag) if exchcd == 1, p(`j')
    sort datadate ME_p`j'
    by datadate: replace ME_p`j' = ME_p`j'[_n-1] if ME_p`j' == .
    replace DECILE = `i' if MElag <= ME_p`j' & DECILE == .
    drop ME_p`j'
}

bys datadate: egen ME_p90 = pctile(MElag) if exchcd == 1, p(90)
sort datadate ME_p90
by datadate: replace ME_p90 = ME_p90[_n-1] if ME_p90 == .
replace DECILE = 10 if MElag > ME_p90 & DECILE == .
drop ME_p90

rename DECILE DECILEmth
