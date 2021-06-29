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
    * overlapping
    local T = `period'*12
    local T_1 = `period'*12 - 1
    rangestat (sum) compret_T`period'_minus_ol = `retvar', interval(`datevar',-`T',0) by(`portfolio')
    rangestat (sum) compret_T`period'_plus_ol = `retvar', interval(`datevar',0,`T') by(`portfolio')
    rangestat (obs) periods_minus = `portfolio', interval(`datevar',-`T',0) by(`portfolio')
    rangestat (obs) periods_plus = `portfolio', interval(`datevar',0,`T') by(`portfolio')
    replace compret_T`period'_minus_ol = . if periods_minus < `T'+1
    replace compret_T`period'_plus_ol = . if periods_plus < `T'+1
    drop periods_minus periods_plus
    * non-overlapping
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

* ========================================
* run the regressions and generate figures
* ========================================
* Note: following codes use 1926-2020 data, one can easily modify the codes and separately
*       run 1926-1985 sub-period for replication and 1986-2020 for new trends
* ++++++++++++++++++++++++++++++++++++++++
* size-based decile portfolios
use `mthret_size', clear

postfile handle size_decile year str32 adj_method str32 overlapping b se using "${indir}/size10_betas.dta", replace
forvalues decile = 1/10{
    preserve
    keep if size_decile == `decile'
    tsset mth_dt

    forvalues t = 1/10{
        * r(t,t+T) on r(t-T,t)
        * Hansen-Hodrick (1980) adjusted SE
        qui ivreg2 compret_T`t'_plus_ol compret_T`t'_minus_ol, kernel(tru) bw(12) r
        post handle (`decile') (`t') ("Hansen-Hodrick") ("compret_T`t'_minus_ol") (_b[compret_T`t'_minus_ol]) (_se[compret_T`t'_minus_ol])
        * Newey-West (1994) adjusted SE
        qui ivreg2 compret_T`t'_plus_ol compret_T`t'_minus_ol, kernel(bar) bw(auto) r
        post handle (`decile') (`t') ("Newey-West") ("compret_T`t'_minus_ol") (_b[compret_T`t'_minus_ol]) (_se[compret_T`t'_minus_ol])
        
        * r(t,t+T-1) on r(t-T,t-1)
        * Hansen-Hodrick (1980) adjusted SE
        qui ivreg2 compret_T`t'_plus_nol compret_T`t'_minus_nol, kernel(tru) bw(12) r
        post handle (`decile') (`t') ("Hansen-Hodrick") ("compret_T`t'_minus_nol") (_b[compret_T`t'_minus_nol]) (_se[compret_T`t'_minus_nol])
        * Newey-West (1994) adjusted SE
        qui ivreg2 compret_T`t'_plus_nol compret_T`t'_minus_nol, kernel(bar) bw(auto) r
        post handle (`decile') (`t') ("Newey-West") ("compret_T`t'_minus_nol") (_b["compret_T`t'_minus_nol"]) (_se[compret_T`t'_minus_nol])
    }

    restore
}
postclose handle

* sic 17-industry portfolios
use `mthret_sic', clear

postfile handle sic year str32 adj_method str32 overlapping b se using "${indir}/sic17_betas.dta", replace
forvalues sic = 1/17{
    preserve
    keep if sic_17 == `sic'
    tsset mth_dt

    forvalues t = 1/10{
        * r(t,t+T) on r(t-T,t)
        * Hansen-Hodrick (1980) adjusted SE
        qui ivreg2 compret_T`t'_plus_ol compret_T`t'_minus_ol, kernel(tru) bw(12) r
        post handle (`sic') (`t') ("Hansen-Hodrick") ("compret_T`t'_minus_ol") (_b[compret_T`t'_minus_ol]) (_se[compret_T`t'_minus_ol])
        * Newey-West (1994) adjusted SE
        qui ivreg2 compret_T`t'_plus_ol compret_T`t'_minus_ol, kernel(bar) bw(auto) r
        post handle (`sic') (`t') ("Newey-West") ("compret_T`t'_minus_ol") (_b[compret_T`t'_minus_ol]) (_se[compret_T`t'_minus_ol])
        
        * r(t,t+T-1) on r(t-T,t-1)
        * Hansen-Hodrick (1980) adjusted SE
        qui ivreg2 compret_T`t'_plus_nol compret_T`t'_minus_nol, kernel(tru) bw(12) r
        post handle (`sic') (`t') ("Hansen-Hodrick") ("compret_T`t'_minus_nol") (_b[compret_T`t'_minus_nol]) (_se[compret_T`t'_minus_nol])
        * Newey-West (1994) adjusted SE
        qui ivreg2 compret_T`t'_plus_nol compret_T`t'_minus_nol, kernel(bar) bw(auto) r
        post handle (`sic') (`t') ("Newey-West") ("compret_T`t'_minus_nol") (_b["compret_T`t'_minus_nol"]) (_se[compret_T`t'_minus_nol])
    }
    
    restore
}
postclose handle

* market portfolios: equal-weighted versus value-weighted
postfile handle str32 weight year str32 adj_method str32 overlapping b se using "${indir}/mkt_betas.dta", replace
use `mthret_mkt', clear
tsset mth_dt
forvalues t = 1/10{
    * r(t,t+T) on r(t-T,t)
    * Hansen-Hodrick (1980) adjusted SE
    qui ivreg2 compret_T`t'_plus_ol compret_T`t'_minus_ol, kernel(tru) bw(12) r
    post handle ("Equal-weighted") (`t') ("Hansen-Hodrick") ("compret_T`t'_minus_ol") (_b[compret_T`t'_minus_ol]) (_se[compret_T`t'_minus_ol])
    * Newey-West (1994) adjusted SE
    qui ivreg2 compret_T`t'_plus_ol compret_T`t'_minus_ol, kernel(bar) bw(auto) r
    post handle ("Equal-weighted") (`t') ("Newey-West") ("compret_T`t'_minus_ol") (_b[compret_T`t'_minus_ol]) (_se[compret_T`t'_minus_ol])
    
    * r(t,t+T-1) on r(t-T,t-1)
    * Hansen-Hodrick (1980) adjusted SE
    qui ivreg2 compret_T`t'_plus_nol compret_T`t'_minus_nol, kernel(tru) bw(12) r
    post handle ("Equal-weighted") (`t') ("Hansen-Hodrick") ("compret_T`t'_minus_nol") (_b[compret_T`t'_minus_nol]) (_se[compret_T`t'_minus_nol])
    * Newey-West (1994) adjusted SE
    qui ivreg2 compret_T`t'_plus_nol compret_T`t'_minus_nol, kernel(bar) bw(auto) r
    post handle ("Equal-weighted") (`t') ("Newey-West") ("compret_T`t'_minus_nol") (_b["compret_T`t'_minus_nol"]) (_se[compret_T`t'_minus_nol])
}

use `mthret_mkt_w', clear
tsset mth_dt
forvalues t = 1/10{
    * r(t,t+T) on r(t-T,t)
    * Hansen-Hodrick (1980) adjusted SE
    qui ivreg2 compret_T`t'_plus_ol compret_T`t'_minus_ol, kernel(tru) bw(12) r
    post handle ("Value-weighted") (`t') ("Hansen-Hodrick") ("compret_T`t'_minus_ol") (_b[compret_T`t'_minus_ol]) (_se[compret_T`t'_minus_ol])
    * Newey-West (1994) adjusted SE
    qui ivreg2 compret_T`t'_plus_ol compret_T`t'_minus_ol, kernel(bar) bw(auto) r
    post handle ("Value-weighted") (`t') ("Newey-West") ("compret_T`t'_minus_ol") (_b[compret_T`t'_minus_ol]) (_se[compret_T`t'_minus_ol])
    
    * r(t,t+T-1) on r(t-T,t-1)
    * Hansen-Hodrick (1980) adjusted SE
    qui ivreg2 compret_T`t'_plus_nol compret_T`t'_minus_nol, kernel(tru) bw(12) r
    post handle ("Value-weighted") (`t') ("Hansen-Hodrick") ("compret_T`t'_minus_nol") (_b[compret_T`t'_minus_nol]) (_se[compret_T`t'_minus_nol])
    * Newey-West (1994) adjusted SE
    qui ivreg2 compret_T`t'_plus_nol compret_T`t'_minus_nol, kernel(bar) bw(auto) r
    post handle ("Value-weighted") (`t') ("Newey-West") ("compret_T`t'_minus_nol") (_b["compret_T`t'_minus_nol"]) (_se[compret_T`t'_minus_nol])
}

postclose handle
clear

* ===============
* plot the betas
* ===============


* erase all the intermediary files
cap erase "${indir}/size10_betas.dta"
cap erase "${indir}/sic17_betas.dta"
cap erase "${indir}/mkt_betas.dta"