// Confianza institucional y cohortes generacionales en Chile
// Bicentenario 2006-2025, Bustamante & Quintero, Congreso Triada 2026
// Índice: 0 config, 1 prep, 2 modelos principales, 3 robustez teórica,
// 4 márgenes, 4B márgenes teóricas, 5 normalidad, 6 wald fronteras,
// 7 wald conjunto de cohorte, 8 diagnóstico dummies omitidas,
// 9 forest quinquenal, 10 tendencia temporal, 11 brecha z-score,
// 12 brecha probabilidad, 13 curva de especificaciones, 14 gráfico
// momento 1, 15 cobertura de variables

// 0. configuración
global DATA      "C:\Users\gonza\Dropbox\Proyectos personales\02.- DATOS\Bicentenario\bicentenario_panel_armonizado.dta"
global PRINCIPAL "C:\Users\gonza\Dropbox\Proyectos personales\01.- Desarrollo investigación\Quintero, Bustamante\Análisis final\Principal_NSE"
global AUXILIAR  "C:\Users\gonza\Dropbox\Proyectos personales\01.- Desarrollo investigación\Quintero, Bustamante\Análisis final\Auxiliar_NSE"
global TEORICA   "C:\Users\gonza\Dropbox\Proyectos personales\01.- Desarrollo investigación\Quintero, Bustamante\Análisis final\Cohortes teóricas_NSE"

// 1. preparación de datos
use "$DATA", clear

gen int birthyear = year - edad
keep if birthyear >= 1930 & birthyear <= 2007
keep if edad >= 18 & edad <= 85

// svy: no combina con los efectos aleatorios anidados de melogit/mixed, así
// que el ponderador va como pweight en cada modelo, con vce(robust)
svyset folio_mapa [pw=ponderador], strata(estrato) vce(linearized) singleunit(centered)

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

// periodización histórico-local (Araujo & Martuccelli 2012 + Generación
// del estallido, Mannheim 1928 / Krosnick & Alwin 1989) — robustez, no
// reemplaza cohort5 como especificación principal
gen cohort_teorica = 1     if birthyear <= 1949
replace cohort_teorica = 2 if inrange(birthyear, 1950, 1964)
replace cohort_teorica = 3 if inrange(birthyear, 1965, 1979)
replace cohort_teorica = 4 if inrange(birthyear, 1980, 1994)
replace cohort_teorica = 5 if birthyear >= 1995

label define cohort_teoricalbl ///
    1 "Pre-masificación educativa (<=1949)" ///
    2 "Estado desarrollista (1950-1964)" ///
    3 "Dictadura/transición (1965-1979)" ///
    4 "Democracia neoliberal (1980-1994)" ///
    5 "Generación del estallido (1995+)"
label values cohort_teorica cohort_teoricalbl

// esquema importado (Silenciosa/Boomer/X/Millennial/Z) y corte único estilo
// Balcells & Villamil 2026, con ventana ±2 años alrededor de cada frontera
// candidata (año contra año da muy poca potencia); Balcells queda en ±1
// porque sus dos cortes están a solo 2 años de distancia entre sí
gen cohort_check = cohort5
replace cohort_check = 11001 if inrange(birthyear, 1944, 1945)
replace cohort_check = 11002 if inrange(birthyear, 1946, 1947)
replace cohort_check = 12001 if inrange(birthyear, 1979, 1980)
replace cohort_check = 12002 if inrange(birthyear, 1981, 1982)
replace cohort_check = 13001 if inrange(birthyear, 1995, 1996)
replace cohort_check = 13002 if inrange(birthyear, 1997, 1998)
replace cohort_check = 20001 if birthyear == 1970
replace cohort_check = 20002 if birthyear == 1971
replace cohort_check = 20003 if birthyear == 1972
replace cohort_check = 20004 if birthyear == 1973

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

// 2. modelos principales (cohort5)
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

foreach m in gob_logit parl_logit part_logit ffaa_logit igl_logit ///
             gob_lineal parl_lineal part_lineal ffaa_lineal igl_lineal ///
             gob_ord parl_ord part_ord ffaa_ord igl_ord {
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

esttab gob_logit parl_logit part_logit ffaa_logit igl_logit ///
    using "$AUXILIAR\tabla_1a_binaria.rtf", replace ///
    eform b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
    mtitles("Gobierno" "Parlamento" "Partidos" "FF.AA." "Iglesia") ///
    stats(sigma_p N AIC BIC, fmt(4 0 1 1) labels("Sigma periodo" "N obs." "AIC" "BIC")) ///
    label nogaps compress nonotes nobaselevels ///
    title("Tabla APC (a) - Modelo binario logistico (OR; DV: confia top-2-box)")

esttab gob_lineal parl_lineal part_lineal ffaa_lineal igl_lineal ///
    using "$AUXILIAR\tabla_1b_continua.rtf", replace ///
    b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
    mtitles("Gobierno" "Parlamento" "Partidos" "FF.AA." "Iglesia") ///
    stats(sigma_p N AIC BIC, fmt(4 0 1 1) labels("Sigma periodo" "N obs." "AIC" "BIC")) ///
    label nogaps compress nonotes nobaselevels ///
    title("Tabla APC (b) - Modelo lineal sobre z-score (DV: confianza estandarizada por ano)")

esttab gob_ord parl_ord part_ord ffaa_ord igl_ord ///
    using "$PRINCIPAL\tabla_1c_ordinal.rtf", replace ///
    eform b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
    mtitles("Gobierno" "Parlamento" "Partidos" "FF.AA." "Iglesia") ///
    stats(sigma_p N AIC BIC, fmt(4 0 1 1) labels("Sigma periodo" "N obs." "AIC" "BIC")) ///
    label nogaps compress nonotes nobaselevels ///
    title("Tabla APC (c) - Modelo ordinal logistico (OR; DV: escala 1-5 completa) - ESPECIFICACION PRINCIPAL")

// 3. robustez: cohortes teóricas
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

foreach m in gob_logit_teo parl_logit_teo part_logit_teo ffaa_logit_teo igl_logit_teo ///
             gob_lineal_teo parl_lineal_teo part_lineal_teo ffaa_lineal_teo igl_lineal_teo ///
             gob_ord_teo parl_ord_teo part_ord_teo ffaa_ord_teo igl_ord_teo {
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

esttab gob_logit_teo parl_logit_teo part_logit_teo ffaa_logit_teo igl_logit_teo ///
    using "$AUXILIAR\tabla_2a_binaria_robustez_teorica.rtf", replace ///
    eform b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
    mtitles("Gobierno" "Parlamento" "Partidos" "FF.AA." "Iglesia") ///
    stats(sigma_p N AIC BIC, fmt(4 0 1 1) labels("Sigma periodo" "N obs." "AIC" "BIC")) ///
    label nogaps compress nonotes nobaselevels ///
    title("Tabla APC (2a, robustez) - Cohortes teoricas, modelo binario (OR)")

esttab gob_lineal_teo parl_lineal_teo part_lineal_teo ffaa_lineal_teo igl_lineal_teo ///
    using "$AUXILIAR\tabla_2b_continua_robustez_teorica.rtf", replace ///
    b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
    mtitles("Gobierno" "Parlamento" "Partidos" "FF.AA." "Iglesia") ///
    stats(sigma_p N AIC BIC, fmt(4 0 1 1) labels("Sigma periodo" "N obs." "AIC" "BIC")) ///
    label nogaps compress nonotes nobaselevels ///
    title("Tabla APC (2b, robustez) - Cohortes teoricas, modelo lineal sobre z-score")

esttab gob_ord_teo parl_ord_teo part_ord_teo ffaa_ord_teo igl_ord_teo ///
    using "$AUXILIAR\tabla_2c_ordinal_robustez_teorica.rtf", replace ///
    eform b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
    mtitles("Gobierno" "Parlamento" "Partidos" "FF.AA." "Iglesia") ///
    stats(sigma_p N AIC BIC, fmt(4 0 1 1) labels("Sigma periodo" "N obs." "AIC" "BIC")) ///
    label nogaps compress nonotes nobaselevels ///
    title("Tabla APC (2c, robustez) - Cohortes teoricas, modelo ordinal (OR)")

// 4. gráficos de márgenes (cohorte / período / edad)
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

// la elección entre gráfico continuo y ordinal por institución sigue el
// diagnóstico de normalidad de la sección 5: continua donde la violación es
// leve (Gobierno/FF.AA./Iglesia), ordinal donde es seria (Parlamento/Partidos)
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

// 4B. gráficos de márgenes — cohortes teóricas
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

// 5. diagnóstico de normalidad
// con este N cualquier test formal de normalidad va a rechazar con p≈0 casi
// seguro — lo informativo es la magnitud de skewness/kurtosis, no el p-valor
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

// 6. tests de wald — fronteras (momento 2: dónde está el quiebre)
// tres encrucijadas de esquema de cohorte: importado, teórico-local, corte
// único; se testean en las tres especificaciones de DV
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
    file write `fh' `"`especificacion'"' "," `"`esquema'"' "," `"`institucion'"' "," ///
        `"`bloque'"' "," `"`tipo'"' "," `"`stattype'"' "," ///
        %9.3f (`stat') "," %3.0f (r(df)) "," %9.4f (r(p)) _n
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

        // esquema teórico local: reutiliza el modelo con cohort5 ya estimado
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

        // encrucijadas 1 y 3 (importada / balcells): modelo nuevo con cohort_check
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
        wald_row `fh_wald' "`spec'" "balcells" "`lbl'" "frontera plebiscito 1988 (1970/1971)" "frontera"
        quietly test 20004.cohort_check = 20003.cohort_check
        wald_row `fh_wald' "`spec'" "balcells" "`lbl'" "frontera retorno democracia 1990 (1972/1973)" "frontera"

        local ++i
    }
}

file close `fh_wald'

// 7. test de wald conjunto de cohorte (momento 1: ¿existe algún efecto?)
// réplica del chequeo global de Bargsted & Maldonado 2018, que ellos hacen
// con LR test. Acá se intentan las dos formas: LR (columnas chi2/df/p) y
// Wald conjunto (columnas wald_*). El LR sale con df muy por debajo de 13
// bajo vce(robust) en binaria/ordinal (hasta indefinido en dos casos) —
// no es un problema de dummies de cohorte omitidas (ver sección 8), es que
// `lrtest` usa e(rank), que en melogit/meologit con errores robustos no
// siempre coincide con el conteo simple de parámetros. El Wald conjunto no
// depende de e(rank) y da resultados estables — es el que conviene citar.
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

        quietly test 1945.cohort5 1950.cohort5 1955.cohort5 1960.cohort5 1965.cohort5 ///
            1970.cohort5 1975.cohort5 1980.cohort5 1985.cohort5 1990.cohort5 1995.cohort5 ///
            2000.cohort5 2005.cohort5
        local wald_chi2 = r(chi2)
        local wald_df   = r(df)
        local wald_p    = r(p)

        quietly `estcmd' `v'`dvsuf' age_s age_s2 mujer i.educ4 i.nse4 [pweight=ponderador] || year: `estopt'
        local ll_reducido = e(ll)
        estimates store modelo_reducido

        quietly lrtest `short'`sufmodelo' modelo_reducido, force

        file write `fh_m1' `"`spec'"' "," `"`lbl'"' "," %12.3f (`ll_full') "," %12.3f (`ll_reducido') "," ///
            %9.3f (r(chi2)) "," %3.0f (r(df)) "," %9.4f (r(p)) "," ///
            %9.3f (`wald_chi2') "," %3.0f (`wald_df') "," %9.4f (`wald_p') _n

        local ++i
    }
}
file close `fh_m1'

// 8. diagnóstico: ¿se caen dummies de cohorte por colinealidad?
// un coeficiente descartado por colinealidad queda como "cero estructural"
// (el "o." de la tabla de resultados) y sigue siendo testeable sin error —
// por eso se chequea el error estándar, no `test`. Sirvió para descartar
// que el problema de la sección 7 fuera dummies omitidos: no lo son.
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

// 9. forest plot — fronteras entre quinquenios consecutivos
// las 13 fronteras entre cada par de quinquenios, especificación ordinal,
// reutilizando los modelos ya estimados en la sección 2
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
      title("Fronteras entre quinquenios consecutivos", size(medium)) ///
      legend(order(1 "Gobierno" 2 "Parlamento" 3 "Partidos" 4 "FF.AA." 5 "Iglesia") rows(1) position(6) size(small)) ///
      graphregion(color(white)) xsize(10) ysize(9)
graph export "$PRINCIPAL\5_forest_encrucijadas.png", replace width(2400)
restore

// 10. tendencia temporal 2006-2025 (contexto descriptivo)
// proporción ponderada simple, sin ajustar por cohorte ni edad
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

twoway ///
    (connected prop anio if inst_id==1, mcolor(navy)    lcolor(navy)    msymbol(O)) ///
    (connected prop anio if inst_id==2, mcolor(maroon)  lcolor(maroon)  msymbol(D)) ///
    (connected prop anio if inst_id==3, mcolor(dkgreen) lcolor(dkgreen) msymbol(T)) ///
    (connected prop anio if inst_id==4, mcolor(orange)  lcolor(orange)  msymbol(S)) ///
    (connected prop anio if inst_id==5, mcolor(purple)  lcolor(purple)  msymbol(X)) ///
    , xtitle("Año de encuesta") ytitle("% que confía (top-2-box, ponderado)") ///
      title("Confianza institucional en Chile, 2006-2025", size(medium)) ///
      subtitle("Tendencia descriptiva simple, sin ajustar por cohorte ni edad", size(vsmall)) ///
      legend(order(1 "Gobierno" 2 "Parlamento" 3 "Partidos" 4 "FF.AA." 5 "Iglesia") rows(1) position(6) size(small)) ///
      graphregion(color(white)) xsize(10) ysize(6)
graph export "$PRINCIPAL\6_tendencia_temporal.png", replace width(2400)
restore

// 11. brecha estallido, escala z-score
tempname fh_estallido
tempfile margins_estallido
postfile `fh_estallido' byte inst_id byte post_estallido double b double ll double ul using "`margins_estallido'", replace

local i = 1
foreach v of local institutions {
    quietly mixed `v'_z age_s age_s2 i.post_estallido mujer i.educ4 i.nse4 [pweight=ponderador] || year:, mle vce(robust)
    quietly margins post_estallido
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

twoway (bar b xpos if post_estallido == 0, color(navy%70) barwidth(0.32)) ///
       (bar b xpos if post_estallido == 1, color(orange%70) barwidth(0.32)) ///
       (rcap ll ul xpos, lcolor(black)), ///
    xlabel(1 "Gobierno" 2 "Parlamento" 3 "Partidos" 4 "FF.AA." 5 "Iglesia", angle(0)) ///
    xtitle("") ytitle("Confianza (z-score por año)", size(small)) ///
    yline(0, lcolor(gs10) lpattern(dash)) ///
    title("Brecha generacional confirmada: pre- vs. post-estallido", size(medium)) ///
    subtitle("Única ruptura que sobrevive a las tres encrucijadas de cohortes testeadas", size(vsmall)) ///
    legend(order(1 "Nacidos antes de 1995" 2 "Generación del estallido (1995+)") rows(1) position(6) size(small)) ///
    graphregion(color(white)) xsize(9) ysize(6)
graph export "$PRINCIPAL\4_brecha_estallido.png", replace width(2400)
restore

// 12. brecha estallido, escala de probabilidad + test de significancia
tempname fh_estallido_p
tempfile margins_estallido_p
postfile `fh_estallido_p' byte inst_id byte post_estallido double b double ll double ul using "`margins_estallido_p'", replace

tempname fh_sig
file open `fh_sig' using "$PRINCIPAL\7_brecha_estallido_prob_pvalues.csv", write replace
file write `fh_sig' "institucion,chi2,p" _n

local i = 1
foreach v of local institutions {
    quietly meologit `v' age_s age_s2 i.post_estallido mujer i.educ4 i.nse4 [pweight=ponderador] || year:, or vce(robust)
    quietly test 1.post_estallido
    local lbl : word `i' of `labels'
    file write `fh_sig' `""`lbl'""' "," %9.3f (r(chi2)) "," %9.4f (r(p)) _n

    quietly margins post_estallido, expression(predict(pr outcome(4)) + predict(pr outcome(5)))
    matrix tab_est = r(table)
    forvalues c = 1/2 {
        post `fh_estallido_p' (`i') (`c' - 1) (tab_est[1,`c']) (tab_est[5,`c']) (tab_est[6,`c'])
    }
    local ++i
}
postclose `fh_estallido_p'
file close `fh_sig'

preserve
use "`margins_estallido_p'", clear
label define instlbl3 1 "Gobierno" 2 "Parlamento" 3 "Partidos" 4 "FF.AA." 5 "Iglesia"
label values inst_id instlbl3

gen xpos = inst_id + (post_estallido - 0.5) * 0.35

twoway (bar b xpos if post_estallido == 0, color(navy%70) barwidth(0.32)) ///
       (bar b xpos if post_estallido == 1, color(orange%70) barwidth(0.32)) ///
       (rcap ll ul xpos, lcolor(black)), ///
    xlabel(1 "Gobierno" 2 "Parlamento" 3 "Partidos" 4 "FF.AA." 5 "Iglesia", angle(0)) ///
    xtitle("") ytitle("P(confía) = P(Y=4)+P(Y=5)", size(small)) ///
    title("Brecha generacional confirmada: pre- vs. post-estallido", size(medium)) ///
    subtitle("Misma ruptura que la sección 11, en escala de probabilidad (modelo ordinal)", size(vsmall)) ///
    legend(order(1 "Nacidos antes de 1995" 2 "Generación del estallido (1995+)") rows(1) position(6) size(small)) ///
    graphregion(color(white)) xsize(9) ysize(6)
graph export "$PRINCIPAL\7_brecha_estallido_prob.png", replace width(2400)
restore

// 13. curva de especificaciones — las tres encrucijadas juntas
// specification curve (Simonsohn, Simmons & Nelson 2020) / multiverse
// analysis (Steegen et al. 2016): las 10 fronteras candidatas de las tres
// encrucijadas en una sola figura. No estima nada, solo grafica la sección 6.
// El (1)/(2)/(3) en cada etiqueta identifica el esquema, misma numeración
// que el README.
preserve
import delimited "$PRINCIPAL\tabla_4_wald_cohortes.csv", clear varnames(1) case(preserve)
keep if tipo == "frontera" & especificacion == "ordinal"

gen neglog10p = -log10(chi2tail(df, stat))

gen front_pos = .
replace front_pos = 1  if bloque == "frontera Silenciosa/Boomer (1945/1946)"
replace front_pos = 2  if bloque == "frontera 1-2 (1949/1950)"
replace front_pos = 3  if bloque == "frontera Boomer/X (1964/1965)"
replace front_pos = 4  if bloque == "frontera 2-3 (1964/1965)"
replace front_pos = 5  if bloque == "frontera plebiscito 1988 (1970/1971)"
replace front_pos = 6  if bloque == "frontera retorno democracia 1990 (1972/1973)"
replace front_pos = 7  if bloque == "frontera 3-4 (1979/1980)"
replace front_pos = 8  if bloque == "frontera X/Millennial (1980/1981)"
replace front_pos = 9  if bloque == "frontera 4-5 (1994/1995)"
replace front_pos = 10 if bloque == "frontera Millennial/Z (1996/1997)"

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
      ylabel(1 "Silenciosa / Boomer (1)" 2 "Pre-masificación educativa / Estado desarrollista (2)" 3 "Boomer / Generación X (1)" 4 "Estado desarrollista / Dictadura-transición (2)" 5 "Corte plebiscito 1988 (3)" 6 "Corte retorno a la democracia 1990 (3)" 7 "Dictadura-transición / Democracia neoliberal (2)" 8 "Generación X / Millennial (1)" 9 "Democracia neoliberal / Generación del estallido (2)" 10 "Millennial / Generación Z (1)", angle(0) labsize(vsmall)) ytitle("") ///
      xtitle("-log10(p), test de Wald (especificación ordinal)") ///
      title("Curva de especificaciones — fronteras de cohorte candidatas", size(medium)) ///
      legend(order(1 "Gobierno" 2 "Parlamento" 3 "Partidos" 4 "FF.AA." 5 "Iglesia") rows(1) position(6) size(small)) ///
      graphregion(color(white) margin(l=25)) plotregion(color(white)) xsize(13) ysize(7)
graph export "$PRINCIPAL\8_specification_curve.png", replace width(2400)
restore

// 14. gráfico del momento 1 — ¿existe algún efecto de cohorte?
// contraparte visual de la sección 7. Eje X en log10(chi2), no -log10(p):
// el chi2 de Partidos-ordinal es tan grande (53.880) que chi2tail() hace
// underflow a 0 y -log10(0) queda indefinido — con log10(chi2) no hay ese
// problema, y como las 15 combinaciones ya son p<0.0001, la magnitud
// relativa del chi2 es lo que aporta información acá, no el p exacto.
preserve
import delimited "$PRINCIPAL\lr_bargsted_maldonado.csv", clear varnames(1) case(preserve)

gen logchi2 = log10(wald_chi2)

gen spec_pos = .
replace spec_pos = 1 if especificacion == "binaria"
replace spec_pos = 2 if especificacion == "zscore"
replace spec_pos = 3 if especificacion == "ordinal"

gen spec_jit = spec_pos + cond(institucion=="Gobierno",-0.24, ///
    cond(institucion=="Parlamento",-0.12,cond(institucion=="Partidos",0, ///
    cond(institucion=="FF.AA.",0.12,0.24))))

twoway ///
    (scatter spec_jit logchi2 if institucion=="Gobierno",   mcolor(navy)    msymbol(O)) ///
    (scatter spec_jit logchi2 if institucion=="Parlamento", mcolor(maroon)  msymbol(D)) ///
    (scatter spec_jit logchi2 if institucion=="Partidos",   mcolor(dkgreen) msymbol(T)) ///
    (scatter spec_jit logchi2 if institucion=="FF.AA.",     mcolor(orange)  msymbol(S)) ///
    (scatter spec_jit logchi2 if institucion=="Iglesia",    mcolor(purple)  msymbol(X)) ///
    , ylabel(1 "Binaria (top-2)" 2 "Continua (z-score)" 3 "Ordinal completa", angle(0) labsize(small)) ytitle("") ///
      xtitle("log10(chi2), test de Wald conjunto sobre los 13 coeficientes de cohort5") ///
      title("¿Existe algún efecto de cohorte? (momento 1)", size(medium)) ///
      subtitle("Test de Wald conjunto, réplica del chequeo global de Bargsted & Maldonado (2018) — p<0.0001 en las 15 combinaciones", size(vsmall)) ///
      legend(order(1 "Gobierno" 2 "Parlamento" 3 "Partidos" 4 "FF.AA." 5 "Iglesia") rows(1) position(6) size(small)) ///
      note("Gobierno: df=12 en las tres especificaciones (colinealidad entre dos coeficientes de cohorte al testearlos juntos); resto en df=13.", size(vsmall)) ///
      graphregion(color(white) margin(l=15)) plotregion(color(white)) xsize(11) ysize(5.5)
graph export "$PRINCIPAL\9_wald_momento1_cohorte.png", replace width(2400)
restore

// 15. cobertura de variables (todas, no solo las DV)
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

    file write `fh_cob2' `""`lbl'""' "," (`ntot') "," (`olas_con_datos') "," (`n_olas_total') "," ///
        %9.2f (`vmin') "," %9.2f (`vmax') "," (`ncat') _n
    local ++i
}
file close `fh_cob2'

di as text _n "{hline 78}"
di as text "FIN DEL ANÁLISIS."
di as text "Principal -> $PRINCIPAL"
di as text "Auxiliar  -> $AUXILIAR"
di as text "{hline 78}"
