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

twoway line _b_spxadj date if date>=td(1oct2003), lc(black) lp(solid) || line _b_spxadj date, lc(gs8) lp(dash) || line _b_spxadj date, lc(gs8) lp(dash) yline(0, lc(red), lp(dot)) xtitle("Daily AR of the Excess Market Return, 1926 - 2021") xtitle("Daily AR(1)")

