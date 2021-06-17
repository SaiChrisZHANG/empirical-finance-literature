* Author: Sai Zhang (saizhang.econ@gmail.com)
* This program is used to generate the 17-industry classification of 4-digit SIC codes
* The SIC codes are downloaded from Kenneth French's website (https://mba.tuck.dartmouth.edu/pages/faculty/ken.french/Data_Library/det_17_ind_port.html)
* Please change the name of the variable SICCD to accomodate the data

cap program drop sic_17class
program sic_17class
    local sicvar = "SICCD"
    qui{
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
        replace sic_17 = 4 if inrange($sicvar,3100,3111)|inrange($sicvar,3130,3131)|inrange($sicvar,3140,3151)
        replace sic_17 = 4 if inrange($sicvar,3963,3965)|inrange($sicvar,5130,5139)

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

        * Machinery and business equipment
        replace sic_17 = 11 if inrange($sicvar,3510,3536)|inrange($sicvar,3540,3582)|inrange($sicvar,3585,3586)
        replace sic_17 = 11 if inrange($sicvar,3589,3600)|inrange($sicvar,3610,3613)|inrange($sicvar,3620,3629)
        replace sic_17 = 11 if inrange($sicvar,3670,3695)|$sicvar==3699|inrange($sicvar,3810,3812)
        replace sic_17 = 11 if inrange($sicvar,3820,3827)|inrange($sicvar,3829,3839)|inrange(3950,3955)
        replace sic_17 = 11 if $sicvar==5060|$sicvar==5063|$sicvar==5065|inrange($sicvar,5080,5081)

        * Automobiles
        replace sic_17 = 12 if inrange($sicvar,3710,3711)|$sicvar==3714|$sicvar==3716|inrange($sicvar,3750,3751)
        replace sic_17 = 12 if $sicvar==3792|inrange($sicvar,5010,5015)|inrange($sicvar,5510,5521)|inrange($sicvar,5530,5531)
        replace sic_17 = 12 if inrange($sicvar,5560,5561)|inrange($sicvar,5570,5571)|inrange($sicvar,5590,5599)

        * Transportation
        replace sic_17 = 13 if $sicvar==3713|$sicvar==3715|inrange($sicvar,3720,3721)|inrange($sicvar,3724,3725)
        replace sic_17 = 13 if $sicvar==3728|inrange($sicvar,3730,3732)|inrange($sicvar,3740,3743)|inrange($sicvar,3760,3769)
        replace sic_17 = 13 if $sicvar==3790|$sicvar==3795|$sicvar==3799|inrange($sicvar,4000,4013)|$sicvar==4100
        replace sic_17 = 13 if inrange($sicvar,4110,4121)|inrange($sicvar,4130,4131)|inrange($sicvar,4140,4142)|inrange($sicvar,4150,4151)
        replace sic_17 = 13 if inrange($sicvar,4170,4173)|inrange($sicvar,4190,4200)|inrange($sicvar,4210,4231)|inrange($sicvar,4400,4700)
        replace sic_17 = 13 if inrange($sicvar,4710,4712)|inrange($sicvar,4720,4742)|$sicvar==4780|$sicvar==4783|$sicvar==4785|$sicvar==4789

        * Utilities
        replace sic_17 = 14 if $sicvar==4900|inrange($sicvar,4910,4911)|inrange($sicvar,4920,4922)|inrange($sicvar,4923,4925)
        replace sic_17 = 14 if inrange($sicvar,4930,4932)|inrange($sicvar,4939,4942)

        * Retail stores
        replace sic_17 = 15 if inrange($sicvar,5260,5261)|inrange($sicvar,5270,5271)|$sicvar==5300|inrange($sicvar,5310,5311)|$sicvar==5320|inrange($sicvar,5330,5331)
        replace sic_17 = 15 if $sicvar==5334|inrange($sicvar,5390,5400)|inrange($sicvar,5410,5412)|inrange($sicvar,5420,5421)|inrange($sicvar,5430,5431)|inrange($sicvar,5440,5441)
        replace sic_17 = 15 if inrange($sicvar,5450,5451)|inrange($sicvar,5460,5461)|inrange($sicvar,5490,5499)|inrange($sicvar,5540,5541)|inrange($sicvar,5550,5551)|inrange($sicvar,5600,5700)
        replace sic_17 = 15 if inrange($sicvar,5710,5722)|inrange($sicvar,5730,3736)|$sicvar==5750|inrange($sicvar,5800,5813)|$sicvar==5890|$sicvar==5900|inrange($sicvar,5910,5912)|inrange($sicvar,5920,5921)
        replace sic_17 = 15 if inrange($sicvar,5930,5932)|inrange($sicvar,5940,5949)|inrange($sicvar,5960,5963)|inrange($sicvar,5980,5990)|inrange($sicvar,5992,5995)|$sicvar==5999

        * Financials
        replace sic_17 = 16 if inrange($sicvar,6010,6023)|inrange($sicvar,6025,6026)|inrange($sicvar,6028,6036)|inrange($sicvar,6040,6062)|inrange($sicvar,6080,6082)|inrange($sicvar,6090,6100)
        replace sic_17 = 16 if inrange($sicvar,6110,6112)|inrange($sicvar,6120,6129)|inrange($sicvar,6140,6163)|$sicvar==6172|inrange($sicvar,6199,6300)|inrange($sicvar,6310,6312)
        replace sic_17 = 16 if inrange($sicvar,6320,6324)|inrange($sicvar,6330,6331)|inrange($sicvar,6350,6351)|inrange($sicvar,6360,6361)|inrange($sicvar,6370,6371)|inrange($sicvar,6390,6411)
        replace sic_17 = 16 if $sicvar==6500|$sicvar==6510|inrange($sicvar,6512,6515)|inrange($sicvar,6517,6519)|inrange($sicvar,6530,6532)|inrange($sicvar,6540,6541)|inrange($sicvar,6550,6553)
        replace sic_17 = 16 if $sicvar==6611|$sicvar==6700|inrange($sicvar,6710,6726)|inrange($sicvar,6730,6733)|$sicvar==6790|$sicvar==6792|inrange($sicvar,6794,6795)|inrange($sicvar,6798,6799)

        * Other
        replace sic_17 = 17 if inrange($sicvar,2520,2549)|inrange($sicvar,2600,2659)|$sicvar==2661|inrange($sicvar,2670,2761)|inrange($sicvar,2770,2771)|inrange($sicvar,2780,2799)|inrange($sicvar,2835,2836)
        replace sic_17 = 17 if inrange($sicvar,2990,3000)|inrange($sicvar,3010,3011)|$sicvar==3041|$sicvar==3053|inrange($sicvar,3160,3161)|inrange($sicvar,3170,3172)|inrange($sicvar,3190,3221)|inrange($sicvar,3229,3231)
        replace sic_17 = 17 if $sicvar==3260|$sicvar==3263|$sicvar==3269|inrange($sicvar,3295,3299)|$sicvar==3537|inrange($sicvar,3640,3649)|inrange($sicvar,3660,3666)|$sicvar==3669|inrange($sicvar,3840,3851)
        replace sic_17 = 17 if $sicvar==3991|$sicvar==3993|inrange($sicvar,3995,3996)|inrange($sicvar,4810,4813)|inrange($sicvar,4820,4822)|inrange($sicvar,4830,4841)|inrange($sicvar,4890,4892)|$sicvar==4899|inrange($sicvar,4950,4961)
        replace sic_17 = 17 if inrange($sicvar,4970,4971)|$sicvar==4991|inrange($sicvar,5040,5049)|inrange($sicvar,5082,5088)|inrange($sicvar,5090,5093)|$sicvar==5100|inrange($sicvar,5110,5113)|$sicvar==5199|$sicvar==7000
        replace sic_17 = 17 if inrange($sicvar,7010,7011)|inrange($sicvar,7020,7021)|inrange($sicvar,7030,7033)|inrange($sicvar,7040,7041)|$sicvar==7200|inrange($sicvar,7210,7213)|inrange($sicvar,7215,7221)|inrange($sicvar,7230,7231)
        replace sic_17 = 17 if inrange($sicvar,7240,7241)|inrange($sicvar,7250,7251)|inrange($sicvar,7260,7269)|inrange($sicvar,7290,7291)|inrange($sicvar,7299,7300)|inrange($sicvar,7310,7323)|inrange($sicvar,7330,7338)
        replace sic_17 = 17 if inrange($sicvar,7340,7342)|inrange($sicvar,7349,7353)|inrange($sicvar,7359,7385)|inrange($sicvar,7389,7395)|$sicvar==7397|$sicvar==7399|$sicvar==7500|inrange($sicvar,7510,7523)|inrange($sicvar,7530,7549)
        replace sic_17 = 17 if $sicvar==7600|$sicvar==7620|inrange($sicvar,7622,7623)|inrange($sicvar,7629,7631)|inrange($sicvar,7640,7641)|inrange($sicvar,7690,7699)|inrange($sicvar,7800,7833)|inrange($sicvar,7840,7841)
        replace sic_17 = 17 if $sicvar==7900|inrange($sicvar,7910,7911)|inrange($sicvar,7920,7933)|inrange($sicvar,7940,7949)|$sicvar==7980|inrange($sicvar,7990,8499)|inrange($sicvar,8600,8700)|inrange($sicvar,8710,8713)
        replace sic_17 = 17 if inrange($sicvar,8720,8721)|inrange($sicvar,8730,8734)|inrange($sicvar,8740,8748)|inrange($sicvar,8800,8999)

        * Unknown: can be seen as Others
        replace sic_17 = 18 if mi(sic_17)

        label define sic_17class 1 "Food" 2 "Mines" 3 "Oil" 4 "Clothes" 5 "Durables" 6 "Chemicals" 7 "Drugs, Soap, Perfumes, Tobacco" 8 "Construction" 9 "Steel" 10 "Fabricated Products" 11 "Machinery and Business Equipment" 12 "Automobiles" 13 "Tansportation" 14 "Utilities" 15 "Retail Stores" 16 "Financials" 17 "Other" 18 "Unknown"
        label values sic_17 sic_17class
    } 
end