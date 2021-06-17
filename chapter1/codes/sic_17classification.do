* Author: Sai Zhang (saizhang.econ@gmail.com)
* This program is used to generate the 17-industry classification of 4-digit SIC codes
* The SIC codes are downloaded from Kenneth French's website (https://mba.tuck.dartmouth.edu/pages/faculty/ken.french/Data_Library/det_17_ind_port.html)
* Please change the name of the variable SICCD to accomodate the data

cap program drop sic_17class
program sic_17class

    local sicvar = "SICCD"
    * generate a 17-industry classification variable
    gen sic_17 = .

    * Food
    replace sic_17 = 1 if inrange($sicvar,100,299)|inrange($sicvar,700,799)|inrange($sicvar,900,999)
    replace sic_17 = 1 if inrange($sicvar,2000,2048)|inrange($sicvar,2050,2068)|inrange($sicvar,2070,2080)
    replace sic_17 = 1 if inrange($sicvar,2082,2087)|inrange($sicvar,2090,2092)|inrange($sicvar,2095,2099)
    replace sic_17 = 1 if inrange($sicvar,5140,5159)|inrange($sicvar,5180,5182)|$sicvar==5191

    * Mines
    replace sic_17 = 2 if inrange($sicvar,1000,1049)|inrange($sicvar,1060,1069)|inrange($sicvar,1080,1099)
    replace sic_17 = 2 if inrange($sicvar,1200,1299)|inrange($sicvar,1400,1499)|inrange($sicvar,5050,5052)

    * Oil
    replace sic_17 = 3 if $sicvar==1300|inrange($sicvar,1310,1329)|inrange($sicvar,1380,1382)
    replace sic_17 = 3 if $sicvar==1389|inrange($sicvar,2900,2912)|inrange($sicvar,5170,5172)

end