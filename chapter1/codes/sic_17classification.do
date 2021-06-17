* Author: Sai Zhang (saizhang.econ@gmail.com)
* This program is used to generate the 17-industry classification of 4-digit SIC codes
* The SIC codes are downloaded from Kenneth French's website (https://mba.tuck.dartmouth.edu/pages/faculty/ken.french/Data_Library/det_17_ind_port.html)

cap program drop sic_17class
program sic_17class

    local sicvar = "SICCD"
    * generate a 17-industry classification variable
    gen sic_17 = .

    * Food industry
    replace sic_17 = 1 if inrange($sicvar,100,299)|inrange($sicvar,700,799)|inrange($sicvar,900,999)
    replace sic_17 = 1 if inrange($sicvar,2000,2048)|inrange($sicvar,2050,2068)|inrange($sicvar,2070,2080)
    replace sic_17 = 1 if inrange($sicvar,2082,2087)|inrange($sicvar,2090,2092)|inrange($sicvar,2095,2099)
    replace sic_17 = 1 if inrange($sicvar,5140,5159)|inrange($sicvar,5180,5182)|$sicvar==5191

end