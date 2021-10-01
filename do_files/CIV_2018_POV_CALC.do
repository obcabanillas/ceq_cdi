******************************
*CIV 2018 poverty tabulations*
******************************
clear
set more off
*Set main path
if "`c(username)'"=="wb535806"	{
	global root "C:/Users/wb535806/OneDrive - WBG/RGO/CIV/PA/RGO_CIV/Input"
}
else {
	global root "C:/Users/`c(username)'/WBG/Rogelio Granguillhome Ochoa - /CIV/PA/RGO_CIV/Input"	

}

*Import final welfare aggregate
use "$root/ehcvm_welfare_CIV2018.dta",clear

*Create zone variable
gen zone=milieu+1
replace zone=1 if zae==6
label define zone 1 Abidjan 2 "Autres villes" 3 Rural
label value zone zone

*Create indicators for poverty estimates
gen dif=zref-pcexp
gen p0=100*(dif>0)
gen p1=(dif/zref)*p0
gen p2=((dif/zref)^2)*p0

*Tabulations
tabstat p0 p1 p2 pcexp zref dtet [aw=hhweight*hhsize], by(milieu)

/* Numbers match table 5 from trends file

Summary statistics: mean
  by categories of: milieu (Milieu residence)

milieu |        p0        p1        p2     pcexp      zref      dtet
-------+------------------------------------------------------------
Urbain |  24.67215  6.612643  2.530061  637793.5  345520.3  661109.4
 Rural |  54.65791  16.72328  6.937994  384155.1  345520.3  355741.1
-------+------------------------------------------------------------
 Total |    39.448  11.59478  4.702124  512810.1  345520.3  510635.4
--------------------------------------------------------------------

*/

tabstat p0 p1 p2 pcexp [aw=hhweight*hhsize], by(zone)

/* Data matches table 5 from trends file

Summary statistics: mean
  by categories of: zone 

         zone |        p0        p1        p2     pcexp
--------------+----------------------------------------
      Abidjan |  10.17705   2.15976  .7108769    808383
Autres villes |  34.66449   9.68228  3.784132    520196
        Rural |  54.65791  16.72328  6.937994  384155.1
--------------+----------------------------------------
        Total |    39.448  11.59478  4.702124  512810.1
-------------------------------------------------------

*/




