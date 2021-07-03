* Author: Sai Zhang (saizhang.econ@gmail.com)
* This file is used to produce figure  in Chapter 1 (see page ), replicating Fama and French (1988).

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
    replace size_decile=10 if mi(size_decile)
    keep PERMNO year size_decile
    save `size_decile', replace
}
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
gen mth_dt = ym(year(date),month(date))
format mth_dt %tm
drop yyyymm

* Step 2: generate 2 equal-weighted portfolio average returns, equal-weighted and value-weighted market returns
*         one by the size deciles, one by the 17-industry classification
* Step 3: generate 1-10 year compounding returns, by summing monthly returns in 1-10 year's period of time

* necessary codes
cap ssc install rangestat
* a simple function to generate compounding returns
cap program drop ret_compound
program ret_compound
    args retvar datevar period portfolio
    local T = `period'*12

    * full sample
    rangestat (sum) compret_T`period'_minus_ol = `retvar', interval(`datevar',-`T',0) by(`portfolio')
    rangestat (sum) compret_T`period'_plus_ol = `retvar', interval(`datevar',0,`T') by(`portfolio')
    rangestat (obs) periods_minus = `portfolio', interval(`datevar',-`T',0) by(`portfolio')
    rangestat (obs) periods_plus = `portfolio', interval(`datevar',0,`T') by(`portfolio')
    replace compret_T`period'_minus_ol = . if periods_minus < `T'+1
    replace compret_T`period'_plus_ol = . if periods_plus < `T'+1
    drop periods_minus periods_plus

    * non-overlapping
    local T_1 = `T'-1
    rangestat (sum) compret_T`period'_minus_nol = `retvar', interval(`datevar',-`T',-1) by(`portfolio')
    rangestat (sum) compret_T`period'_plus_nol = `retvar', interval(`datevar',0,`T_1') by(`portfolio')
    rangestat (obs) periods_minus = `portfolio', interval(`datevar',-`T',-1) by(`portfolio')
    rangestat (obs) periods_plus = `portfolio', interval(`datevar',0,`T_1') by(`portfolio')
    replace compret_T`period'_minus_nol = . if periods_minus < `T' | mi(periods_minus)
    replace compret_T`period'_plus_nol = . if periods_plus < `T'
    drop periods_minus periods_plus
end

*** decile-size portfolio returns
tempfile mthret_size
preserve
bys size_decile mth_dt: egen mthret_size = mean(ret_adj)
keep mthret_size mth_dt size_decile
duplicates drop size_decile mth_dt, force
sort size_decile mth_dt
forvalues t = 1/10{
    qui ret_compound mthret_size mth_dt `t' size_decile
}
save `mthret_size', replace
restore

*** insdustry portfolio returns
tempfile mthret_sic
preserve
replace sic_17 = 17 if sic_17 == 18
bys sic_17 mth_dt: egen mthret_sic = mean(ret_adj)
keep mthret_sic mth_dt sic_17
duplicates drop sic_17 mth_dt, force
sort sic_17 mth_dt
forvalues t = 1/10{
    qui ret_compound mthret_sic mth_dt `t' sic_17
}
save `mthret_sic', replace
restore

*** market average returns
tempfile mthret_mkt
tempfile mthret_mkt_w
preserve
sort PERMNO mth_dt
by PERMNO: gen mkt_cap_w = PRC[_n-1]*SHROUT[_n-1]
gen ret_adj_w = mkt_cap_w * ret_adj
bys mth_dt: egen mthret_mkt = mean(ret_adj)
bys mth_dt: egen up = total(ret_adj_w)
bys mth_dt: egen down = total(mkt_cap_w)
gen mthret_mkt_w = up/down
keep mthret_mkt mthret_mkt_w mth_dt
duplicates drop mth_dt, force
sort mth_dt
* tag is a pseudo-portfolio indicator
gen tag = 1
forvalues t = 1/10{
    qui ret_compound mthret_mkt mth_dt `t' tag
}
save `mthret_mkt', replace

keep mthret_mkt mthret_mkt_w mth_dt tag
forvalues t = 1/10{
    qui ret_compound mthret_mkt_w mth_dt `t' tag
}
drop tag
save `mthret_mkt_w', replace
restore
clear

* ======================================
* run regressions and generate figures
* ======================================
* Note: following codes use 1926-2020 data, I separately
*       run 1926-1985 sub-period for replication and 1986-2020 for new trends
* ++++++++++++++++++++++++++++++++++++++++
* size-based decile portfolios
use `mthret_size', clear

postfile handle size_decile year str32 adj_method str32 overlapping str32 sampling b se using "${indir}/size10_betas.dta", replace
forvalues decile = 1/10{
    preserve
    keep if size_decile == `decile'
    tsset mth_dt

    forvalues t = 1/10{
        * full sample
        * r(t,t+T) on r(t-T,t)
        * Hansen-Hodrick (1980) adjusted SE
        qui ivreg2 compret_T`t'_plus_ol compret_T`t'_minus_ol, kernel(tru) bw(12) r
        post handle (`decile') (`t') ("HH") ("OL") ("Full") (_b[compret_T`t'_minus_ol]) (_se[compret_T`t'_minus_ol])
        * Newey-West (1994) adjusted SE
        qui ivreg2 compret_T`t'_plus_ol compret_T`t'_minus_ol, kernel(bar) bw(auto) r
        post handle (`decile') (`t') ("NW") ("OL") ("Full") (_b[compret_T`t'_minus_ol]) (_se[compret_T`t'_minus_ol])
        
        * r(t,t+T-1) on r(t-T,t-1)
        * Hansen-Hodrick (1980) adjusted SE
        qui ivreg2 compret_T`t'_plus_nol compret_T`t'_minus_nol, kernel(tru) bw(12) r
        post handle (`decile') (`t') ("HH") ("NOL") ("Full") (_b[compret_T`t'_minus_nol]) (_se[compret_T`t'_minus_nol])
        * Newey-West (1994) adjusted SE
        qui ivreg2 compret_T`t'_plus_nol compret_T`t'_minus_nol, kernel(bar) bw(auto) r
        post handle (`decile') (`t') ("NW") ("NOL") ("Full") (_b[compret_T`t'_minus_nol]) (_se[compret_T`t'_minus_nol])

        * replication sample (before 1986)
        qui ivreg2 compret_T`t'_plus_ol compret_T`t'_minus_ol if yofd(dofm(mth_dt))<1986, kernel(tru) bw(12) r
        post handle (`decile') (`t') ("HH") ("OL") ("Pre-1986") (_b[compret_T`t'_minus_ol]) (_se[compret_T`t'_minus_ol])
        qui ivreg2 compret_T`t'_plus_ol compret_T`t'_minus_ol if yofd(dofm(mth_dt))<1986, kernel(bar) bw(auto) r
        post handle (`decile') (`t') ("NW") ("OL") ("Pre-1986") (_b[compret_T`t'_minus_ol]) (_se[compret_T`t'_minus_ol])
        qui ivreg2 compret_T`t'_plus_nol compret_T`t'_minus_nol if yofd(dofm(mth_dt))<1986, kernel(tru) bw(12) r
        post handle (`decile') (`t') ("HH") ("NOL") ("Pre-1986") (_b[compret_T`t'_minus_nol]) (_se[compret_T`t'_minus_nol])
        qui ivreg2 compret_T`t'_plus_nol compret_T`t'_minus_nol if yofd(dofm(mth_dt))<1986, kernel(bar) bw(auto) r
        post handle (`decile') (`t') ("NW") ("NOL") ("Pre-1986") (_b[compret_T`t'_minus_nol]) (_se[compret_T`t'_minus_nol])

        * new sample (since 1986)
        qui ivreg2 compret_T`t'_plus_ol compret_T`t'_minus_ol if yofd(dofm(mth_dt))>1985, kernel(tru) bw(12) r
        post handle (`decile') (`t') ("HH") ("OL") ("Post-1986") (_b[compret_T`t'_minus_ol]) (_se[compret_T`t'_minus_ol])
        qui ivreg2 compret_T`t'_plus_ol compret_T`t'_minus_ol if yofd(dofm(mth_dt))>1985, kernel(bar) bw(auto) r
        post handle (`decile') (`t') ("NW") ("OL") ("Post-1986") (_b[compret_T`t'_minus_ol]) (_se[compret_T`t'_minus_ol])
        qui ivreg2 compret_T`t'_plus_nol compret_T`t'_minus_nol if yofd(dofm(mth_dt))>1985, kernel(tru) bw(12) r
        post handle (`decile') (`t') ("HH") ("NOL") ("Post-1986") (_b[compret_T`t'_minus_nol]) (_se[compret_T`t'_minus_nol])
        qui ivreg2 compret_T`t'_plus_nol compret_T`t'_minus_nol if yofd(dofm(mth_dt))>1985, kernel(bar) bw(auto) r
        post handle (`decile') (`t') ("NW") ("NOL") ("Post-1986") (_b[compret_T`t'_minus_nol]) (_se[compret_T`t'_minus_nol])
    }

    restore
}
postclose handle

* sic 17-industry portfolios
use `mthret_sic', clear

postfile handle sic year str32 adj_method str32 overlapping str32 sampling b se using "${indir}/sic17_betas.dta", replace
forvalues sic = 1/17{
    preserve
    keep if sic_17 == `sic'
    tsset mth_dt

    forvalues t = 1/10{
        * r(t,t+T) on r(t-T,t)
        * Hansen-Hodrick (1980) adjusted SE
        qui ivreg2 compret_T`t'_plus_ol compret_T`t'_minus_ol, kernel(tru) bw(12) r
        post handle (`sic') (`t') ("HH") ("OL") ("Full") (_b[compret_T`t'_minus_ol]) (_se[compret_T`t'_minus_ol])
        * Newey-West (1994) adjusted SE
        qui ivreg2 compret_T`t'_plus_ol compret_T`t'_minus_ol, kernel(bar) bw(auto) r
        post handle (`sic') (`t') ("NW") ("OL") ("Full") (_b[compret_T`t'_minus_ol]) (_se[compret_T`t'_minus_ol])
        * r(t,t+T-1) on r(t-T,t-1)
        * Hansen-Hodrick (1980) adjusted SE
        qui ivreg2 compret_T`t'_plus_nol compret_T`t'_minus_nol, kernel(tru) bw(12) r
        post handle (`sic') (`t') ("HH") ("NOL") ("Full") (_b[compret_T`t'_minus_nol]) (_se[compret_T`t'_minus_nol])
        * Newey-West (1994) adjusted SE
        qui ivreg2 compret_T`t'_plus_nol compret_T`t'_minus_nol, kernel(bar) bw(auto) r
        post handle (`sic') (`t') ("NW") ("NOL") ("Full") (_b[compret_T`t'_minus_nol]) (_se[compret_T`t'_minus_nol])

        * replication sample (before 1986)
        qui ivreg2 compret_T`t'_plus_ol compret_T`t'_minus_ol if yofd(dofm(mth_dt))<1986, kernel(tru) bw(12) r
        post handle (`sic') (`t') ("HH") ("OL") ("Pre-1986") (_b[compret_T`t'_minus_ol]) (_se[compret_T`t'_minus_ol])
        qui ivreg2 compret_T`t'_plus_ol compret_T`t'_minus_ol if yofd(dofm(mth_dt))<1986, kernel(bar) bw(auto) r
        post handle (`sic') (`t') ("NW") ("OL") ("Pre-1986") (_b[compret_T`t'_minus_ol]) (_se[compret_T`t'_minus_ol])
        qui ivreg2 compret_T`t'_plus_nol compret_T`t'_minus_nol if yofd(dofm(mth_dt))<1986, kernel(tru) bw(12) r
        post handle (`sic') (`t') ("HH") ("NOL") ("Pre-1986") (_b[compret_T`t'_minus_nol]) (_se[compret_T`t'_minus_nol])
        qui ivreg2 compret_T`t'_plus_nol compret_T`t'_minus_nol if yofd(dofm(mth_dt))<1986, kernel(bar) bw(auto) r
        post handle (`sic') (`t') ("NW") ("NOL") ("Pre-1986") (_b[compret_T`t'_minus_nol]) (_se[compret_T`t'_minus_nol])

        * new sample (since 1986)
        qui ivreg2 compret_T`t'_plus_ol compret_T`t'_minus_ol if yofd(dofm(mth_dt))>1985, kernel(tru) bw(12) r
        post handle (`sic') (`t') ("HH") ("OL") ("Post-1986") (_b[compret_T`t'_minus_ol]) (_se[compret_T`t'_minus_ol])
        qui ivreg2 compret_T`t'_plus_ol compret_T`t'_minus_ol if yofd(dofm(mth_dt))>1985, kernel(bar) bw(auto) r
        post handle (`sic') (`t') ("NW") ("OL") ("Post-1986") (_b[compret_T`t'_minus_ol]) (_se[compret_T`t'_minus_ol])
        qui ivreg2 compret_T`t'_plus_nol compret_T`t'_minus_nol if yofd(dofm(mth_dt))>1985, kernel(tru) bw(12) r
        post handle (`sic') (`t') ("HH") ("NOL") ("Post-1986") (_b[compret_T`t'_minus_nol]) (_se[compret_T`t'_minus_nol])
        qui ivreg2 compret_T`t'_plus_nol compret_T`t'_minus_nol if yofd(dofm(mth_dt))>1985, kernel(bar) bw(auto) r
        post handle (`sic') (`t') ("NW") ("NOL") ("Post-1986") (_b[compret_T`t'_minus_nol]) (_se[compret_T`t'_minus_nol])
    }
    
    restore
}
postclose handle

* market portfolios: equal-weighted versus value-weighted
postfile handle str32 weight year str32 adj_method str32 overlapping str32 sampling b se using "${indir}/mkt_betas.dta", replace
use `mthret_mkt', clear
tsset mth_dt
forvalues t = 1/10{
    * r(t,t+T) on r(t-T,t)
    * Hansen-Hodrick (1980) adjusted SE
    qui ivreg2 compret_T`t'_plus_ol compret_T`t'_minus_ol, kernel(tru) bw(12) r
    post handle ("Equal-weighted") (`t') ("HH") ("OL") ("Full") (_b[compret_T`t'_minus_ol]) (_se[compret_T`t'_minus_ol])
    * Newey-West (1994) adjusted SE
    qui ivreg2 compret_T`t'_plus_ol compret_T`t'_minus_ol, kernel(bar) bw(auto) r
    post handle ("Equal-weighted") (`t') ("NW") ("OL") ("Full") (_b[compret_T`t'_minus_ol]) (_se[compret_T`t'_minus_ol])
    * r(t,t+T-1) on r(t-T,t-1)
    * Hansen-Hodrick (1980) adjusted SE
    qui ivreg2 compret_T`t'_plus_nol compret_T`t'_minus_nol, kernel(tru) bw(12) r
    post handle ("Equal-weighted") (`t') ("HH") ("NOL") ("Full") (_b[compret_T`t'_minus_nol]) (_se[compret_T`t'_minus_nol])
    * Newey-West (1994) adjusted SE
    qui ivreg2 compret_T`t'_plus_nol compret_T`t'_minus_nol, kernel(bar) bw(auto) r
    post handle ("Equal-weighted") (`t') ("NW") ("NOL") ("Full") (_b[compret_T`t'_minus_nol]) (_se[compret_T`t'_minus_nol])

    * replication sample
    qui ivreg2 compret_T`t'_plus_ol compret_T`t'_minus_ol if yofd(dofm(mth_dt))<1986, kernel(tru) bw(12) r
    post handle ("Equal-weighted") (`t') ("HH") ("OL") ("Pre-1986") (_b[compret_T`t'_minus_ol]) (_se[compret_T`t'_minus_ol])
    qui ivreg2 compret_T`t'_plus_ol compret_T`t'_minus_ol if yofd(dofm(mth_dt))<1986, kernel(bar) bw(auto) r
    post handle ("Equal-weighted") (`t') ("NW") ("OL") ("Pre-1986") (_b[compret_T`t'_minus_ol]) (_se[compret_T`t'_minus_ol])
    qui ivreg2 compret_T`t'_plus_nol compret_T`t'_minus_nol if yofd(dofm(mth_dt))<1986, kernel(tru) bw(12) r
    post handle ("Equal-weighted") (`t') ("HH") ("NOL") ("Pre-1986") (_b[compret_T`t'_minus_nol]) (_se[compret_T`t'_minus_nol])
    qui ivreg2 compret_T`t'_plus_nol compret_T`t'_minus_nol if yofd(dofm(mth_dt))<1986, kernel(bar) bw(auto) r
    post handle ("Equal-weighted") (`t') ("NW") ("NOL") ("Pre-1986") (_b[compret_T`t'_minus_nol]) (_se[compret_T`t'_minus_nol])

    * new sample
    qui ivreg2 compret_T`t'_plus_ol compret_T`t'_minus_ol if yofd(dofm(mth_dt))>1985, kernel(tru) bw(12) r
    post handle ("Equal-weighted") (`t') ("HH") ("OL") ("Post-1986") (_b[compret_T`t'_minus_ol]) (_se[compret_T`t'_minus_ol])
    qui ivreg2 compret_T`t'_plus_ol compret_T`t'_minus_ol if yofd(dofm(mth_dt))>1985, kernel(bar) bw(auto) r
    post handle ("Equal-weighted") (`t') ("NW") ("OL") ("Post-1986") (_b[compret_T`t'_minus_ol]) (_se[compret_T`t'_minus_ol])
    qui ivreg2 compret_T`t'_plus_nol compret_T`t'_minus_nol if yofd(dofm(mth_dt))>1985, kernel(tru) bw(12) r
    post handle ("Equal-weighted") (`t') ("HH") ("NOL") ("Post-1986") (_b[compret_T`t'_minus_nol]) (_se[compret_T`t'_minus_nol])
    qui ivreg2 compret_T`t'_plus_nol compret_T`t'_minus_nol if yofd(dofm(mth_dt))>1985, kernel(bar) bw(auto) r
    post handle ("Equal-weighted") (`t') ("NW") ("NOL") ("Post-1986") (_b[compret_T`t'_minus_nol]) (_se[compret_T`t'_minus_nol])
}

use `mthret_mkt_w', clear
tsset mth_dt
forvalues t = 1/10{
    * r(t,t+T) on r(t-T,t)
    * Hansen-Hodrick (1980) adjusted SE
    qui ivreg2 compret_T`t'_plus_ol compret_T`t'_minus_ol, kernel(tru) bw(12) r
    post handle ("Value-weighted") (`t') ("HH") ("OL") ("Full") (_b[compret_T`t'_minus_ol]) (_se[compret_T`t'_minus_ol])
    * Newey-West (1994) adjusted SE
    qui ivreg2 compret_T`t'_plus_ol compret_T`t'_minus_ol, kernel(bar) bw(auto) r
    post handle ("Value-weighted") (`t') ("NW") ("OL") ("Full") (_b[compret_T`t'_minus_ol]) (_se[compret_T`t'_minus_ol])
    
    * r(t,t+T-1) on r(t-T,t-1)
    * Hansen-Hodrick (1980) adjusted SE
    qui ivreg2 compret_T`t'_plus_nol compret_T`t'_minus_nol, kernel(tru) bw(12) r
    post handle ("Value-weighted") (`t') ("HH") ("NOL") ("Full") (_b[compret_T`t'_minus_nol]) (_se[compret_T`t'_minus_nol])
    * Newey-West (1994) adjusted SE
    qui ivreg2 compret_T`t'_plus_nol compret_T`t'_minus_nol, kernel(bar) bw(auto) r
    post handle ("Value-weighted") (`t') ("NW") ("NOL") ("Full") (_b["compret_T`t'_minus_nol"]) (_se[compret_T`t'_minus_nol])

    * replication sample
    qui ivreg2 compret_T`t'_plus_ol compret_T`t'_minus_ol if yofd(dofm(mth_dt))<1986, kernel(tru) bw(12) r
    post handle ("Value-weighted") (`t') ("HH") ("OL") ("Pre-1986") (_b[compret_T`t'_minus_ol]) (_se[compret_T`t'_minus_ol])
    qui ivreg2 compret_T`t'_plus_ol compret_T`t'_minus_ol if yofd(dofm(mth_dt))<1986, kernel(bar) bw(auto) r
    post handle ("Value-weighted") (`t') ("NW") ("OL") ("Pre-1986") (_b[compret_T`t'_minus_ol]) (_se[compret_T`t'_minus_ol])
    qui ivreg2 compret_T`t'_plus_nol compret_T`t'_minus_nol if yofd(dofm(mth_dt))<1986, kernel(tru) bw(12) r
    post handle ("Value-weighted") (`t') ("HH") ("NOL") ("Pre-1986") (_b[compret_T`t'_minus_nol]) (_se[compret_T`t'_minus_nol])
    qui ivreg2 compret_T`t'_plus_nol compret_T`t'_minus_nol if yofd(dofm(mth_dt))<1986, kernel(bar) bw(auto) r
    post handle ("Value-weighted") (`t') ("NW") ("NOL") ("Pre-1986") (_b[compret_T`t'_minus_nol]) (_se[compret_T`t'_minus_nol])

    * new sample
    qui ivreg2 compret_T`t'_plus_ol compret_T`t'_minus_ol if yofd(dofm(mth_dt))>1985, kernel(tru) bw(12) r
    post handle ("Value-weighted") (`t') ("HH") ("OL") ("Post-1986") (_b[compret_T`t'_minus_ol]) (_se[compret_T`t'_minus_ol])
    qui ivreg2 compret_T`t'_plus_ol compret_T`t'_minus_ol if yofd(dofm(mth_dt))>1985, kernel(bar) bw(auto) r
    post handle ("Value-weighted") (`t') ("NW") ("OL") ("Post-1986") (_b[compret_T`t'_minus_ol]) (_se[compret_T`t'_minus_ol])
    qui ivreg2 compret_T`t'_plus_nol compret_T`t'_minus_nol if yofd(dofm(mth_dt))>1985, kernel(tru) bw(12) r
    post handle ("Value-weighted") (`t') ("HH") ("NOL") ("Post-1986") (_b[compret_T`t'_minus_nol]) (_se[compret_T`t'_minus_nol])
    qui ivreg2 compret_T`t'_plus_nol compret_T`t'_minus_nol if yofd(dofm(mth_dt))>1985, kernel(bar) bw(auto) r
    post handle ("Value-weighted") (`t') ("NW") ("NOL") ("Post-1986") (_b[compret_T`t'_minus_nol]) (_se[compret_T`t'_minus_nol])
}

postclose handle
clear

* ======================================
* plot the betas
* ======================================
* reference: https://medium.com/the-stata-guide/stata-graphs-define-your-own-color-schemes-4320b16f7ef7

* Size deciles:
use "${indir}/size10_betas.dta", clear
append using "${indir}/mkt_betas.dta"
gen marker = "Size Decile: " + string(size_decile) if !mi(size_decile)
replace marker = "Market" if weight == "Equal-weighted"
replace marker = "Market (weighted)" if weight == "Value-weighted"
* only mark significant coefficients
gen coef = b if abs(b)>=1.96*se

forvalues decile = 1/10{
    colorpalette black, opacity(10(10)100) n(10) nograph
    local HHlines_full_ol `HHlines_full_ol' (line b year if size_decile==`decile' & sampling=="Full" & adj_method=="HH" & overlapping=="OL", lc("`r(p`decile')'") lp(solid) lw(*0.8)) || (scatter coef year if size_decile==`decile' & sampling=="Full" & adj_method=="HH" & overlapping=="OL", mc("`r(p`decile')'") m(D) msize(small)) ||
    local NWlines_full_ol `NWlines_full_ol' (line b year if size_decile==`decile' & sampling=="Full" & adj_method=="NW" & overlapping=="OL", lc("`r(p`decile')'") lp(solid) lw(*0.8)) || (scatter coef year if size_decile==`decile' & sampling=="Full" & adj_method=="NW" & overlapping=="OL", mc("`r(p`decile')'") m(D) msize(small)) ||
    colorpalette dkgreen, opacity(10(10)100) n(10) nograph
    local HHlines_rep_ol `HHlines_rep_ol' (line b year if size_decile==`decile' & sampling=="Pre-1986" & adj_method=="HH" & overlapping=="OL", lc("`r(p`decile')'") lp(solid) lw(*0.8)) || (scatter coef year if size_decile==`decile' & sampling=="Pre-1986" & adj_method=="HH" & overlapping=="OL", mc("`r(p`decile')'") m(D) msize(small)) ||
    local NWlines_rep_ol `NWlines_rep_ol' (line b year if size_decile==`decile' & sampling=="Pre-1986" & adj_method=="NW" & overlapping=="OL", lc("`r(p`decile')'") lp(solid) lw(*0.8)) || (scatter coef year if size_decile==`decile' & sampling=="Pre-1986" & adj_method=="NW" & overlapping=="OL", mc("`r(p`decile')'") m(D) msize(small)) ||
    colorpalette navy, opacity(10(10)100) n(10) nograph
    local HHlines_new_ol `HHlines_new_ol' (line b year if size_decile==`decile' & sampling=="Post-1986" & adj_method=="HH" & overlapping=="OL", lc("`r(p`decile')'") lp(solid) lw(*0.8)) || (scatter coef year if size_decile==`decile' & sampling=="Post-1986" & adj_method=="HH" & overlapping=="OL", mc("`r(p`decile')'") m(D) msize(small)) ||
    local NWlines_new_ol `NWlines_new_ol' (line b year if size_decile==`decile' & sampling=="Post-1986" & adj_method=="NW" & overlapping=="OL", lc("`r(p`decile')'") lp(solid) lw(*0.8)) || (scatter coef year if size_decile==`decile' & sampling=="Post-1986" & adj_method=="NW" & overlapping=="OL", mc("`r(p`decile')'") m(D) msize(small)) ||
}

* Full period, HH-adjusted standard errors, overlapping
twoway `HHlines_full_ol' (scatter b year if year==10 & mi(weight) & sampling=="Full" & adj_method=="HH" & overlapping=="OL", m(none) mlabel(marker) mlabsize(*0.6) mlabcolor(black)) || ///
(line b year if weight=="Equal-weighted" & sampling=="Full" & adj_method=="HH" & overlapping=="OL", lc(red) lp(solid)) || ///
(scatter coef year if weight=="Equal-weighted" & sampling=="Full" & adj_method=="HH" & overlapping=="OL", mc(red) m(O) msize(small)) || ///
(line b year if weight=="Value-weighted" & sampling=="Full" & adj_method=="HH" & overlapping=="OL", lc(red) lp(dash)) || ///
(scatter coef year if weight=="Value-weighted" & sampling=="Full" & adj_method=="HH" & overlapping=="OL", mc(red) m(O) msize(small)), ///
legend(order(22 "Equal-weighted Market Portfolio" 24 "Value-weighted Market Portfolio") size(small)) ///
xlabel(1(1)10,labsize(small)) xscale(r(1/11)) xtitle("year", size(medsmall)) ///
ytitle("OLS Slopes (significant ones marked)", size(medsmall)) ///
title("OLS Slopes for the Size-Decile Portfolios, 1926-2020",size(medium)) ///
note("The OLS estimation standard errors are adjusted using Hensen-Hodrick (1980) method.") saving("${outdir}/size_full_hh.gph", replace)

* Full period, NW-adjusted standard errors, overlapping
twoway `NWlines_full_ol' (scatter b year if year==10 & mi(weight) & sampling=="Full" & adj_method=="NW" & overlapping=="OL", m(none) mlabel(marker) mlabsize(*0.6) mlabcolor(black)) || ///
(line b year if weight=="Equal-weighted" & sampling=="Full" & adj_method=="NW" & overlapping=="OL", lc(red) lp(solid)) || ///
(scatter coef year if weight=="Equal-weighted" & sampling=="Full" & adj_method=="NW" & overlapping=="OL", mc(red) m(O) msize(small)) || ///
(line b year if weight=="Value-weighted" & sampling=="Full" & adj_method=="NW" & overlapping=="OL", lc(red) lp(dash)) || ///
(scatter coef year if weight=="Value-weighted" & sampling=="Full" & adj_method=="NW" & overlapping=="OL", mc(red) m(O) msize(small)), ///
legend(order(22 "Equal-weighted Market Portfolio" 24 "Value-weighted Market Portfolio") size(small)) ///
xlabel(1(1)10,labsize(small)) xscale(r(1/11)) xtitle("year", size(medsmall)) ///
ytitle("OLS Slopes (significant ones marked)", size(medsmall)) ///
title("OLS Slopes for the Size-Decile Portfolios, 1926-2020",size(medium)) ///
note("The OLS estimation standard errors are adjusted using Newey-West (1994) method.") saving("${outdir}/size_full_nw.gph", replace)

* Pre-1986, HH-adjusted standard errors, overlapping
twoway `HHlines_rep_ol' (scatter b year if year==10 & mi(weight) & sampling=="Pre-1986" & adj_method=="HH" & overlapping=="OL", m(none) mlabel(marker) mlabsize(*0.6) mlabcolor(dkgreen)) || ///
(line b year if weight=="Equal-weighted" & sampling=="Pre-1986" & adj_method=="HH" & overlapping=="OL", lc(red) lp(solid)) || ///
(scatter coef year if weight=="Equal-weighted" & sampling=="Pre-1986" & adj_method=="HH" & overlapping=="OL", mc(red) m(O) msize(small)) || ///
(line b year if weight=="Value-weighted" & sampling=="Pre-1986" & adj_method=="HH" & overlapping=="OL", lc(red) lp(dash)) || ///
(scatter coef year if weight=="Value-weighted" & sampling=="Pre-1986" & adj_method=="HH" & overlapping=="OL", mc(red) m(O) msize(small)), ///
legend(order(22 "Equal-weighted Market Portfolio" 24 "Value-weighted Market Portfolio") size(small)) ///
xlabel(1(1)10,labsize(small)) xscale(r(1/11)) xtitle("year", size(medsmall)) ///
ytitle("OLS Slopes (significant ones marked)", size(medsmall)) ///
title("OLS Slopes for the Size-Decile Portfolios, 1926-1986",size(medium)) ///
note("The OLS estimation standard errors are adjusted using Hensen-Hodrick (1980) method.") saving("${outdir}/size_pre1986_hh.gph", replace)

* Post-1986, HH-adjusted standard errors, overlapping
twoway `HHlines_new_ol' (scatter b year if year==10 & mi(weight) & sampling=="Post-1986" & adj_method=="HH" & overlapping=="OL", m(none) mlabel(marker) mlabsize(*0.6) mlabcolor(black)) || ///
(line b year if weight=="Equal-weighted" & sampling=="Post-1986" & adj_method=="HH" & overlapping=="OL", lc(red) lp(solid)) || ///
(scatter coef year if weight=="Equal-weighted" & sampling=="Post-1986" & adj_method=="HH" & overlapping=="OL", mc(red) m(O) msize(small)) || ///
(line b year if weight=="Value-weighted" & sampling=="Post-1986" & adj_method=="HH" & overlapping=="OL", lc(red) lp(dash)) || ///
(scatter coef year if weight=="Value-weighted" & sampling=="Post-1986" & adj_method=="HH" & overlapping=="OL", mc(red) m(O) msize(small)), ///
legend(order(22 "Equal-weighted Market Portfolio" 24 "Value-weighted Market Portfolio") size(small)) ///
xlabel(1(1)10,labsize(small)) xscale(r(1/11)) xtitle("year", size(medsmall)) ///
ytitle("OLS Slopes (significant ones marked)", size(medsmall)) ///
title("OLS Slopes for the Size-Decile Portfolios, 1986-2020",size(medium)) ///
note("The OLS estimation standard errors are adjusted using Hensen-Hodrick (1980) method.") saving("${outdir}/size_post1986_hh.gph", replace)

clear

* combine figures together
cd "${outdir}"
gr combine size_full_hh.gph size_full_nw.gph, rows(1) cols(2) imargin(medlarge) xsize(12) ysize(4.5) saving("${outdir}/size_full.gph", replace)
gr combine size_pre1986_hh.gph size_post1986_hh.gph, rows(1) cols(2) imargin(medlarge) xsize(12) ysize(4.5) saving("${outdir}/pre_vs_post.gph", replace)

* erase all the intermediary files
cap erase "${indir}/size10_betas.dta"
cap erase "${indir}/sic17_betas.dta"
cap erase "${indir}/mkt_betas.dta"
cap erase "${outdir}/size_full_hh.gph"
cap erase "${outdir}/size_full_nw.gph"
cap erase "${outdir}/size_pre1986_hh.gph"
cap erase "${outdir}/size_post1986_hh.gph"