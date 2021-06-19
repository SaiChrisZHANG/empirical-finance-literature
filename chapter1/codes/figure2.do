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

gen size_decile = .

forvalues i = 1/9{
    local j=10*`i'
    bys date: egen size_p`j' = pctile(mkt_cap), p(`j')
    sort date size_p`j'
    by date: replace size_p`j' = size_p`j'[_n-1] if size_p`j' == .
    replace size_decile = `i' if mkt_cap <= size_p`j' & size_decile == .
    drop size_p`j'
}

bys date: egen size_p90 = pctile(mkt_cap) if exchcd == 1, p(90)
sort date size_p90
by date: replace size_p90 = size_p90[_n-1] if size_p90 == .
replace size_decile = 10 if mkt_cap > size_p90 & size_decile == .
drop size_p90

