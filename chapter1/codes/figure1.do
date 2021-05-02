* Author: Sai Zhang (saizhang.econ@gmail.com)
* This file is used to produce figure {} in Chapter 1 (see page {}).

* The CRSP market index excess return data are downloaded from French Kenneth's webiste.
* links are here: https://mba.tuck.dartmouth.edu/pages/faculty/ken.french/Data_Library/f-f_factors.html

global rootdir = "~/LIT/empirical-finance-literature"
global chap1dir = "${rootdir}/chapter1"
global outdir = "${chap1dir}/output"
global indir = "${chap1dir}/data"

use `"${indir}/daily_return.dta"', replace

* some basic cleaning
gen yr = substr(date,1,4)
gen mth = substr(date,5,2)
gen day = substr(date,7,2)
destring yr mth day, replace
gen dt = mdy(mth, day, yr)
keep mkt_er dt