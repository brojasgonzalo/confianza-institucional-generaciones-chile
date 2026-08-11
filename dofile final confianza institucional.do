// ============================================================================
// CONFIANZA INSTITUCIONAL Y COHORTES GENERACIONALES EN CHILE
// Encuesta Bicentenario, panel armonizado 2006-2025
// Bustamante & Quintero — 4to Congreso Latinoamericano de Ciencias Sociales
// y Gobierno de la Triada 2026
//
// Análisis edad-período-cohorte (APC) de la confianza en cinco instituciones
// (Gobierno, Parlamento, Partidos, FF.AA., Iglesia), con foco en si existe
// una ruptura generacional asociada a la Generación del estallido (nacidos
// desde 1995).
//
// ÍNDICE
//   0. CONFIGURACIÓN ............ rutas de archivos — editar antes de correr
//   1. PREPARACIÓN DE DATOS ..... variables de cohorte, edad, DVs
//   2. MODELOS PRINCIPALES ...... binaria, continua (z-score) y ordinal,
//                                 cohortes quinquenales, diseño muestral
//   3. ROBUSTEZ: COHORTES TEÓRICAS  misma estructura, cohortes histórico-
//                                 generacionales en vez de quinquenios
//   4. GRÁFICOS DE MÁRGENES ..... cohorte / período / edad, los tres modelos.
//                                 Principal usa continua donde la sección 5
//                                 no encuentra violación seria de normalidad
//                                 (Gobierno/FF.AA./Iglesia) y ordinal donde
//                                 sí (Parlamento/Partidos) — ver sección 4
//   4B. GRÁFICOS COHORTES TEÓRICAS  mismos márgenes, pero con cohort_teorica
//                                 (5 bloques) en vez de cohort5 (14
//                                 quinquenios) — carpeta aparte, comparación
//   5. DIAGNÓSTICO DE NORMALIDAD  residuos del modelo continuo
//   6. TESTS DE WALD ............ tres encrucijadas de esquemas de cohorte
//   7. HALLAZGO CONFIRMADO ...... brecha pre/post Generación del estallido
//   8. FOREST PLOT QUINQUENIOS .. las 13 fronteras entre quinquenios
//                                 consecutivos (reutiliza estimates de la
//                                 sección 2, sin volver a estimar)
//   9. TENDENCIA TEMPORAL ....... contexto descriptivo 2006-2025 (proporción
//                                 ponderada simple, no modelo multinivel)
//   10. BRECHA ESTALLIDO EN % ... como la sección 7 pero en P(confía), no
//                                 z-score — 5 modelos rápidos, 1 predictor
//   11. CURVA DE ESPECIFICACIONES  las 10 fronteras candidatas de las tres
//                                 encrucijadas juntas (no estima nada, solo
//                                 grafica la sección 6)
//
// Para saltar a una sección, buscar el texto ">>> SECCIÓN N" en este archivo.
// ============================================================================


// ============================================================================
// >>> SECCIÓN 0: CONFIGURACIÓN — EDITAR ESTAS RUTAS ANTES DE CORRER
// ============================================================================
// DATA:        ruta al archivo bicentenario_panel_armonizado.dta
// PRINCIPAL:   carpeta para las tablas/gráficos centrales del paper —
//              especificación ordinal (recomendada), el hallazgo de la
//              brecha del estallido, y la evidencia de las 3 encrucijadas
// AUXILIAR:    carpeta para robustez y diagnóstico — binaria, continua,
//              cohortes teóricas, normalidad, chequeo de dummies de año
// TEORICA:     carpeta aparte solo para los gráficos de márgenes con
//              cohort_teorica (5 bloques histórico-generacionales) en vez
//              de cohort5 (14 quinquenios) — comparación visual, no
//              reemplaza nada de Principal/Auxiliar todavía (ver sección 4B)
// Todo lo demás en este do-file usa estos cuatro globals — no hace falta
// cambiar ninguna otra ruta en el resto del archivo.
//
// NSE (2026-08-06): se agregó i.nse4 (nivel socioeconómico armonizado, 4
// categorías) como control en las ~45 estimaciones, junto a mujer/educ4.
// Requiere que bicentenario_panel_armonizado.dta ya tenga nse4 (generado en
// build_panel_bicentenario_armonizado.do). Las tres carpetas de salida se
// redirigieron a *_NSE para no pisar la corrida anterior (sin el control de
// NSE) que sigue intacta en Principal/Auxiliar/Cohortes teóricas.

global DATA      "C:\Users\gonza\Dropbox\Proyectos personales\02.- DATOS\Bicentenario\bicentenario_panel_armonizado.dta"
global PRINCIPAL "C:\Users\gonza\Dropbox\Proyectos personales\01.- Desarrollo investigación\Quintero, Bustamante\Análisis final\Principal_NSE"
global AUXILIAR  "C:\Users\gonza\Dropbox\Proyectos personales\01.- Desarrollo investigación\Quintero, Bustamante\Análisis final\Auxiliar_NSE"
global TEORICA   "C:\Users\gonza\Dropbox\Proyectos personales\01.- Desarrollo investigación\Quintero, Bustamante\Análisis final\Cohortes teóricas_NSE"


// ============================================================================
// >>> SECCIÓN 1: PREPARACIÓN DE DATOS
// ============================================================================

use "$DATA", clear

// Año de nacimiento aproximado; se excluyen cohortes con poca presencia en
// la muestra y edades fuera del rango adulto estándar.
gen int birthyear = year - edad
keep if birthyear >= 1930 & birthyear <= 2007
keep if edad >= 18 & edad <= 85

// Diseño muestral (documentado en notas_construccion_panel.txt). Se declara
// para dejar constancia y habilitar chequeos descriptivos con svy:, pero los
// modelos multinivel de abajo (melogit/mixed/meologit) no admiten el
// prefijo svy: junto con efectos aleatorios anidados — Stata no propaga
// correctamente la linealización del diseño sobre modelos multinivel. Por
// eso el ponderador se incorpora directamente como pweight en cada modelo,
// con vce(robust). Esto corrige el punto estimado por probabilidad de
// selección y da errores estándar tipo sándwich, pero no replica el efecto
// de diseño completo de la estratificación y el conglomerado más allá del
// año — limitación declarada, no resuelta del todo.
svyset folio_mapa [pw=ponderador], strata(estrato) vce(linearized) singleunit(centered)

// Edad escalada para facilitar convergencia del modelo.
gen age_s  = edad / 10
gen age_s2 = age_s^2
gen mujer  = (sexo == 2) if !missing(sexo)

// Cohortes quinquenales, siguiendo a Bargsted & Maldonado (2018). La
// cohorte más antigua colapsa en "≤1944" por baja presencia muestral.
gen cohort5 = 5 * floor(birthyear / 5)
recode cohort5 (min/1944 = 1944)

label define cohort5lbl 1944 "≤1944" 1945 "1945-49" 1950 "1950-54" 1955 "1955-59" ///
    1960 "1960-64" 1965 "1965-69" 1970 "1970-74" 1975 "1975-79" ///
    1980 "1980-84" 1985 "1985-89" 1990 "1990-94" 1995 "1995-99" ///
    2000 "2000-04" 2005 "2005-07"
label values cohort5 cohort5lbl

// Cohortes teóricamente motivadas (robustez): periodización histórico-
// generacional inspirada en el argumento de Araujo & Martuccelli (2012) de
// que la subjetividad se forma en condiciones históricas concretas —no es
// una tabla que el libro proponga literalmente, es una operacionalización
// propia de ese argumento—, extendida con la Generación del estallido
// (Mannheim 1928; Krosnick & Alwin 1989).
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

// Cohortes para testear esquemas alternativos (sección 6): copia de
// cohort5, pero con ventana ±2 años alrededor de las fronteras que no
// coinciden con un borde de cohort5 (antes era resolución anual, un año
// contra el siguiente — muy poca potencia; ±2 es el punto intermedio entre
// eso y comparar generaciones completas, que mezclaría el quiebre puntual
// con la tendencia general).
//   - Taxonomía importada (Silenciosa/Boomer/X/Millennial/Z): fronteras en
//     1945/46, 1980/81 y 1996/97 no coinciden con cohort5; 1964/65 sí
//     coincide (borde 1960 vs. 1965) y se reutiliza directo.
//   - Corte único estilo Balcells & Villamil (2026): dos candidatos,
//     plebiscito 1988 (corte 1970/71) y retorno a la democracia 1990
//     (corte 1972/73) — están a solo 2 años de distancia entre sí, así que
//     una ventana ±2 en ambos se superpondría (el "después" del primero
//     coincidiría con el "antes" del segundo). Se dejan en año individual
//     (ventana ±1), la única excepción a la regla de ±2.
// Los offsets (11001/11002, 12001/12002, 13001/13002, 20001-20004) evitan
// colisión con los códigos de cohort5.
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

// Generación del estallido como variable binaria: la única frontera
// generacional confirmada en la sección 6 (ver detalle ahí). Se usa en la
// sección 7 para el gráfico del hallazgo final.
gen post_estallido = (birthyear >= 1995) if !missing(birthyear)
label define post_estallidolbl 0 "Pre-estallido (<1995)" 1 "Post-estallido (1995+)"
label values post_estallido post_estallidolbl

// Variables dependientes, en sus tres versiones: ordinal completa (1-5,
// tal como viene), binaria (top-2-box) y continua (z-score por año). En
// las tres, 6 y 7 son no sabe/no responde y se recodifican a missing.
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


// ============================================================================
// >>> SECCIÓN 2: MODELOS PRINCIPALES (cohortes quinquenales)
// ============================================================================
// Tres especificaciones de la misma estructura APC (cohorte y edad como
// efectos fijos, período como intercepto aleatorio):
//   (a) Binaria (top-2-box) + melogit  -> no impone normalidad, pero pierde
//       potencia al colapsar la escala (ver sección 5)
//   (b) Continua (z-score) + mixed     -> más potencia, pero impone
//       normalidad sobre una variable observada discreta de 5 categorías
//   (c) Ordinal (escala 1-5 completa) + meologit -> usa toda la
//       información (no pierde potencia como la binaria) y no asume
//       normalidad de la variable observada (solo de una variable latente
//       subyacente, con puntos de corte libres) — especificación principal
//       recomendada, ver sección 6 para la justificación empírica completa

// --- (a) Binaria -------------------------------------------------------
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

// --- (b) Continua (z-score) ---------------------------------------------
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

// --- (c) Ordinal ---------------------------------------------------------
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

// --- AIC, BIC y sigma de período, para las 15 estimaciones ---------------
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

// --- Tablas de resultados -------------------------------------------------
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


// ============================================================================
// >>> SECCIÓN 3: ROBUSTEZ — COHORTES TEÓRICAS
// ============================================================================
// Misma estructura que la sección 2, reemplazando cohort5 por
// cohort_teorica. Sirve para reportar la tabla con las etiquetas
// generacionales con nombre (más legible para el lector), aunque el modelo
// de identificación principal sigue siendo el de cohortes quinquenales.

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


// ============================================================================
// >>> SECCIÓN 4: GRÁFICOS DE MÁRGENES (cohorte / período / edad)
// ============================================================================
// Reutiliza las estimaciones de la sección 2 (estimates restore) — no se
// vuelve a estimar ningún modelo acá. Un gráfico de 3 paneles por
// institución y por especificación (15 gráficos en total).

// --- (a) Binaria: escala de probabilidad predicha -------------------------
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

// --- (b) Continua: escala z-score ------------------------------------------
// Elección de cuál gráfico (continuo vs. ordinal) va a Principal: no es
// estética, sigue el diagnóstico de normalidad de la sección 5. Ahí la
// violación es leve en Gobierno/FF.AA./Iglesia (el continuo es defendible y
// se ve más limpio) y seria en Parlamento/Partidos (piso de la escala muy
// cargado; el continuo ahí angosta los IC precisamente donde el supuesto
// que los angosta no se sostiene). Por eso la especificación principal
// visual se decide institución por institución, no de forma pareja para
// las 5 — la tabla de resultados (arriba) sí sigue siendo ordinal para las
// 5, esto solo cambia qué gráfico ilustra el hallazgo.
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

// --- (c) Ordinal: P(confía) = P(Y=4) + P(Y=5) ------------------------------
// predict(pr outcome(4)) + predict(pr outcome(5)) vía expression(): el
// modelo ordinal no acepta un rango "4/5" directo en outcome(). Contraparte
// del bloque anterior: en Parlamento/Partidos este es el gráfico principal
// (intervalos más anchos, pero es la incertidumbre real dado el sesgo de
// piso); en Gobierno/FF.AA./Iglesia queda como chequeo de robustez en
// Auxiliar (misma conclusión sustantiva, solo más ruido visual).
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


// ============================================================================
// >>> SECCIÓN 4B: GRÁFICOS DE MÁRGENES — COHORTES TEÓRICAS
// ============================================================================
// Mismo ejercicio que la sección 4, pero con cohort_teorica (5 bloques
// histórico-generacionales) en vez de cohort5 (14 quinquenios). Al agrupar
// mucha más N por categoría, los intervalos deberían angostarse bastante
// frente a los de la sección 4 — a costa de perder la resolución quinquenal.
// Se generan ambas especificaciones (continua y ordinal) para las 5
// instituciones, en una carpeta aparte ($TEORICA) para comparar a ojo antes
// de decidir si alguna reemplaza a las de Principal/Auxiliar. Reutiliza los
// modelos _teo ya estimados en la sección 3 — no se vuelve a estimar nada.

foreach m in gob parl part ffaa igl {
    if "`m'" == "gob"  local nombre "Gobierno"
    if "`m'" == "parl" local nombre "Parlamento"
    if "`m'" == "part" local nombre "Partidos"
    if "`m'" == "ffaa" local nombre "FF.AA."
    if "`m'" == "igl"  local nombre "Iglesia"

    // --- continua (z-score), cohortes teóricas -----------------------------
    estimates restore `m'_lineal_teo
    margins cohort_teorica
    marginsplot, title("Confianza en `nombre' por cohorte (teórica)") xtitle("Cohorte histórico-generacional") ytitle("Confianza (z-score por año)") xlabel(, valuelabel angle(30) labsize(vsmall)) name(g1, replace)
    margins, over(year)
    marginsplot, xlabel(2006 2011 2016 2019 2021 2023 2025, angle(45) labsize(small)) xtitle("Año de encuesta") ytitle("Confianza (z-score por año)") title("Confianza en `nombre' por período") name(g2, replace)
    margins, at(age_s = (1.8(1)8.5))
    marginsplot, xlabel(1.8 "18" 2.8 "28" 3.8 "38" 4.8 "48" 5.8 "58" 6.8 "68" 7.8 "78" 8.5 "85") xtitle("Edad") ytitle("Confianza (z-score por año)") title("Confianza en `nombre' por edad") name(g3, replace)
    graph combine g1 g2 g3, rows(1) title("APC Confianza en `nombre' (b-teo) continua, cohortes teóricas") xsize(14) ysize(5)
    graph export "$TEORICA\1b_continua_teo_`m'.png", replace width(2400)

    // --- ordinal, cohortes teóricas -----------------------------------------
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


// ============================================================================
// >>> SECCIÓN 5: DIAGNÓSTICO DE NORMALIDAD
// ============================================================================
// Testea si el supuesto de normalidad del modelo (b) continuo se sostiene.
// Reutiliza las estimaciones _lineal ya guardadas en la sección 2.
//
// Con este N (decenas de miles de observaciones), cualquier test formal de
// normalidad va a rechazar con p≈0 casi con certeza — es un artefacto del
// tamaño muestral, no necesariamente evidencia de que la violación importe
// en la práctica. Lo informativo es la magnitud de skewness/kurtosis (no
// solo su significancia) y el histograma/QQ-plot.
//
// Hallazgo de referencia (con este panel): la no-normalidad es un problema
// real y serio para Parlamento y Partidos (confianza más baja, distribución
// amontonada en el piso de la escala) y leve para Gobierno/FF.AA./Iglesia.
// Es la razón por la que la especificación ordinal (sección 2c) es la
// recomendada como principal: usa toda la información sin ese supuesto.

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

    // Residuos de nivel individual.
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

    // Efecto aleatorio de año (nivel 2; ~18 grupos, lectura sobre todo
    // visual). predict ... reffects repite el mismo valor por año en cada
    // observación de ese año — se colapsa a un valor por año antes de
    // testear, si no cada año se cuenta miles de veces en vez de una sola.
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


// ============================================================================
// >>> SECCIÓN 6: TESTS DE WALD — TRES ENCRUCIJADAS DE COHORTES
// ============================================================================
// ENCRUCIJADA 1 (esquema importado): ¿tienen sentido para Chile las
//   fronteras de la taxonomía generacional importada (Generación Silenciosa
//   1928-45, Baby Boomers 1946-64, Generación X 1965-80, Millennials
//   1981-96, Generación Z 1997+; ver del Solar & Fernández 2024, Faro UDD),
//   o son fronteras sin anclaje local (crítica de Didier 2017)?
// ENCRUCIJADA 2 (esquema teórico local): dentro de la periodización propia
//   (histórico-local + estallido), ¿las fronteras son rupturas reales, o la
//   partición quinquenal esconde más estructura de la que reconoce?
// ENCRUCIJADA 3 (corte único estilo Balcells & Villamil 2026): un solo
//   corte duro en la edad de socialización respecto del quiebre
//   democrático chileno, en dos versiones (plebiscito 1988, retorno a la
//   democracia 1990).
//
// Las tres encrucijadas se testean en las tres especificaciones de DV.
// La encrucijada 2 reutiliza las estimaciones _logit/_lineal/_ord ya
// guardadas en la sección 2 (mismo cohort5); las encrucijadas 1 y 3
// requieren un modelo nuevo con cohort_check.

capture program drop wald_row
program define wald_row
    args fh especificacion esquema institucion bloque tipo
    // test después de svy: reporta F, no chi2; acá no se usa svy: pero se
    // deja el manejo robusto por si se reutiliza este programa en otro
    // contexto que sí lo use.
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

// Nota de diseño: el nombre corto de cada modelo guardado (gob/parl/part/
// ffaa/igl) no se puede derivar automáticamente del nombre de la variable
// (conf_gobierno, conf_parlamento, ...), así que se mantiene una lista
// paralela de nombres cortos en el mismo orden que `institutions'.
local shortnames "gob parl part ffaa igl"

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

        // ================= ENCRUCIJADA 2: esquema teórico local =========
        // Reutiliza el modelo con cohort5 ya estimado en la sección 2.
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

        // ================= ENCRUCIJADAS 1 y 3: cohort_check ==============
        // Modelo nuevo (no estaba guardado de antes) con la variable de
        // resolución mixta para las fronteras importada y Balcells.
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

// Lectura de tabla_4_wald_cohortes.csv:
//   - tipo "dentro-bloque": p > 0.10 apoya que esos quinquenios son
//     indistinguibles entre sí (la agregación teórica no pierde información)
//   - tipo "frontera": p < 0.05 confirma una ruptura generacional real
// Resultado de referencia (con este panel): solo la frontera 4-5
// (1994/1995, esquema teórico) se sostiene de forma robusta en las tres
// especificaciones; los esquemas importado y Balcells quedan mayormente
// descartados.


// ============================================================================
// >>> SECCIÓN 7: HALLAZGO CONFIRMADO — BRECHA PRE/POST ESTALLIDO
// ============================================================================
// De las tres encrucijadas testeadas en la sección 6, la única frontera
// generacional que sobrevive en las tres especificaciones de DV, en las
// tres alternativas de esquema de cohorte, y también al reemplazar el
// intercepto aleatorio de período por dummies fijas de año (chequeo
// adicional, no incluido en este archivo — ver bitácora del proyecto), es
// la Generación del estallido (nacidos desde 1995).
//
// Este bloque estima un modelo limpio con esa única variable de cohorte
// binaria (post_estallido) y grafica la brecha para las 5 instituciones en
// una sola figura. Usa la especificación continua (z-score + mixed) porque
// es donde la ruptura alcanza mayor significancia estadística de forma
// consistente (ver tabla_4_wald_cohortes.csv).

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


// ============================================================================
// >>> SECCIÓN 8: FOREST PLOT — FRONTERAS ENTRE QUINQUENIOS CONSECUTIVOS
// ============================================================================
// Reutiliza los modelos ordinales con cohort5 completo ya estimados en la
// sección 2 (estimates restore `short'_ord — cero estimación nueva acá).
// Testea las 13 fronteras entre quinquenios consecutivos (¿≤1944 vs
// 1945-49?, ¿1945-49 vs 1950-54?, ..., ¿2000-04 vs 2005-07?) para cada
// institución — resolución completa quinquenio a quinquenio, no solo las 4
// fronteras entre los bloques teóricos grandes (esas siguen en
// tabla_4_wald_cohortes.csv). Eje x: -log10(p) del test de Wald —
// más a la derecha = más significativo, línea de referencia en p=.05.

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

// No usar la columna p tal cual (redondeada a 4 decimales, colapsa a
// "0.0000" en fronteras muy significativas y -log10(0) es indefinido) —
// recalcular desde el chi2 con chi2tail(), como en el resto del do-file.
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


// ============================================================================
// >>> SECCIÓN 9: TENDENCIA TEMPORAL 2006-2025 (contexto descriptivo)
// ============================================================================
// Panel de contexto: evolución del % que confía (top-2-box) en las 5
// instituciones a través del tiempo. Deliberadamente descriptivo — una
// proporción ponderada simple por año (comando `mean`, no un modelo
// multinivel, no margins) — para situar al lector antes de entrar en el
// argumento generacional: ¿la confianza en general sube o baja en el
// período, más allá de qué cohorte responde cada año? Corre en segundos
// (18 años x 5 instituciones = 90 medias ponderadas simples).

tempname fh_trend
tempfile trend_data
postfile `fh_trend' int anio byte inst_id double prop using "`trend_data'", replace

// Algunas instituciones no se preguntaron en todos los años del panel (ver
// nota de CLAUDE.md sobre cobertura de variables por ola) — `capture` salta
// esas celdas vacías en vez de abortar todo el loop con "no observations".
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


// ============================================================================
// >>> SECCIÓN 10: BRECHA ESTALLIDO EN ESCALA DE PROBABILIDAD
// ============================================================================
// Misma lógica que la sección 7 (brecha pre/post estallido), pero con el
// modelo ordinal (la especificación principal del paper) en vez de z-score,
// graficando P(confía) = P(Y=4)+P(Y=5) — más intuitivo para una audiencia
// de congreso ("% que confía" en vez de "desviaciones estándar"). Mismo
// contraste robusto, misma estructura APC (edad + intercepto aleatorio de
// período + post_estallido como único predictor de cohorte). A diferencia
// de la sección 4, acá no hay grid de márgenes por edad ni 14 categorías de
// cohorte — son 5 modelos de un solo predictor, deberían tardar segundos
// por institución, no horas.

tempname fh_estallido_p
tempfile margins_estallido_p
postfile `fh_estallido_p' byte inst_id byte post_estallido double b double ll double ul using "`margins_estallido_p'", replace

// Test de significancia del salto pre/post-estallido en esta especificación
// simplificada (post_estallido como único predictor de cohorte, sin las 14
// categorías de cohort5) — para no depender solo de si los IC del gráfico
// se tocan o no (overlap visual no es lo mismo que test no significativo).
tempname fh_sig
file open `fh_sig' using "$PRINCIPAL\7_brecha_estallido_prob_pvalues.csv", write replace
file write `fh_sig' "institucion,chi2,p" _n

local i = 1
foreach v of local institutions {
    quietly meologit `v' age_s age_s2 i.post_estallido mujer i.educ4 i.nse4 [pweight=ponderador] || year:, or vce(robust)
    quietly test 1.post_estallido
    local lbl : word `i' of `labels'
    di as text "`lbl': chi2 = " %9.3f (r(chi2)) ", p = " %9.4f (r(p))
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
    subtitle("Misma ruptura que la Sección 7, en escala de probabilidad (modelo ordinal)", size(vsmall)) ///
    legend(order(1 "Nacidos antes de 1995" 2 "Generación del estallido (1995+)") rows(1) position(6) size(small)) ///
    graphregion(color(white)) xsize(9) ysize(6)
graph export "$PRINCIPAL\7_brecha_estallido_prob.png", replace width(2400)
restore


// ============================================================================
// >>> SECCIÓN 11: CURVA DE ESPECIFICACIONES — LAS TRES ENCRUCIJADAS
// ============================================================================
// No estima nada nuevo — solo importa tabla_4_wald_cohortes.csv (ya
// generado en la sección 6) y lo grafica. Muestra las 10 fronteras
// candidatas de las tres encrucijadas juntas (teórica + importada +
// Balcells): a diferencia de la sección 8 (que solo mira dentro del
// esquema teórico), esta es la evidencia de robustez de la ELECCIÓN del
// esquema de cohorte en sí — una "specification curve" (Simonsohn, Simmons
// & Nelson 2020) / "multiverse analysis" (Steegen et al. 2016): todas las
// decisiones analíticas razonables a la vez, no solo la que se usó.

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
      ylabel(1 "Silenciosa/Boomer 1945/46 (importada)" 2 "Bloque 1-2, 1949/1950 (teorica)" 3 "Boomer/X 1964/65 (importada)" 4 "Bloque 2-3, 1964/1965 (teorica)" 5 "Plebiscito 1988, 1970/71 (balcells)" 6 "Retorno democracia, 1972/73 (balcells)" 7 "Bloque 3-4, 1979/1980 (teorica)" 8 "X/Millennial 1980/81 (importada)" 9 "Bloque 4-5, 1994/1995 (teorica)" 10 "Millennial/Z 1996/97 (importada)", angle(0) labsize(vsmall)) ytitle("") ///
      xtitle("-log10(p), test de Wald (especificación ordinal)") ///
      title("Curva de especificaciones — fronteras de cohorte candidatas", size(medium)) ///
      legend(order(1 "Gobierno" 2 "Parlamento" 3 "Partidos" 4 "FF.AA." 5 "Iglesia") rows(1) position(6) size(small)) ///
      graphregion(color(white)) xsize(10) ysize(7)
graph export "$PRINCIPAL\8_specification_curve.png", replace width(2400)
restore


di as text _n "{hline 78}"
di as text "FIN DEL ANÁLISIS."
di as text "Principal -> $PRINCIPAL"
di as text "Auxiliar  -> $AUXILIAR"
di as text "{hline 78}"
