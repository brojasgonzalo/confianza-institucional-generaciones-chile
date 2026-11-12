* config
global DATA      "C:\Users\gonza\Dropbox\Proyectos personales\02.- DATOS\Bicentenario\bicentenario_panel_armonizado.dta"
global PRINCIPAL "C:\Users\gonza\Dropbox\Proyectos personales\01.- Desarrollo investigación\Quintero, Bustamante\Análisis final\Principal"
global AUXILIAR  "C:\Users\gonza\Dropbox\Proyectos personales\01.- Desarrollo investigación\Quintero, Bustamante\Análisis final\Auxiliar"
global TEORICA   "C:\Users\gonza\Dropbox\Proyectos personales\01.- Desarrollo investigación\Quintero, Bustamante\Análisis final\Cohortes teóricas"

* prep
use "$DATA", clear

gen int birthyear = year - edad
keep if birthyear >= 1930 & birthyear <= 2007
keep if edad >= 18 & edad <= 85

svyset folio_mapa [pw=ponderador], strata(estrato) vce(linearized) singleunit(centered)

gen age_s  = edad / 10
gen age_s2 = age_s^2
gen mujer  = (sexo == 2) if !missing(sexo)

gen cohort5 = 5 * floor(birthyear / 5)
recode cohort5 (min/1944 = 1944)
label define cohort5lbl 1944 "≤1944" 1945 "1945-49" 1950 "1950-54" 1955 "1955-59" 1960 "1960-64" 1965 "1965-69" 1970 "1970-74" 1975 "1975-79" 1980 "1980-84" 1985 "1985-89" 1990 "1990-94" 1995 "1995-99" 2000 "2000-04" 2005 "2005-07"
label values cohort5 cohort5lbl

gen cohort_teorica = 1     if birthyear <= 1949
replace cohort_teorica = 2 if inrange(birthyear, 1950, 1964)
replace cohort_teorica = 3 if inrange(birthyear, 1965, 1979)
replace cohort_teorica = 4 if inrange(birthyear, 1980, 1994)
replace cohort_teorica = 5 if birthyear >= 1995

label define cohort_teoricalbl 1 "Pre-masificación educativa (<=1949)" 2 "Estado desarrollista (1950-1964)" 3 "Dictadura/transición (1965-1979)" 4 "Democracia neoliberal (1980-1994)" 5 "Generación del estallido (1995+)"
label values cohort_teorica cohort_teoricalbl

gen cohort_check = cohort5
replace cohort_check = 11001 if inrange(birthyear, 1944, 1945)
replace cohort_check = 11002 if inrange(birthyear, 1946, 1947)
replace cohort_check = 12001 if inrange(birthyear, 1979, 1980)
replace cohort_check = 12002 if inrange(birthyear, 1981, 1982)
replace cohort_check = 13001 if inrange(birthyear, 1995, 1996)
replace cohort_check = 13002 if inrange(birthyear, 1997, 1998)
* 1988: 1970 pudo votar en el plebiscito, 1971 no. 1990: 1971 cumple 18 en dictadura, 1972 en democracia
replace cohort_check = 20001 if birthyear == 1970
replace cohort_check = 20002 if birthyear == 1971
replace cohort_check = 20003 if birthyear == 1972

gen post_estallido = (birthyear >= 1995) if !missing(birthyear)
label define post_estallidolbl 0 "Pre-estallido (<1995)" 1 "Post-estallido (1995+)"
label values post_estallido post_estallidolbl

foreach v in conf_gobierno conf_parlamento conf_partidos conf_ffaa conf_iglesia {
    replace `v' = . if inlist(`v', 6, 7)

    gen `v'_bin = (`v' >= 4) if !missing(`v')
    label var `v'_bin "`v' confía (top-2-box: 4-5=1, 1-3=0)"

    bys year: egen `v'_m = mean(`v')
    bys year: egen `v'_s = sd(`v')
    gen `v'_z = (`v' - `v'_m) / `v'_s
    drop `v'_m `v'_s
    label var `v'_z "`v' (z-score por año)"
}

local institutions "conf_gobierno conf_parlamento conf_partidos conf_ffaa conf_iglesia"
local labels        `""Gobierno" "Parlamento" "Partidos" "FF.AA." "Iglesia""'
local shortnames    "gob parl part ffaa igl"

* modelos
melogit conf_gobierno_bin   age_s age_s2 i.cohort5 mujer i.educ4 i.nse4 [pweight=ponderador] || year:, or vce(robust)
estimates store gob_logit
melogit conf_parlamento_bin age_s age_s2 i.cohort5 mujer i.educ4 i.nse4 [pweight=ponderador] || year:, or vce(robust)
estimates store parl_logit
melogit conf_partidos_bin   age_s age_s2 i.cohort5 mujer i.educ4 i.nse4 [pweight=ponderador] || year:, or vce(robust)
estimates store part_logit
melogit conf_ffaa_bin       age_s age_s2 i.cohort5 mujer i.educ4 i.nse4 [pweight=ponderador] || year:, or vce(robust)
estimates store ffaa_logit
melogit conf_iglesia_bin    age_s age_s2 i.cohort5 mujer i.educ4 i.nse4 [pweight=ponderador] || year:, or vce(robust)
estimates store igl_logit

mixed conf_gobierno_z   age_s age_s2 i.cohort5 mujer i.educ4 i.nse4 [pweight=ponderador] || year:, mle vce(robust)
estimates store gob_lineal
mixed conf_parlamento_z age_s age_s2 i.cohort5 mujer i.educ4 i.nse4 [pweight=ponderador] || year:, mle vce(robust)
estimates store parl_lineal
mixed conf_partidos_z   age_s age_s2 i.cohort5 mujer i.educ4 i.nse4 [pweight=ponderador] || year:, mle vce(robust)
estimates store part_lineal
mixed conf_ffaa_z       age_s age_s2 i.cohort5 mujer i.educ4 i.nse4 [pweight=ponderador] || year:, mle vce(robust)
estimates store ffaa_lineal
mixed conf_iglesia_z    age_s age_s2 i.cohort5 mujer i.educ4 i.nse4 [pweight=ponderador] || year:, mle vce(robust)
estimates store igl_lineal

meologit conf_gobierno   age_s age_s2 i.cohort5 mujer i.educ4 i.nse4 [pweight=ponderador] || year:, or vce(robust)
estimates store gob_ord
meologit conf_parlamento age_s age_s2 i.cohort5 mujer i.educ4 i.nse4 [pweight=ponderador] || year:, or vce(robust)
estimates store parl_ord
meologit conf_partidos   age_s age_s2 i.cohort5 mujer i.educ4 i.nse4 [pweight=ponderador] || year:, or vce(robust)
estimates store part_ord
meologit conf_ffaa       age_s age_s2 i.cohort5 mujer i.educ4 i.nse4 [pweight=ponderador] || year:, or vce(robust)
estimates store ffaa_ord
meologit conf_iglesia    age_s age_s2 i.cohort5 mujer i.educ4 i.nse4 [pweight=ponderador] || year:, or vce(robust)
estimates store igl_ord

foreach m in gob_logit parl_logit part_logit ffaa_logit igl_logit gob_lineal parl_lineal part_lineal ffaa_lineal igl_lineal gob_ord parl_ord part_ord ffaa_ord igl_ord {
    estimates restore `m'
    local ll = e(ll)
    local k  = e(k)
    local N  = e(N)
    estadd scalar AIC = -2*`ll' + 2*`k'
    estadd scalar BIC = -2*`ll' + `k'*ln(`N')
    quietly estat sd
    matrix sd_tab = r(table)
    estadd scalar sigma_p = sd_tab[1,1]
}

esttab gob_logit parl_logit part_logit ffaa_logit igl_logit using "$AUXILIAR\tabla_1a_binaria.rtf", replace eform b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) mtitles("Gobierno" "Parlamento" "Partidos" "FF.AA." "Iglesia") stats(sigma_p N AIC BIC, fmt(4 0 1 1) labels("Sigma periodo" "N obs." "AIC" "BIC")) label nogaps compress nonotes nobaselevels title("Tabla APC (a) - Modelo binario logistico (OR; DV: confia top-2-box)")

esttab gob_lineal parl_lineal part_lineal ffaa_lineal igl_lineal using "$AUXILIAR\tabla_1b_continua.rtf", replace b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) mtitles("Gobierno" "Parlamento" "Partidos" "FF.AA." "Iglesia") stats(sigma_p N AIC BIC, fmt(4 0 1 1) labels("Sigma periodo" "N obs." "AIC" "BIC")) label nogaps compress nonotes nobaselevels title("Tabla APC (b) - Modelo lineal sobre z-score (DV: confianza estandarizada por ano)")

esttab gob_ord parl_ord part_ord ffaa_ord igl_ord using "$PRINCIPAL\tabla_1c_ordinal.rtf", replace eform b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) mtitles("Gobierno" "Parlamento" "Partidos" "FF.AA." "Iglesia") stats(sigma_p N AIC BIC, fmt(4 0 1 1) labels("Sigma periodo" "N obs." "AIC" "BIC")) label nogaps compress nonotes nobaselevels title("Tabla APC (c) - Modelo ordinal logistico (OR; DV: escala 1-5 completa) - ESPECIFICACION PRINCIPAL")

* teorica
melogit conf_gobierno_bin   age_s age_s2 i.cohort_teorica mujer i.educ4 i.nse4 [pweight=ponderador] || year:, or vce(robust)
estimates store gob_logit_teo
melogit conf_parlamento_bin age_s age_s2 i.cohort_teorica mujer i.educ4 i.nse4 [pweight=ponderador] || year:, or vce(robust)
estimates store parl_logit_teo
melogit conf_partidos_bin   age_s age_s2 i.cohort_teorica mujer i.educ4 i.nse4 [pweight=ponderador] || year:, or vce(robust)
estimates store part_logit_teo
melogit conf_ffaa_bin       age_s age_s2 i.cohort_teorica mujer i.educ4 i.nse4 [pweight=ponderador] || year:, or vce(robust)
estimates store ffaa_logit_teo
melogit conf_iglesia_bin    age_s age_s2 i.cohort_teorica mujer i.educ4 i.nse4 [pweight=ponderador] || year:, or vce(robust)
estimates store igl_logit_teo

mixed conf_gobierno_z   age_s age_s2 i.cohort_teorica mujer i.educ4 i.nse4 [pweight=ponderador] || year:, mle vce(robust)
estimates store gob_lineal_teo
mixed conf_parlamento_z age_s age_s2 i.cohort_teorica mujer i.educ4 i.nse4 [pweight=ponderador] || year:, mle vce(robust)
estimates store parl_lineal_teo
mixed conf_partidos_z   age_s age_s2 i.cohort_teorica mujer i.educ4 i.nse4 [pweight=ponderador] || year:, mle vce(robust)
estimates store part_lineal_teo
mixed conf_ffaa_z       age_s age_s2 i.cohort_teorica mujer i.educ4 i.nse4 [pweight=ponderador] || year:, mle vce(robust)
estimates store ffaa_lineal_teo
mixed conf_iglesia_z    age_s age_s2 i.cohort_teorica mujer i.educ4 i.nse4 [pweight=ponderador] || year:, mle vce(robust)
estimates store igl_lineal_teo

meologit conf_gobierno   age_s age_s2 i.cohort_teorica mujer i.educ4 i.nse4 [pweight=ponderador] || year:, or vce(robust)
estimates store gob_ord_teo
meologit conf_parlamento age_s age_s2 i.cohort_teorica mujer i.educ4 i.nse4 [pweight=ponderador] || year:, or vce(robust)
estimates store parl_ord_teo
meologit conf_partidos   age_s age_s2 i.cohort_teorica mujer i.educ4 i.nse4 [pweight=ponderador] || year:, or vce(robust)
estimates store part_ord_teo
meologit conf_ffaa       age_s age_s2 i.cohort_teorica mujer i.educ4 i.nse4 [pweight=ponderador] || year:, or vce(robust)
estimates store ffaa_ord_teo
meologit conf_iglesia    age_s age_s2 i.cohort_teorica mujer i.educ4 i.nse4 [pweight=ponderador] || year:, or vce(robust)
estimates store igl_ord_teo

foreach m in gob_logit_teo parl_logit_teo part_logit_teo ffaa_logit_teo igl_logit_teo gob_lineal_teo parl_lineal_teo part_lineal_teo ffaa_lineal_teo igl_lineal_teo gob_ord_teo parl_ord_teo part_ord_teo ffaa_ord_teo igl_ord_teo {
    estimates restore `m'
    local ll = e(ll)
    local k  = e(k)
    local N  = e(N)
    estadd scalar AIC = -2*`ll' + 2*`k'
    estadd scalar BIC = -2*`ll' + `k'*ln(`N')
    quietly estat sd
    matrix sd_tab = r(table)
    estadd scalar sigma_p = sd_tab[1,1]
}

esttab gob_logit_teo parl_logit_teo part_logit_teo ffaa_logit_teo igl_logit_teo using "$AUXILIAR\tabla_2a_binaria_robustez_teorica.rtf", replace eform b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) mtitles("Gobierno" "Parlamento" "Partidos" "FF.AA." "Iglesia") stats(sigma_p N AIC BIC, fmt(4 0 1 1) labels("Sigma periodo" "N obs." "AIC" "BIC")) label nogaps compress nonotes nobaselevels title("Tabla APC (2a, robustez) - Cohortes teoricas, modelo binario (OR)")

esttab gob_lineal_teo parl_lineal_teo part_lineal_teo ffaa_lineal_teo igl_lineal_teo using "$AUXILIAR\tabla_2b_continua_robustez_teorica.rtf", replace b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) mtitles("Gobierno" "Parlamento" "Partidos" "FF.AA." "Iglesia") stats(sigma_p N AIC BIC, fmt(4 0 1 1) labels("Sigma periodo" "N obs." "AIC" "BIC")) label nogaps compress nonotes nobaselevels title("Tabla APC (2b, robustez) - Cohortes teoricas, modelo lineal sobre z-score")

esttab gob_ord_teo parl_ord_teo part_ord_teo ffaa_ord_teo igl_ord_teo using "$AUXILIAR\tabla_2c_ordinal_robustez_teorica.rtf", replace eform b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) mtitles("Gobierno" "Parlamento" "Partidos" "FF.AA." "Iglesia") stats(sigma_p N AIC BIC, fmt(4 0 1 1) labels("Sigma periodo" "N obs." "AIC" "BIC")) label nogaps compress nonotes nobaselevels title("Tabla APC (2c, robustez) - Cohortes teoricas, modelo ordinal (OR)")

* margenes
foreach m in gob parl part ffaa igl {
    if "`m'" == "gob"  local nombre "Gobierno"
    if "`m'" == "parl" local nombre "Parlamento"
    if "`m'" == "part" local nombre "Partidos"
    if "`m'" == "ffaa" local nombre "FF.AA."
    if "`m'" == "igl"  local nombre "Iglesia"

    estimates restore `m'_logit
    margins cohort5
    marginsplot, title("Confianza en `nombre' por cohorte") xtitle("Cohorte de nacimiento") ytitle("Probabilidad predicha de confiar") xlabel(, valuelabel angle(45) labsize(vsmall)) name(g1, replace)
    margins, over(year)
    marginsplot, xlabel(2006 2011 2016 2019 2021 2023 2025, angle(45) labsize(small)) xtitle("Año de encuesta") ytitle("Probabilidad predicha de confiar") title("Confianza en `nombre' por período") name(g2, replace)
    margins, at(age_s = (1.8(1)8.5))
    marginsplot, xlabel(1.8 "18" 2.8 "28" 3.8 "38" 4.8 "48" 5.8 "58" 6.8 "68" 7.8 "78" 8.5 "85") xtitle("Edad") ytitle("Probabilidad predicha de confiar") title("Confianza en `nombre' por edad") name(g3, replace)
    graph combine g1 g2 g3, rows(1) title("APC Confianza en `nombre' (a) binaria") xsize(14) ysize(5)
    graph export "$AUXILIAR\1a_binaria_`m'.png", replace width(2400)
}

local limpias "gob ffaa igl"

foreach m in gob parl part ffaa igl {
    if "`m'" == "gob"  local nombre "Gobierno"
    if "`m'" == "parl" local nombre "Parlamento"
    if "`m'" == "part" local nombre "Partidos"
    if "`m'" == "ffaa" local nombre "FF.AA."
    if "`m'" == "igl"  local nombre "Iglesia"

    estimates restore `m'_lineal
    margins cohort5
    marginsplot, title("Confianza en `nombre' por cohorte") xtitle("Cohorte de nacimiento") ytitle("Confianza (z-score por año)") xlabel(, valuelabel angle(45) labsize(vsmall)) name(g1, replace)
    margins, over(year)
    marginsplot, xlabel(2006 2011 2016 2019 2021 2023 2025, angle(45) labsize(small)) xtitle("Año de encuesta") ytitle("Confianza (z-score por año)") title("Confianza en `nombre' por período") name(g2, replace)
    margins, at(age_s = (1.8(1)8.5))
    marginsplot, xlabel(1.8 "18" 2.8 "28" 3.8 "38" 4.8 "48" 5.8 "58" 6.8 "68" 7.8 "78" 8.5 "85") xtitle("Edad") ytitle("Confianza (z-score por año)") title("Confianza en `nombre' por edad") name(g3, replace)
    graph combine g1 g2 g3, rows(1) title("APC Confianza en `nombre' (b) continua") xsize(14) ysize(5)

    if strpos(" `limpias' ", " `m' ") {
        graph export "$PRINCIPAL\1b_continua_`m'.png", replace width(2400)
    }
    else {
        graph export "$AUXILIAR\1b_continua_`m'.png", replace width(2400)
    }
}

foreach m in gob parl part ffaa igl {
    if "`m'" == "gob"  local nombre "Gobierno"
    if "`m'" == "parl" local nombre "Parlamento"
    if "`m'" == "part" local nombre "Partidos"
    if "`m'" == "ffaa" local nombre "FF.AA."
    if "`m'" == "igl"  local nombre "Iglesia"

    estimates restore `m'_ord
    margins cohort5, expression(predict(pr outcome(4)) + predict(pr outcome(5)))
    marginsplot, title("Confianza en `nombre' por cohorte") xtitle("Cohorte de nacimiento") ytitle("P(confía) = P(Y=4)+P(Y=5)") xlabel(, valuelabel angle(45) labsize(vsmall)) name(g1, replace)
    margins, over(year) expression(predict(pr outcome(4)) + predict(pr outcome(5)))
    marginsplot, xlabel(2006 2011 2016 2019 2021 2023 2025, angle(45) labsize(small)) xtitle("Año de encuesta") ytitle("P(confía) = P(Y=4)+P(Y=5)") title("Confianza en `nombre' por período") name(g2, replace)
    margins, at(age_s = (1.8(1)8.5)) expression(predict(pr outcome(4)) + predict(pr outcome(5)))
    marginsplot, xlabel(1.8 "18" 2.8 "28" 3.8 "38" 4.8 "48" 5.8 "58" 6.8 "68" 7.8 "78" 8.5 "85") xtitle("Edad") ytitle("P(confía) = P(Y=4)+P(Y=5)") title("Confianza en `nombre' por edad") name(g3, replace)
    graph combine g1 g2 g3, rows(1) title("APC Confianza en `nombre' (c) ordinal") xsize(14) ysize(5)

    if strpos(" `limpias' ", " `m' ") {
        graph export "$AUXILIAR\1c_ordinal_`m'.png", replace width(2400)
    }
    else {
        graph export "$PRINCIPAL\1c_ordinal_`m'.png", replace width(2400)
    }
}

* margenes_teo
foreach m in gob parl part ffaa igl {
    if "`m'" == "gob"  local nombre "Gobierno"
    if "`m'" == "parl" local nombre "Parlamento"
    if "`m'" == "part" local nombre "Partidos"
    if "`m'" == "ffaa" local nombre "FF.AA."
    if "`m'" == "igl"  local nombre "Iglesia"

    estimates restore `m'_lineal_teo
    margins cohort_teorica
    marginsplot, title("Confianza en `nombre' por cohorte (teórica)") xtitle("Cohorte histórico-generacional") ytitle("Confianza (z-score por año)") xlabel(, valuelabel angle(30) labsize(vsmall)) name(g1, replace)
    margins, over(year)
    marginsplot, xlabel(2006 2011 2016 2019 2021 2023 2025, angle(45) labsize(small)) xtitle("Año de encuesta") ytitle("Confianza (z-score por año)") title("Confianza en `nombre' por período") name(g2, replace)
    margins, at(age_s = (1.8(1)8.5))
    marginsplot, xlabel(1.8 "18" 2.8 "28" 3.8 "38" 4.8 "48" 5.8 "58" 6.8 "68" 7.8 "78" 8.5 "85") xtitle("Edad") ytitle("Confianza (z-score por año)") title("Confianza en `nombre' por edad") name(g3, replace)
    graph combine g1 g2 g3, rows(1) title("APC Confianza en `nombre' (b-teo) continua, cohortes teóricas") xsize(14) ysize(5)
    graph export "$TEORICA\1b_continua_teo_`m'.png", replace width(2400)

    estimates restore `m'_ord_teo
    margins cohort_teorica, expression(predict(pr outcome(4)) + predict(pr outcome(5)))
    marginsplot, title("Confianza en `nombre' por cohorte (teórica)") xtitle("Cohorte histórico-generacional") ytitle("P(confía) = P(Y=4)+P(Y=5)") xlabel(, valuelabel angle(30) labsize(vsmall)) name(g1, replace)
    margins, over(year) expression(predict(pr outcome(4)) + predict(pr outcome(5)))
    marginsplot, xlabel(2006 2011 2016 2019 2021 2023 2025, angle(45) labsize(small)) xtitle("Año de encuesta") ytitle("P(confía) = P(Y=4)+P(Y=5)") title("Confianza en `nombre' por período") name(g2, replace)
    margins, at(age_s = (1.8(1)8.5)) expression(predict(pr outcome(4)) + predict(pr outcome(5)))
    marginsplot, xlabel(1.8 "18" 2.8 "28" 3.8 "38" 4.8 "48" 5.8 "58" 6.8 "68" 7.8 "78" 8.5 "85") xtitle("Edad") ytitle("P(confía) = P(Y=4)+P(Y=5)") title("Confianza en `nombre' por edad") name(g3, replace)
    graph combine g1 g2 g3, rows(1) title("APC Confianza en `nombre' (c-teo) ordinal, cohortes teóricas") xsize(14) ysize(5)
    graph export "$TEORICA\1c_ordinal_teo_`m'.png", replace width(2400)
}

* normalidad
tempname fh_norm
file open `fh_norm' using "$AUXILIAR\tabla_3_diagnostico_normalidad.csv", write replace
file write `fh_norm' "institucion,nivel,n,skewness,kurtosis,chi2_sktest,p_sktest" _n

foreach m in gob parl part ffaa igl {
    if "`m'" == "gob"  local nombre "Gobierno"
    if "`m'" == "parl" local nombre "Parlamento"
    if "`m'" == "part" local nombre "Partidos"
    if "`m'" == "ffaa" local nombre "FF.AA."
    if "`m'" == "igl"  local nombre "Iglesia"

    estimates restore `m'_lineal

    predict resid_ind, residuals
    quietly summarize resid_ind, detail
    local n_r  = r(N)
    local sk_r = r(skewness)
    local ku_r = r(kurtosis)
    quietly sktest resid_ind
    local chi2_r = r(chi2)
    local p_r    = r(P_chi2)
    file write `fh_norm' `""`nombre'""' "," "individual" "," (`n_r') "," %9.4f (`sk_r') "," %9.4f (`ku_r') "," %9.3f (`chi2_r') "," %9.4f (`p_r') _n

    histogram resid_ind, normal title("Residuos individuales: `nombre'") xtitle("Residuo") name(hist_`m', replace)
    qnorm resid_ind, title("QQ-plot residuos individuales: `nombre'") name(qq_`m', replace)
    graph combine hist_`m' qq_`m', rows(1) title("Diagnóstico de normalidad - `nombre' (nivel individual)") xsize(10) ysize(5)
    graph export "$AUXILIAR\3_normalidad_`m'.png", replace width(2000)

    drop resid_ind

    predict re_year_`m', reffects
    preserve
    bys year: keep if _n == 1
    quietly summarize re_year_`m', detail
    local n_re  = r(N)
    local sk_re = r(skewness)
    local ku_re = r(kurtosis)
    quietly sktest re_year_`m'
    local chi2_re = r(chi2)
    local p_re    = r(P_chi2)
    restore
    file write `fh_norm' `""`nombre'""' "," "ano_re" "," (`n_re') "," %9.4f (`sk_re') "," %9.4f (`ku_re') "," %9.3f (`chi2_re') "," %9.4f (`p_re') _n
}

file close `fh_norm'

* wald
capture program drop wald_row
program define wald_row
    args fh especificacion esquema institucion bloque tipo
    capture local stat = r(chi2)
    if _rc == 0 {
        local stattype "chi2"
    }
    else {
        local stat = r(F)
        local stattype "F"
    }
    file write `fh' `"`especificacion'"' "," `"`esquema'"' "," `"`institucion'"' "," `"`bloque'"' "," `"`tipo'"' "," `"`stattype'"' "," %9.3f (`stat') "," %3.0f (r(df)) "," %9.4f (r(p)) _n
end

tempname fh_wald
file open `fh_wald' using "$PRINCIPAL\tabla_4_wald_cohortes.csv", write replace
file write `fh_wald' "especificacion,esquema,institucion,bloque,tipo,stat_type,stat,df,p" _n

foreach spec in binaria zscore ordinal {

    if "`spec'" == "binaria" {
        local sufmodelo "_logit"
        local estcmd    "melogit"
        local dvsuf     "_bin"
        local estopt    ", or vce(robust)"
    }
    else if "`spec'" == "zscore" {
        local sufmodelo "_lineal"
        local estcmd    "mixed"
        local dvsuf     "_z"
        local estopt    ", mle vce(robust)"
    }
    else {
        local sufmodelo "_ord"
        local estcmd    "meologit"
        local dvsuf     ""
        local estopt    ", or vce(robust)"
    }

    local i = 1
    foreach v of local institutions {
        local lbl   : word `i' of `labels'
        local short : word `i' of `shortnames'

        estimates restore `short'`sufmodelo'

        quietly test 1945.cohort5 = 0
        wald_row `fh_wald' "`spec'" "teorica" "`lbl'" "1 (<=1949)" "dentro-bloque"
        quietly test 1950.cohort5 = 1955.cohort5 = 1960.cohort5
        wald_row `fh_wald' "`spec'" "teorica" "`lbl'" "2 (1950-1964)" "dentro-bloque"
        quietly test 1965.cohort5 = 1970.cohort5 = 1975.cohort5
        wald_row `fh_wald' "`spec'" "teorica" "`lbl'" "3 (1965-1979)" "dentro-bloque"
        quietly test 1980.cohort5 = 1985.cohort5 = 1990.cohort5
        wald_row `fh_wald' "`spec'" "teorica" "`lbl'" "4 (1980-1994)" "dentro-bloque"
        quietly test 1995.cohort5 = 2000.cohort5 = 2005.cohort5
        wald_row `fh_wald' "`spec'" "teorica" "`lbl'" "5 (1995+)" "dentro-bloque"

        quietly test 1945.cohort5 = 1950.cohort5
        wald_row `fh_wald' "`spec'" "teorica" "`lbl'" "frontera 1-2 (1949/1950)" "frontera"
        quietly test 1960.cohort5 = 1965.cohort5
        wald_row `fh_wald' "`spec'" "teorica" "`lbl'" "frontera 2-3 (1964/1965)" "frontera"
        quietly test 1975.cohort5 = 1980.cohort5
        wald_row `fh_wald' "`spec'" "teorica" "`lbl'" "frontera 3-4 (1979/1980)" "frontera"
        quietly test 1990.cohort5 = 1995.cohort5
        wald_row `fh_wald' "`spec'" "teorica" "`lbl'" "frontera 4-5 (1994/1995)" "frontera"

        quietly `estcmd' `v'`dvsuf' age_s age_s2 i.cohort_check mujer i.educ4 i.nse4 [pweight=ponderador] || year: `estopt'

        quietly test 11002.cohort_check = 11001.cohort_check
        wald_row `fh_wald' "`spec'" "importada" "`lbl'" "frontera Silenciosa/Boomer (1945/1946)" "frontera"
        quietly test 1960.cohort_check = 1965.cohort_check
        wald_row `fh_wald' "`spec'" "importada" "`lbl'" "frontera Boomer/X (1964/1965)" "frontera"
        quietly test 12002.cohort_check = 12001.cohort_check
        wald_row `fh_wald' "`spec'" "importada" "`lbl'" "frontera X/Millennial (1980/1981)" "frontera"
        quietly test 13002.cohort_check = 13001.cohort_check
        wald_row `fh_wald' "`spec'" "importada" "`lbl'" "frontera Millennial/Z (1996/1997)" "frontera"

        quietly test 20002.cohort_check = 20001.cohort_check
        wald_row `fh_wald' "`spec'" "corte_unico" "`lbl'" "frontera plebiscito 1988 (1970/1971)" "frontera"
        quietly test 20003.cohort_check = 20002.cohort_check
        wald_row `fh_wald' "`spec'" "corte_unico" "`lbl'" "frontera retorno democracia 1990 (1971/1972)" "frontera"

        local ++i
    }
}

file close `fh_wald'

* momento1
tempname fh_m1
file open `fh_m1' using "$PRINCIPAL\lr_bargsted_maldonado.csv", write replace
file write `fh_m1' "especificacion,institucion,ll_full,ll_reducido,chi2,df,p,wald_chi2,wald_df,wald_p" _n

foreach spec in binaria zscore ordinal {
    if "`spec'" == "binaria" {
        local sufmodelo "_logit"
        local estcmd    "melogit"
        local dvsuf     "_bin"
        local estopt    ", or vce(robust)"
    }
    else if "`spec'" == "zscore" {
        local sufmodelo "_lineal"
        local estcmd    "mixed"
        local dvsuf     "_z"
        local estopt    ", mle vce(robust)"
    }
    else {
        local sufmodelo "_ord"
        local estcmd    "meologit"
        local dvsuf     ""
        local estopt    ", or vce(robust)"
    }

    local i = 1
    foreach v of local institutions {
        local lbl   : word `i' of `labels'
        local short : word `i' of `shortnames'

        estimates restore `short'`sufmodelo'
        local ll_full = e(ll)

        quietly test 1945.cohort5 1950.cohort5 1955.cohort5 1960.cohort5 1965.cohort5 1970.cohort5 1975.cohort5 1980.cohort5 1985.cohort5 1990.cohort5 1995.cohort5 2000.cohort5 2005.cohort5
        local wald_chi2 = r(chi2)
        local wald_df   = r(df)
        local wald_p    = r(p)

        quietly `estcmd' `v'`dvsuf' age_s age_s2 mujer i.educ4 i.nse4 [pweight=ponderador] || year: `estopt'
        local ll_reducido = e(ll)
        estimates store modelo_reducido

        quietly lrtest `short'`sufmodelo' modelo_reducido, force

        file write `fh_m1' `"`spec'"' "," `"`lbl'"' "," %12.3f (`ll_full') "," %12.3f (`ll_reducido') "," %9.3f (r(chi2)) "," %3.0f (r(df)) "," %9.4f (r(p)) "," %9.3f (`wald_chi2') "," %3.0f (`wald_df') "," %9.4f (`wald_p') _n

        local ++i
    }
}
file close `fh_m1'

* omitidas
tempname fh_diag
file open `fh_diag' using "$AUXILIAR\diagnostico_omitidas_cohort5.csv", write replace
file write `fh_diag' "especificacion,institucion,n_omitidas,cohortes_omitidas" _n

local niveles_cohort "1945 1950 1955 1960 1965 1970 1975 1980 1985 1990 1995 2000 2005"

foreach spec in binaria zscore ordinal {
    local sufmodelo = cond("`spec'"=="binaria", "_logit", cond("`spec'"=="zscore", "_lineal", "_ord"))

    local i = 1
    foreach v of local institutions {
        local lbl   : word `i' of `labels'
        local short : word `i' of `shortnames'
        estimates restore `short'`sufmodelo'

        local omitidas ""
        local n_omit = 0
        foreach lvl of local niveles_cohort {
            capture local se_lvl = _se[`lvl'.cohort5]
            if _rc != 0 | missing(`se_lvl') | `se_lvl' == 0 {
                local omitidas "`omitidas' `lvl'"
                local ++n_omit
            }
        }
        file write `fh_diag' `"`spec'"' "," `"`lbl'"' "," (`n_omit') "," `"`omitidas'"' _n
        local ++i
    }
}
file close `fh_diag'

* forest
tempname fh_front_q
file open `fh_front_q' using "$PRINCIPAL\5_fronteras_quinquenales.csv", write replace
file write `fh_front_q' "institucion,frontera,chi2,df,p" _n

local cohortvals   "1944 1945 1950 1955 1960 1965 1970 1975 1980 1985 1990 1995 2000 2005"
local frontlabels  `""≤1944 / 1945-49" "1945-49 / 1950-54" "1950-54 / 1955-59" "1955-59 / 1960-64" "1960-64 / 1965-69" "1965-69 / 1970-74" "1970-74 / 1975-79" "1975-79 / 1980-84" "1980-84 / 1985-89" "1985-89 / 1990-94" "1990-94 / 1995-99" "1995-99 / 2000-04" "2000-04 / 2005-07""'

local i = 1
foreach v of local institutions {
    local lbl   : word `i' of `labels'
    local short : word `i' of `shortnames'
    estimates restore `short'_ord

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

gen front_jit = front_pos + cond(institucion=="Gobierno",-0.24, cond(institucion=="Parlamento",-0.12,cond(institucion=="Partidos",0, cond(institucion=="FF.AA.",0.12,0.24))))

twoway (scatter front_jit neglog10p if institucion=="Gobierno", mcolor(navy) msymbol(O)) (scatter front_jit neglog10p if institucion=="Parlamento", mcolor(maroon) msymbol(D)) (scatter front_jit neglog10p if institucion=="Partidos", mcolor(dkgreen) msymbol(T)) (scatter front_jit neglog10p if institucion=="FF.AA.", mcolor(orange) msymbol(S)) (scatter front_jit neglog10p if institucion=="Iglesia", mcolor(purple) msymbol(X)) , xline(1.301, lpattern(dash) lcolor(gs8)) ylabel(1 "≤1944 / 1945-49" 2 "1945-49 / 1950-54" 3 "1950-54 / 1955-59" 4 "1955-59 / 1960-64" 5 "1960-64 / 1965-69" 6 "1965-69 / 1970-74" 7 "1970-74 / 1975-79" 8 "1975-79 / 1980-84" 9 "1980-84 / 1985-89" 10 "1985-89 / 1990-94" 11 "1990-94 / 1995-99" 12 "1995-99 / 2000-04" 13 "2000-04 / 2005-07", angle(0) labsize(vsmall)) ytitle("") xtitle("-log10(p), test de Wald (especificación ordinal)") title("Fronteras entre quinquenios consecutivos", size(medium)) legend(order(1 "Gobierno" 2 "Parlamento" 3 "Partidos" 4 "FF.AA." 5 "Iglesia") rows(1) position(6) size(small)) graphregion(color(white)) xsize(10) ysize(9)
graph export "$PRINCIPAL\5_forest_encrucijadas.png", replace width(2400)
restore

* tendencia
tempname fh_trend
tempfile trend_data
postfile `fh_trend' int anio byte inst_id double prop using "`trend_data'", replace

quietly levelsof year, local(anios)
local i = 1
foreach v of local institutions {
    foreach a of local anios {
        capture quietly mean `v'_bin [pweight=ponderador] if year == `a'
        if _rc == 0 {
            matrix b = e(b)
            post `fh_trend' (`a') (`i') (b[1,1])
        }
    }
    local ++i
}
postclose `fh_trend'

preserve
use "`trend_data'", clear
label define instlbl2 1 "Gobierno" 2 "Parlamento" 3 "Partidos" 4 "FF.AA." 5 "Iglesia"
label values inst_id instlbl2

twoway (connected prop anio if inst_id==1, mcolor(navy) lcolor(navy) msymbol(O)) (connected prop anio if inst_id==2, mcolor(maroon) lcolor(maroon) msymbol(D)) (connected prop anio if inst_id==3, mcolor(dkgreen) lcolor(dkgreen) msymbol(T)) (connected prop anio if inst_id==4, mcolor(orange) lcolor(orange) msymbol(S)) (connected prop anio if inst_id==5, mcolor(purple) lcolor(purple) msymbol(X)) , xtitle("Año de encuesta") ytitle("% que confía (top-2-box, ponderado)") title("Confianza institucional en Chile, 2006-2025", size(medium)) subtitle("Tendencia descriptiva simple, sin ajustar por cohorte ni edad", size(vsmall)) legend(order(1 "Gobierno" 2 "Parlamento" 3 "Partidos" 4 "FF.AA." 5 "Iglesia") rows(1) position(6) size(small)) graphregion(color(white)) xsize(10) ysize(6)
graph export "$PRINCIPAL\6_tendencia_temporal.png", replace width(2400)
restore

* brecha1
* figura 4: corte 1995 en formato continuo, con el mismo diseño que las figuras 7, 8 y 10 (olas desde 2013, edad fija en el promedio)
* antes usaba todas las olas, incluidas 2006-2012, cuando todavía no había encuestados nacidos desde 1995
tempname fh_estallido
tempfile margins_estallido
postfile `fh_estallido' byte inst_id byte post_estallido double b double ll double ul using "`margins_estallido'", replace

local i = 1
foreach v of local institutions {
    quietly mixed `v'_z c.age_s##c.age_s i.post_estallido mujer i.educ4 i.nse4 if year >= 2013 [pweight=ponderador] || year:, mle vce(robust)
    quietly margins post_estallido, at((mean) age_s)
    matrix tab_est = r(table)
    forvalues c = 1/2 {
        post `fh_estallido' (`i') (`c' - 1) (tab_est[1,`c']) (tab_est[5,`c']) (tab_est[6,`c'])
    }
    local ++i
}
postclose `fh_estallido'

preserve
use "`margins_estallido'", clear
label define instlbl 1 "Gobierno" 2 "Parlamento" 3 "Partidos" 4 "FF.AA." 5 "Iglesia"
label values inst_id instlbl

gen xpos = inst_id + (post_estallido - 0.5) * 0.35

twoway (bar b xpos if post_estallido == 0, color(navy%70) barwidth(0.32)) (bar b xpos if post_estallido == 1, color(orange%70) barwidth(0.32)) (rcap ll ul xpos, lcolor(black)), xlabel(1 "Gobierno" 2 "Parlamento" 3 "Partidos" 4 "FF.AA." 5 "Iglesia", angle(0)) xtitle("") ytitle("Confianza (z-score por año)", size(small)) yline(0, lcolor(gs10) lpattern(dash)) title("Corte 1995, formato continuo", size(medium)) legend(order(1 "Nacidos antes de 1995" 2 "Nacidos desde 1995") rows(1) position(6) size(small)) graphregion(color(white)) xsize(9) ysize(6)
graph export "$PRINCIPAL\4_brecha_estallido.png", replace width(2400)
restore

* cortes_hapc
* figuras 7 y 8 con la lógica de las figuras 11 y 12: cada frontera candidata entra como corte binario (nacidos desde el corte vs. antes), no como test entre dos cohortes vecinas
* así los tres esquemas se comparan con el mismo diseño; antes se comparaban quinquenios, pares de años o años sueltos según el esquema
* HAPC ordinal con intercepto aleatorio de año, solo en las olas en que ya hay nacidos desde el corte (año >= corte + 18), como en la figura 11
* la diferencia es el efecto marginal sobre P(confía) = P(Y=4)+P(Y=5) con la edad fija en el promedio, como en las figuras 11 y 12
* ojo: un corte binario también recoge cualquier tendencia suave de cohorte (ver bv_barrido); se lee dónde separa más, no como test de discontinuidad
* para correr solo esta sección: primero config y prep (hasta antes de * modelos), luego esta sección; redefine sus locals
local institutions "conf_gobierno conf_parlamento conf_partidos conf_ffaa conf_iglesia"
local controles     "mujer i.educ4 i.nse4"

* cortes (nacidos desde): 1946 Silenciosa/Boomer, 1950 Pre-masificación/Estado desarrollista, 1965 Boomer/X y Estado desarrollista/Dictadura-transición,
* 1971 plebiscito 1988, 1972 retorno a la democracia 1990, 1980 Dictadura-transición/Democracia neoliberal, 1981 X/Millennial,
* 1995 Democracia neoliberal/Generación del estallido, 1997 Millennial/Z
local cortes "1946 1950 1965 1971 1972 1980 1981 1995 1997"

tempname fh_cortes
tempfile cortes_data
postfile `fh_cortes' int corte byte inst_id int anio_min long n double p0 double ll0 double ul0 double p1 double ll1 double ul1 double dif double se double pval double dll double dul using "`cortes_data'", replace

foreach c of local cortes {
    capture drop post_c
    gen byte post_c = (birthyear >= `c') if !missing(birthyear)
    local i = 1
    foreach v of local institutions {
        local n = .
        local amin = .
        matrix tab_p = J(9, 2, .)
        matrix tab_d = J(9, 2, .)
        * edad como c.age_s##c.age_s (mismo modelo que age_s age_s2) para que margins pueda fijarla en el promedio
        capture quietly meologit `v' c.age_s##c.age_s i.post_c `controles' if year >= `c' + 18 [pweight=ponderador] || year:, or vce(robust)
        if _rc == 0 {
            local n = e(N)
            quietly summarize year if e(sample)
            local amin = r(min)
            * col 1 = nacidos antes del corte, col 2 = nacidos desde el corte
            capture quietly margins post_c, at((mean) age_s) expression(predict(pr outcome(4)) + predict(pr outcome(5)))
            if _rc == 0 matrix tab_p = r(table)
            * col 2 = diferencia entre ambos lados, con su propio IC
            capture quietly margins, dydx(post_c) at((mean) age_s) expression(predict(pr outcome(4)) + predict(pr outcome(5)))
            if _rc == 0 matrix tab_d = r(table)
            else di as text "corte `c', `v': margins no pudo estimar la diferencia, queda en missing"
        }
        else di as text "corte `c', `v': el modelo no se pudo estimar, queda en missing"
        post `fh_cortes' (`c') (`i') (`amin') (`n') (tab_p[1,1]) (tab_p[5,1]) (tab_p[6,1]) (tab_p[1,2]) (tab_p[5,2]) (tab_p[6,2]) (tab_d[1,2]) (tab_d[2,2]) (tab_d[4,2]) (tab_d[5,2]) (tab_d[6,2])
        local ++i
    }
}
drop post_c
postclose `fh_cortes'

preserve
use "`cortes_data'", clear
label define instlbl9 1 "Gobierno" 2 "Parlamento" 3 "Partidos" 4 "FF.AA." 5 "Iglesia", replace
label values inst_id instlbl9
gen byte esquema = 1 if inlist(corte, 1946, 1981, 1997)
replace esquema = 2 if inlist(corte, 1950, 1980, 1995)
replace esquema = 3 if inlist(corte, 1971, 1972)
replace esquema = 4 if corte == 1965
label define esquemalbl 1 "Importada" 2 "Propia" 3 "Corte único" 4 "Importada y propia", replace
label values esquema esquemalbl
export delimited using "$PRINCIPAL\8_cortes_hapc.csv", replace

* 8: diferencia en cada frontera candidata, el marcador indica el esquema al que pertenece
twoway (rcap dll dul corte, lcolor(gs10)) (scatter dif corte if esquema == 1, mcolor(navy) msymbol(O)) (scatter dif corte if esquema == 2, mcolor(orange) msymbol(D)) (scatter dif corte if esquema == 3, mcolor(maroon) msymbol(T)) (scatter dif corte if esquema == 4, mcolor(dkgreen) msymbol(S)), by(inst_id, rows(2) note("") title("Fronteras candidatas como corte binario", size(medium)) graphregion(color(white))) yline(0, lcolor(gs10)) xlabel(1950(10)2000) xtitle("Corte (nacidos desde)") ytitle("Diferencia en P(confía)") legend(order(2 "Importada" 3 "Propia" 4 "Corte único" 5 "Importada y propia") rows(1) size(small)) xsize(12) ysize(7)
graph export "$PRINCIPAL\8_cortes_hapc.png", replace width(2400)

* 7: el corte 1995, cada lado con su IC
keep if corte == 1995
export delimited using "$PRINCIPAL\7_brecha_estallido_prob.csv", replace
keep inst_id p0 ll0 ul0 p1 ll1 ul1
reshape long p ll ul, i(inst_id) j(grupo)
gen xpos = inst_id + (grupo - 0.5) * 0.35
twoway (bar p xpos if grupo == 0, color(navy%70) barwidth(0.32)) (bar p xpos if grupo == 1, color(orange%70) barwidth(0.32)) (rcap ll ul xpos, lcolor(black)), xlabel(1 "Gobierno" 2 "Parlamento" 3 "Partidos" 4 "FF.AA." 5 "Iglesia", angle(0)) xtitle("") ytitle("P(confía) = P(Y=4)+P(Y=5)", size(small)) title("Corte 1995 en el HAPC", size(medium)) legend(order(1 "Nacidos antes de 1995" 2 "Nacidos desde 1995") rows(1) position(6) size(small)) graphregion(color(white)) xsize(9) ysize(6)
graph export "$PRINCIPAL\7_brecha_estallido_prob.png", replace width(2400)
restore

* brecha3
* figura 10: la diferencia del corte 1995 con su IC, tomada de la figura 8 (mismo modelo que la 7: olas desde 2013, edad fija en el promedio)
* no estima nada, lee 8_cortes_hapc.csv: si cortes_hapc ya corrió, basta con correr esta sección
* antes era un meologit aparte sobre todas las olas, con la diferencia promediada sobre la muestra (daba cifras distintas a la 7 para la misma brecha)
preserve
import delimited "$PRINCIPAL\8_cortes_hapc.csv", clear varnames(1) case(preserve)
keep if corte == 1995
gen byte inst_n = 1 if inst_id == "Gobierno"
replace inst_n = 2 if inst_id == "Parlamento"
replace inst_n = 3 if inst_id == "Partidos"
replace inst_n = 4 if inst_id == "FF.AA."
replace inst_n = 5 if inst_id == "Iglesia"
export delimited inst_id anio_min n dif se pval dll dul using "$PRINCIPAL\10_forest_brecha_estallido.csv", replace

gen inst_rev = 6 - inst_n
gen sig = (pval < 0.05)

twoway (rcap dll dul inst_rev, horizontal lcolor(gs8)) (scatter inst_rev dif if sig==1, mcolor(navy) msymbol(O) msize(large)) (scatter inst_rev dif if sig==0, mcolor(gs10) msymbol(O) msize(large)), xline(0, lpattern(dash) lcolor(gs8)) ylabel(1 "Iglesia" 2 "FF.AA." 3 "Partidos" 4 "Parlamento" 5 "Gobierno", angle(0)) ytitle("") xtitle("Diferencia en P(confía) entre nacidos desde 1995 y antes", size(small)) title("Brecha post-estallido", size(medium)) legend(off) graphregion(color(white)) xsize(9) ysize(6)
graph export "$PRINCIPAL\10_forest_brecha_estallido.png", replace width(2400)
restore

* grafico1
preserve
import delimited "$PRINCIPAL\lr_bargsted_maldonado.csv", clear varnames(1) case(preserve)

gen logchi2 = log10(wald_chi2)

gen spec_pos = .
replace spec_pos = 1 if especificacion == "binaria"
replace spec_pos = 2 if especificacion == "zscore"
replace spec_pos = 3 if especificacion == "ordinal"

gen spec_jit = spec_pos + cond(institucion=="Gobierno",-0.24, cond(institucion=="Parlamento",-0.12,cond(institucion=="Partidos",0, cond(institucion=="FF.AA.",0.12,0.24))))

twoway (scatter spec_jit logchi2 if institucion=="Gobierno", mcolor(navy) msymbol(O)) (scatter spec_jit logchi2 if institucion=="Parlamento", mcolor(maroon) msymbol(D)) (scatter spec_jit logchi2 if institucion=="Partidos", mcolor(dkgreen) msymbol(T)) (scatter spec_jit logchi2 if institucion=="FF.AA.", mcolor(orange) msymbol(S)) (scatter spec_jit logchi2 if institucion=="Iglesia", mcolor(purple) msymbol(X)) , ylabel(1 "Binaria (top-2)" 2 "Continua (z-score)" 3 "Ordinal completa", angle(0) labsize(small)) ytitle("") xtitle("log10(chi2), test de Wald conjunto sobre los 13 coeficientes de cohort5") title("¿Existe algún efecto de cohorte? (momento 1)", size(medium)) subtitle("Test de Wald conjunto, réplica del chequeo global de Bargsted & Maldonado (2018) — p<0.0001 en las 15 combinaciones", size(vsmall)) legend(order(1 "Gobierno" 2 "Parlamento" 3 "Partidos" 4 "FF.AA." 5 "Iglesia") rows(1) position(6) size(small)) note("Gobierno: df=12 en las tres especificaciones (colinealidad entre dos coeficientes de cohorte al testearlos juntos); resto en df=13.", size(vsmall)) graphregion(color(white) margin(l=15)) plotregion(color(white)) xsize(11) ysize(5.5)
graph export "$PRINCIPAL\9_wald_momento1_cohorte.png", replace width(2400)
restore

* bv_prep
* replica de Balcells y Villamil (2026, EJPR): corte binario sobre toda la muestra, cruzado con el año de encuesta
* como ellos: logit con EF de año y log de la edad (no HAPC), solo binaria top-2; a diferencia de ellos, con ponderador
* su corte es la primera cohorte que cumple 18 fuera de la dictadura (1958 cumple 18 en 1976); el análogo chileno es 1972 (cumple 18 en 1990)
* redefine los locals por si estas secciones se corren solas
local institutions "conf_gobierno conf_parlamento conf_partidos conf_ffaa conf_iglesia"
local labels        `""Gobierno" "Parlamento" "Partidos" "FF.AA." "Iglesia""'
local controles     "mujer i.educ4 i.nse4"

capture drop age_l post1972
gen age_l = ln(edad)
gen post1972 = (birthyear >= 1972) if !missing(birthyear)
label define post1972lbl 0 "Nacidos antes de 1972" 1 "Nacidos desde 1972", replace
label values post1972 post1972lbl

* en qué olas aparece la generación del estallido
tab year post_estallido

* bv_corte
* figura 2 de ellos: P(confía) de cada lado del corte, ola por ola, con la edad fija en el promedio (ellos la fijan en ~42 años)
* el corte 1995 se corre igual, solo en las olas donde ya hay nacidos desde 1995 (2013 en adelante)
tempname fh_bv
tempfile bv_data
postfile `fh_bv' int corte byte inst_id int anio double p0 double ll0 double ul0 double p1 double ll1 double ul1 double dif double se double pval double dll double dul using "`bv_data'", replace

foreach c in 1972 1995 {
    local cvar = cond(`c' == 1972, "post1972", "post_estallido")
    local i = 1
    foreach v of local institutions {
        * se excluyen las olas en que el grupo posterior no tiene variación en la dependiente (Parlamento 2017 con el corte 1995: 0 de 150 confían)
        * si se dejan, logit bota esa celda por predicción perfecta y margins no puede estimar el grupo posterior en ninguna ola
        capture drop m_post
        quietly egen m_post = mean(`v'_bin) if `cvar' == 1 & year >= `c' + 18 & !missing(`v'_bin, age_l, mujer, educ4, nse4, ponderador), by(year)
        quietly levelsof year if inlist(m_post, 0, 1), local(olas_sin_var)
        local excl ""
        foreach a of local olas_sin_var {
            local excl "`excl' & year != `a'"
            di as text "corte `c', `v': se excluye la ola `a' (el grupo posterior no tiene variación)"
        }
        drop m_post
        quietly logit `v'_bin i.`cvar'##i.year age_l `controles' [pweight=ponderador] if year >= `c' + 18 `excl', vce(robust)
        quietly levelsof year if e(sample), local(anios_est)
        foreach a of local anios_est {
            * red de seguridad: si igual una ola no es estimable, queda en missing y se avisa
            capture quietly margins `cvar', at(year = `a' (mean) age_l)
            if _rc == 0 matrix tab_p = r(table)
            else matrix tab_p = J(9, 2, .)
            capture quietly margins, dydx(`cvar') at(year = `a' (mean) age_l)
            local rc_d = _rc
            if `rc_d' == 0 matrix tab_d = r(table)
            else {
                matrix tab_d = J(9, 2, .)
                matrix tab_p[1, 2] = .
                matrix tab_p[5, 2] = .
                matrix tab_p[6, 2] = .
                di as text "corte `c', `v', año `a': grupo posterior no estimable (rc = `rc_d'), queda en missing"
            }
            * col 1 de tab_p es el grupo antes del corte y col 2 el grupo después; en tab_d la col 2 es la diferencia
            post `fh_bv' (`c') (`i') (`a') (tab_p[1,1]) (tab_p[5,1]) (tab_p[6,1]) (tab_p[1,2]) (tab_p[5,2]) (tab_p[6,2]) (tab_d[1,2]) (tab_d[2,2]) (tab_d[4,2]) (tab_d[5,2]) (tab_d[6,2])
        }
        local ++i
    }
}
postclose `fh_bv'

preserve
use "`bv_data'", clear
label define instlbl6 1 "Gobierno" 2 "Parlamento" 3 "Partidos" 4 "FF.AA." 5 "Iglesia"
label values inst_id instlbl6
export delimited using "$PRINCIPAL\11_corte_bv_por_ano.csv", replace

foreach c in 1972 1995 {
    twoway (rcap ll0 ul0 anio if corte == `c', lcolor(navy%40)) (connected p0 anio if corte == `c', mcolor(navy) lcolor(navy) msymbol(O)) (rcap ll1 ul1 anio if corte == `c', lcolor(orange%40)) (connected p1 anio if corte == `c', mcolor(orange) lcolor(orange) msymbol(D)), by(inst_id, rows(2) note("") title("Corte `c'", size(medium)) graphregion(color(white))) xtitle("Año de encuesta") ytitle("P(confía), top-2") legend(order(2 "Nacidos antes de `c'" 4 "Nacidos desde `c'") rows(1) size(small)) xsize(12) ysize(7)
    graph export "$PRINCIPAL\11_corte`c'_por_ano.png", replace width(2400)
}
restore

* bv_barrido
* placebo generalizado: el mismo corte binario (sin cruzar con año) movido año a año entre 1950 y 2000
* su placebo es 7 años después del corte; el análogo chileno (1979/1980) es frontera de nuestra periodización, por eso se barre todo
* ojo: con log de la edad y EF de año la dummy también recoge cualquier tendencia suave de cohorte; se lee dónde el corte separa más, no como test de discontinuidad
tempname fh_scan
tempfile scan_data
postfile `fh_scan' int corte byte inst_id double dif double se double pval double ll double ul using "`scan_data'", replace

forvalues c = 1950/2000 {
    capture drop post_tmp
    gen byte post_tmp = (birthyear >= `c') if !missing(birthyear)
    local i = 1
    foreach v of local institutions {
        quietly logit `v'_bin i.post_tmp i.year age_l `controles' [pweight=ponderador], vce(robust)
        quietly margins, dydx(post_tmp) at((mean) age_l)
        matrix tab_s = r(table)
        post `fh_scan' (`c') (`i') (tab_s[1,2]) (tab_s[2,2]) (tab_s[4,2]) (tab_s[5,2]) (tab_s[6,2])
        local ++i
    }
}
drop post_tmp
postclose `fh_scan'

preserve
use "`scan_data'", clear
label define instlbl7 1 "Gobierno" 2 "Parlamento" 3 "Partidos" 4 "FF.AA." 5 "Iglesia"
label values inst_id instlbl7
export delimited using "$PRINCIPAL\12_barrido_cortes.csv", replace

twoway (rarea ll ul corte, color(gs13)) (line dif corte, lcolor(navy)), by(inst_id, rows(2) note("") title("Barrido de cortes", size(medium)) graphregion(color(white))) xline(1972 1995, lpattern(dash) lcolor(gs8)) yline(0, lcolor(gs10)) xtitle("Corte (nacidos desde)") ytitle("Diferencia en P(confía)") legend(off) xsize(12) ysize(7)
graph export "$PRINCIPAL\12_barrido_cortes.png", replace width(2400)
restore

* bv_edad
* figura 3 de ellos: perfil de edad estimado aparte en cada período de encuesta
* un desplazamiento parejo de toda la curva es período; uno concentrado en un tramo de edad es cohorte
* tres formas para la edad: 1 cuadrática (la de ellos), 2 cúbica, 3 grupos de edad (sin forma impuesta)
* la cuadrática se curva hacia un solo lado: si la curva sube fuerte en un extremo, levanta también el otro y puede inventar un repunte en los jóvenes
* la cúbica también es inestable en los extremos de edad; los grupos son la referencia para ver si un repunte es real
capture drop periodo5 edad_g
gen periodo5 = 5 * floor(year / 5)
replace periodo5 = 2020 if year == 2025
label define periodo5lbl 2005 "2006-2009" 2010 "2010-2014" 2015 "2015-2019" 2020 "2020-2025", replace
label values periodo5 periodo5lbl

* 18-24, 25-29, ..., 75-79, 80-85; en 2006-2009 no hay nadie de 80 o más (nacidos desde 1930), así que ese período tiene un grupo menos
gen edad_g = 5 * floor(edad / 5)
replace edad_g = 20 if edad_g < 20
replace edad_g = 80 if edad_g > 80

tempname fh_edad
tempfile edad_data
postfile `fh_edad' byte forma byte inst_id int periodo double edad_v double p double ll double ul double p_cubico using "`edad_data'", replace

quietly levelsof periodo5, local(periodos)
local i = 1
foreach v of local institutions {
    foreach p of local periodos {
        * formas 1 y 2 con la edad en décadas (age_s) para que el término cúbico no desordene la escala; las predicciones son las mismas que con la edad en años
        forvalues f = 1/2 {
            local poli = cond(`f' == 1, "c.age_s##c.age_s", "c.age_s##c.age_s##c.age_s")
            capture quietly logit `v'_bin `poli' i.year `controles' [pweight=ponderador] if periodo5 == `p', vce(robust)
            if _rc != 0 continue
            * p_cubico: test de Wald del término cúbico, dice si la cúbica agrega algo a la cuadrática
            local pc = .
            if `f' == 2 {
                quietly test c.age_s#c.age_s#c.age_s
                local pc = r(p)
            }
            quietly margins, at(age_s = (2(0.5)8))
            matrix tab_e = r(table)
            local k = 1
            forvalues e = 20(5)80 {
                post `fh_edad' (`f') (`i') (`p') (`e') (tab_e[1,`k']) (tab_e[5,`k']) (tab_e[6,`k']) (`pc')
                local ++k
            }
        }
        * forma 3: grupos de edad, cada punto se ubica en el centro de su grupo
        capture quietly logit `v'_bin i.edad_g i.year `controles' [pweight=ponderador] if periodo5 == `p', vce(robust)
        if _rc != 0 continue
        quietly levelsof edad_g if e(sample), local(grupos)
        local ng : word count `grupos'
        quietly margins edad_g
        matrix tab_e = r(table)
        if colsof(tab_e) != `ng' {
            di as text "`v', período `p': los grupos de edad no calzan con margins, se omite la forma 3"
            continue
        }
        local k = 1
        foreach g of local grupos {
            local mid = cond(`g' == 20, 21, cond(`g' == 80, 82.5, `g' + 2))
            * si un grupo no es estimable (sin error estándar) queda en missing
            post `fh_edad' (3) (`i') (`p') (`mid') (cond(missing(tab_e[2,`k']), ., tab_e[1,`k'])) (tab_e[5,`k']) (tab_e[6,`k']) (.)
            local ++k
        }
    }
    local ++i
}
postclose `fh_edad'

preserve
use "`edad_data'", clear
label define instlbl8 1 "Gobierno" 2 "Parlamento" 3 "Partidos" 4 "FF.AA." 5 "Iglesia"
label values inst_id instlbl8
label define formalbl 1 "cuadrática" 2 "cúbica" 3 "grupos de edad"
label values forma formalbl
export delimited using "$PRINCIPAL\13_edad_por_periodo.csv", replace

* 13: cuadrática (réplica de ellos), 13b: cúbica, 13c: grupos de edad
forvalues f = 1/2 {
    local suf = cond(`f' == 1, "_edad_por_periodo", "b_edad_cubica")
    local tit = cond(`f' == 1, "Edad por período, cuadrática", "Edad por período, cúbica")
    twoway (rarea ll ul edad_v if forma == `f' & periodo == 2005, color(navy%20)) (line p edad_v if forma == `f' & periodo == 2005, lcolor(navy)) (rarea ll ul edad_v if forma == `f' & periodo == 2020, color(orange%20)) (line p edad_v if forma == `f' & periodo == 2020, lcolor(orange)), by(inst_id, rows(2) note("") title("`tit'", size(medium)) graphregion(color(white))) xtitle("Edad") ytitle("P(confía), top-2") legend(order(2 "2006-2009" 4 "2020-2025") rows(1) size(small)) xsize(12) ysize(7)
    graph export "$PRINCIPAL\13`suf'.png", replace width(2400)
}

twoway (rcap ll ul edad_v if forma == 3 & periodo == 2005, lcolor(navy%40)) (connected p edad_v if forma == 3 & periodo == 2005, mcolor(navy) lcolor(navy) msymbol(O) msize(small)) (rcap ll ul edad_v if forma == 3 & periodo == 2020, lcolor(orange%40)) (connected p edad_v if forma == 3 & periodo == 2020, mcolor(orange) lcolor(orange) msymbol(D) msize(small)), by(inst_id, rows(2) note("") title("Edad por período, grupos de edad", size(medium)) graphregion(color(white))) xtitle("Edad") ytitle("P(confía), top-2") xlabel(20(10)80) legend(order(2 "2006-2009" 4 "2020-2025") rows(1) size(small)) xsize(12) ysize(7)
graph export "$PRINCIPAL\13c_edad_grupos.png", replace width(2400)
restore

* cobertura
local variables "conf_gobierno conf_parlamento conf_partidos conf_ffaa conf_iglesia edad mujer educ4 nse4 cohort5"
local varlabels `""Confianza en Gobierno" "Confianza en Parlamento" "Confianza en Partidos" "Confianza en FF.AA." "Confianza en Iglesia" "Edad" "Mujer (sexo)" "Nivel educativo (educ4)" "Nivel socioeconomico (nse4)" "Cohorte quinquenal (cohort5)""'

tempname fh_cob
file open `fh_cob' using "$PRINCIPAL\cobertura_variables_detalle.csv", write replace
file write `fh_cob' "variable,year,n" _n

local i = 1
foreach v of local variables {
    local lbl : word `i' of `varlabels'
    quietly levelsof year, local(anios)
    foreach a of local anios {
        quietly count if year == `a' & !missing(`v')
        file write `fh_cob' `""`lbl'""' "," (`a') "," (`r(N)') _n
    }
    local ++i
}
file close `fh_cob'

tempname fh_cob2
file open `fh_cob2' using "$PRINCIPAL\cobertura_variables_resumen.csv", write replace
file write `fh_cob2' "variable,n_total,n_olas_con_datos,n_olas_total,min,max,n_categorias" _n

quietly levelsof year, local(anios_todas)
local n_olas_total : word count `anios_todas'

local i = 1
foreach v of local variables {
    local lbl : word `i' of `varlabels'
    quietly count if !missing(`v')
    local ntot = r(N)

    local olas_con_datos = 0
    foreach a of local anios_todas {
        quietly count if year == `a' & !missing(`v')
        if r(N) > 0 local olas_con_datos = `olas_con_datos' + 1
    }

    quietly summarize `v'
    local vmin = r(min)
    local vmax = r(max)
    quietly levelsof `v', local(cats)
    local ncat : word count `cats'

    file write `fh_cob2' `""`lbl'""' "," (`ntot') "," (`olas_con_datos') "," (`n_olas_total') "," %9.2f (`vmin') "," %9.2f (`vmax') "," (`ncat') _n
    local ++i
}
file close `fh_cob2'

di as text "listo"
