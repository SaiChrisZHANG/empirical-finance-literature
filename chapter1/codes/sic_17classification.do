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

    * Clothes
    replace sic_17 = 4 if inrange($sicvar,2200,2284)|inrange($sicvar,2290,2399)|inrange($sicvar,3020,3021)
    replace sic_17 = 4 if inrange($sicvar,3100,3111)|inrange($sicvar,3130,3131)|inrange($sicvar,3140,3149)
    replace sic_17 = 4 if inrange($sicvar,3150,3151)|inrange($sicvar,3963,3965)|inrange($sicvar,5130,5139)

    * Durables
    replace sic_17 = 5 if inrange($sicvar,2510,2519)|inrange($sicvar,2590,2599)|inrange($sicvar,3060,3099)
    replace sic_17 = 5 if inrange($sicvar,3630,3639)|inrange($sicvar,3650,3652)|inrange($sicvar,3860,3861)
    replace sic_17 = 5 if inrange($sicvar,3870,3873)|inrange($sicvar,3910,3911)|inrange($sicvar,3914,3915)
    replace sic_17 = 5 if inrange($sicvar,3930,3931)|inrange($sicvar,3940,3949)|inrange($sicvar,3960,3962)
    replace sic_17 = 5 if inrange($sicvar,5020,5023)|$sicvar==5064|$sicvar==5094|$sicvar==5099

    * Chemicals
    replace sic_17 = 6 if inrange($sicvar,2800,2829)|inrange($sicvar,2860,2879)|inrange($sicvar,2890,2899)|inrange($sicvar,5160,5169)

    * Consumption
    replace sic_17 = 7 if inrange($sicvar,2100,2199)|inrange($sicvar,2830,2831)|inrange($sicvar,2833,2834)
    replace sic_17 = 7 if inrange($sicvar,2840,2844)|inrange($sicvar,5120,5122)|$sicvar==5194

    * Construction and construction materials
    replace sic_17 = 8 if inrange($sicvar,800,899)|inrange($sicvar,1500,1511)|inrange($sicvar,1520,1549)
    replace sic_17 = 8 if inrange($sicvar,1600,1799)|inrange($sicvar,2400,2459)|inrange($sicvar,2490,2499)
    replace sic_17 = 8 if inrange($sicvar,2850,2859)|inrange($sicvar,2950,2952)|$sicvar==3200|inrange($sicvar,3210,3211)
    replace sic_17 = 8 if inrange($sicvar,3240,3241)|inrange($sicvar,3250,3259)|$sicvar==3261|$sicvar==3264
    replace sic_17 = 8 if inrange($sicvar,3270,3275)|inrange($sicvar,3280,3281)|inrange($sicvar,3290,3293)
    replace sic_17 = 8 if inrange($sicvar,3420,3433)|inrange($sicvar,3440,3442)|$sicvar==3446|inrange($sicvar,3448,3452)
    replace sic_17 = 8 if inrange($sicvar,5030,5039)|inrange($sicvar,5070,5078)|$sicvar==5198|inrange($sicvar,5210,5211)
    replace sic_17 = 8 if inrange($sicvar,5230,5231)|inrange($sicvar,5250,5251)

    * Steel
    replace sic_17 = 9 if $sicvar==3300|inrange($sicvar,3310,3317)|inrange($sicvar,3320,3325)|inrange($sicvar,3330,3341)
    replace sic_17 = 9 if inrange($sicvar,3350,3357)|inrange($sicvar,3360,3369)|inrange($sicvar,3390,3399)

    * Fabricated products
    replace sic_17 = 10 if inrange($sicvar,3410,3412)|inrange($sicvar,3443,3444)|inrange($sicvar,3460,3499)

end