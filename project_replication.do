cap log close _all
clear
set more off

cd "~/Documents/ECO 726_Policy/Data"
log using "project.log" ,name(AD) replace 

use "/Users/alina/Documents/ECO 726_Policy/Data/cwhsc_new_cleaned.dta", clear


gen numtype=.
replace numtype=1 if type=="TAXAB" // column 1, FICA earnings
replace numtype=2 if type=="ADJ" // column 2, Adjusted FICA earnings
replace numtype=3 if type=="TOTAL" // column 3, total W-2 earnings

*collapsing average of variables
collapse (mean) var_cm nomearn cpi [w=smplsz], by(white byr year eligible numtype)

*reformatting elgibile and nonelgibile side by side
egen id=concat(white year numtype byr)
reshape wide nomearn var_cm, i(id) j(eligible)
drop id

*making the tags for the columns
gen tag="f" if numtype==1 // f = FICA
replace tag="a" if numtype==2 // a = Adjusted
replace tag="w" if numtype==3 // w = W=2 earnings
drop numtype

*reshaping data by tags
egen id=concat(white year byr)
reshape wide var* nomearn*, i(id) j(tag) string
drop id

*finding differences for eligible minus inelgilble, and SEs
gen cf=nomearn1f-nomearn0f // column 1
	gen sef=sqrt(var_cm1f+var_cm0f)
gen ca=nomearn1a-nomearn0a // column 2
	gen sea=sqrt(var_cm1a+var_cm0a)
gen cw=nomearn1w-nomearn0w // column 3
	gen sew=sqrt(var_cm1w+var_cm0w)
	
*organizing table
keep year byr white c* se* cpi 
expand 2 
sort byr year 

*estimating the first stage estimates and SEs
gen sippp=0.159 if byr==50
replace sippp=0.136 if byr==51
replace sippp=0.105 if byr==52

gen sippse=0.040 if byr==50
replace sippse=0.043 if byr==51
replace sippse=0.050 if byr==52

*math for wald estimator (column 5)
gen serv_c=ca/(sippp*cpi)
gen serv_se=sea/(sippp*cpi)

*building matrices to be same format as replication code
mkmat year c* se* sipp* serv* if white==1, matrix(whites1)
mkmat year c* se* sipp* serv* if white==0, matrix(nonwhites1)

mat whites=J(rowsof(whites1),7,.)
mat nonwhites=J(rowsof(nonwhites1),7,.)

local top=rowsof(whites1)
local top1=`top'-1

*more formatting for matrices and for columns of the table
mat colnames whites= "Cohort" "Year" "FICA Earnings" "Adjusted FICA Earnings" "Total W-2 Earnings" "p^e-p^n" "Service Effect in 1978 $"
mat colnames nonwhites= "Cohort" "Year" "FICA Earnings" "Adjusted FICA Earnings" "Total W-2 Earnings" "p^e-p^n" "Service Effect in 1978 $"

foreach mat in whites nonwhites {
	forval val=1(2)`top1' {
		mat `mat'[`val',2]=`mat'1[`val',"year"]
		mat `mat'[`val',3]=`mat'1[`val',"cf"]
		mat `mat'[`val',4]=`mat'1[`val',"ca"]
		mat `mat'[`val',5]=`mat'1[`val',"cw"]
		mat `mat'[`val',7]=`mat'1[`val',"serv_c"]
		}
		
	forval val=2(2)`top' {
		mat `mat'[`val',3]=`mat'1[`val',"sef"]
		mat `mat'[`val',4]=`mat'1[`val',"sea"]
		mat `mat'[`val',5]=`mat'1[`val',"sew"]
		mat `mat'[`val',7]=`mat'1[`val',"serv_se"]
		}	

		mat `mat'[1,1]=1950
		mat `mat'[9,1]=1951
		mat `mat'[17,1]=1952
		
		mat `mat'[1,6]=0.159
		mat `mat'[2,6]=0.040
		mat `mat'[9,6]=0.136
		mat `mat'[10,6]=0.043
		mat `mat'[17,6]=0.105
		mat `mat'[18,6]=0.050
		}

		mat li whites
		mat li nonwhites
		
* Angrist notes that final column 5 results are slightly different in oublished paper


log close AD
