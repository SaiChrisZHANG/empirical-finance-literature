* Author: Sai Zhang (saizhang.econ@gmail.com)
* This file is used to produce figure 1 in Chapter 1 (see page 20).

* The CRSP market index excess return data are downloaded from French Kenneth's webiste.
* links are here: https://mba.tuck.dartmouth.edu/pages/faculty/ken.french/Data_Library/f-f_factors.html

global rootdir = "~/Desktop/LIT/empirical-finance-literature"
global chap1dir = "${rootdir}/chapter1"
global outdir = "${chap1dir}/outputs"
global indir = "${chap1dir}/data"

use `"${indir}/daily_return.dta"', clear

* some basic cleaning
gen yr = substr(date,1,4)
gen mth = substr(date,5,2)
gen day = substr(date,7,2)
destring yr mth day, replace
gen dt = mdy(mth, day, yr)
keep mkt_er dt
format dt %td

* set time variable as dt
tsset dt

* open a temporary file to store results
tempfile reg_res

* rolling window regressions: 365 calendar days
qui rolling _b _se, window(365) saving(`reg_res', replace) keep(dt): regress mkt_er L.mkt_er, r

use `reg_res', clear
sort date
keep _stat_1 _stat_3 date
duplicates drop date, force
rename _stat_1 ar
rename _stat_3 se

gen high = ar + 1.96*se
gen low = ar - 1.96*se

* Only paint the AR coefficients, not the confidence interval
twoway line ar date, lc(black) lp(solid) yline(0, lc(red) lp(solid) lw(thin)) ytitle("Daily Autocorrelation", size(medsmall)) tlabel(31dec1930 31dec1940 31dec1950 31dec1960 31dec1970 31dec1980 31dec1990 31dec2000 31dec2010 31dec2020, format(%tdCCYY) labsize(small)) ylabel(,labsize(small)) legend(off) xtitle("") saving("${outdir}/fig1.gph", replace)
