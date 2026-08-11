// ============================================================================
// FOREST PLOT — FRONTERAS ENTRE QUINQUENIOS CONSECUTIVOS
// Confianza institucional y cohortes generacionales en Chile
// Bustamante & Quintero — Congreso Triada 2026
//
// Do-file chico y AUTOCONTENIDO. Sí estima 5 modelos nuevos (meologit con
// cohort5 completo, uno por institución — la misma especificación de la
// Sección 2c del dofile principal), pero sin ningún grid de márgenes ni
// marginsplot — nada parecido a la Sección 4. Debería tardar unos minutos
// en total, no horas.
//
// Es una copia de la Sección 0 (config) + Sección 1 (prep de datos) +
// Sección 8 del dofile final. Si ese archivo cambia, actualizar acá
// también.
// ============================================================================

global DATA      "C:\Users\gonza\Dropbox\Proyectos personales\02.- DATOS\Bicentenario\bicentenario_panel_armonizado.dta"
global PRINCIPAL "C:\Users\gonza\Dropbox\Proyectos personales\01.- Desarrollo investigación\Quintero, Bustamante\Análisis final\Principal"


// ----------------------------------------------------------------------------
// Preparación de datos (necesita cohort5 completo)
// ----------------------------------------------------------------------------

use "$DATA", clear

gen int birthyear = year - edad
keep if birthyear >= 1930 & birthyear <= 2007
keep if edad >= 18 & edad <= 85

gen age_s  = edad / 10
gen age_s2 = age_s^2
gen mujer  = (sexo == 2) if !missing(sexo)

gen cohort5 = 5 * floor(birthyear / 5)
recode cohort5 (min/1944 = 1944)
label define cohort5lbl 1944 "≤1944" 1945 "1945-49" 1950 "1950-54" 1955 "1955-59" ///
    1960 "1960-64" 1965 "1965-69" 1970 "1970-74" 1975 "1975-79" ///
    1980 "1980-84" 1985 "1985-89" 1990 "1990-94" 1995 "1995-99" ///
    2000 "2000-04" 2005 "2005-07"
label values cohort5 cohort5lbl

foreach v in conf_gobierno conf_parlamento conf_partidos conf_ffaa conf_iglesia {
    replace `v' = . if inlist(`v', 6, 7)
}

local institutions "conf_gobierno conf_parlamento conf_partidos conf_ffaa conf_iglesia"
local labels        `""Gobierno" "Parlamento" "Partidos" "FF.AA." "Iglesia""'


// ============================================================================
// >>> SECCIÓN 8: FOREST PLOT — FRONTERAS ENTRE QUINQUENIOS CONSECUTIVOS
// ============================================================================
// Testea las 13 fronteras entre quinquenios consecutivos (¿≤1944 vs
// 1945-49?, ¿1945-49 vs 1950-54?, ..., ¿2000-04 vs 2005-07?) para cada
// institución, modelo ordinal (la especificación principal) — resolución
// completa quinquenio a quinquenio, no solo las 4 fronteras entre los
// bloques teóricos grandes.

tempname fh_front_q
file open `fh_front_q' using "$PRINCIPAL\5_fronteras_quinquenales.csv", write replace
file write `fh_front_q' "institucion,frontera,chi2,df,p" _n

local cohortvals   "1944 1945 1950 1955 1960 1965 1970 1975 1980 1985 1990 1995 2000 2005"
local frontlabels  `""≤1944 / 1945-49" "1945-49 / 1950-54" "1950-54 / 1955-59" "1955-59 / 1960-64" "1960-64 / 1965-69" "1965-69 / 1970-74" "1970-74 / 1975-79" "1975-79 / 1980-84" "1980-84 / 1985-89" "1985-89 / 1990-94" "1990-94 / 1995-99" "1995-99 / 2000-04" "2000-04 / 2005-07""'

local i = 1
foreach v of local institutions {
    local lbl : word `i' of `labels'
    quietly meologit `v' age_s age_s2 i.cohort5 mujer i.educ4 [pweight=ponderador] || year:, or vce(robust)

    forvalues b = 1/13 {
        local lo    : word `b' of `cohortvals'
        local hiidx = `b' + 1
        local hi    : word `hiidx' of `cohortvals'
        local flbl  : word `b' of `frontlabels'
        if `b' == 1 {
            quietly test `hi'.cohort5 = 0
        }
        else {
            quietly test `hi'.cohort5 = `lo'.cohort5
        }
        file write `fh_front_q' `""`lbl'""' "," `""`flbl'""' "," %9.3f (r(chi2)) "," %3.0f (r(df)) "," %9.4f (r(p)) _n
    }
    local ++i
}
file close `fh_front_q'

preserve
import delimited "$PRINCIPAL\5_fronteras_quinquenales.csv", clear varnames(1) case(preserve)

// No usar la columna p tal cual (redondeada a 4 decimales, colapsa a
// "0.0000" en fronteras muy significativas y -log10(0) es indefinido) —
// recalcular desde el chi2 con chi2tail().
gen neglog10p = -log10(chi2tail(df, chi2))

gen front_pos = .
replace front_pos = 1  if frontera == "≤1944 / 1945-49"
replace front_pos = 2  if frontera == "1945-49 / 1950-54"
replace front_pos = 3  if frontera == "1950-54 / 1955-59"
replace front_pos = 4  if frontera == "1955-59 / 1960-64"
replace front_pos = 5  if frontera == "1960-64 / 1965-69"
replace front_pos = 6  if frontera == "1965-69 / 1970-74"
replace front_pos = 7  if frontera == "1970-74 / 1975-79"
replace front_pos = 8  if frontera == "1975-79 / 1980-84"
replace front_pos = 9  if frontera == "1980-84 / 1985-89"
replace front_pos = 10 if frontera == "1985-89 / 1990-94"
replace front_pos = 11 if frontera == "1990-94 / 1995-99"
replace front_pos = 12 if frontera == "1995-99 / 2000-04"
replace front_pos = 13 if frontera == "2000-04 / 2005-07"

// Jitter vertical pequeño para que las 5 instituciones no se encimen en la
// misma fila.
gen front_jit = front_pos + cond(institucion=="Gobierno",-0.24, ///
    cond(institucion=="Parlamento",-0.12,cond(institucion=="Partidos",0, ///
    cond(institucion=="FF.AA.",0.12,0.24))))

twoway ///
    (scatter front_jit neglog10p if institucion=="Gobierno",   mcolor(navy)    msymbol(O)) ///
    (scatter front_jit neglog10p if institucion=="Parlamento", mcolor(maroon)  msymbol(D)) ///
    (scatter front_jit neglog10p if institucion=="Partidos",   mcolor(dkgreen) msymbol(T)) ///
    (scatter front_jit neglog10p if institucion=="FF.AA.",     mcolor(orange)  msymbol(S)) ///
    (scatter front_jit neglog10p if institucion=="Iglesia",    mcolor(purple)  msymbol(X)) ///
    , xline(1.301, lpattern(dash) lcolor(gs8)) ///
      ylabel(1 "≤1944 / 1945-49" 2 "1945-49 / 1950-54" 3 "1950-54 / 1955-59" 4 "1955-59 / 1960-64" 5 "1960-64 / 1965-69" 6 "1965-69 / 1970-74" 7 "1970-74 / 1975-79" 8 "1975-79 / 1980-84" 9 "1980-84 / 1985-89" 10 "1985-89 / 1990-94" 11 "1990-94 / 1995-99" 12 "1995-99 / 2000-04" 13 "2000-04 / 2005-07", angle(0) labsize(vsmall)) ytitle("") ///
      xtitle("-log10(p), test de Wald (especificación ordinal)") ///
      title("Gráfico de significancia de tests de Wald", size(medium)) ///
      legend(order(1 "Gobierno" 2 "Parlamento" 3 "Partidos" 4 "FF.AA." 5 "Iglesia") rows(1) position(6) size(small)) ///
      graphregion(color(white)) xsize(10) ysize(9)
graph export "$PRINCIPAL\5_forest_encrucijadas.png", replace width(2400)
restore


di as text _n "{hline 78}"
di as text "LISTO — 5_forest_encrucijadas.png (13 fronteras quinquenales) en Principal."
di as text "{hline 78}"
