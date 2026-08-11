// ============================================================================
// DIAGNÓSTICO: ¿SE ESTÁN OMITIENDO DUMMIES DE COHORTE POR COLINEALIDAD?
// Confianza institucional y cohortes generacionales en Chile
// Bustamante & Quintero — Congreso Triada 2026
//
// Motivo: en lr_bargsted_maldonado.csv, el LR test de binaria y ordinal
// salió con df muy por debajo de 13 (el esperado con 14 categorías de
// cohort5), y en ordinal Parlamento y FF.AA. salió df=0 (p indefinido). En
// zscore salió limpio (df=13 en las 5). Eso sugiere que `melogit`/`meologit`
// están descartando automáticamente algunos de los 13 dummies de cohorte
// por colinealidad/separación perfecta en alguna celda cohorte×año — algo
// que no puede pasar en un modelo lineal (`mixed`), consistente con que
// solo se vea en binaria/ordinal.
//
// Este dofile re-estima el modelo COMPLETO (idéntico al de la Sección 2/6
// del dofile principal — mismo `i.cohort5 mujer i.educ4 i.nse4`, mismo
// pweight/vce(robust)) para las 5 instituciones × 3 especificaciones, y
// para cada uno prueba si cada uno de los 13 niveles de cohort5 (todos
// menos la base, ≤1944) sigue existiendo como coeficiente estimable
// (`test <nivel>.cohort5`). Si Stata lo descartó, ese `test` falla y se
// registra como "omitida". También cuenta cuántas observaciones caen en
// celdas cohorte×año sin ninguna variación en la DV (todo el mundo
// respondió lo mismo ahí) — la causa más probable de la separación.
//
// Importante: si esto confirma omisiones, el siguiente paso es revisar
// si alguna de esas cohortes omitidas coincide con las fronteras ya
// reportadas en Principal_NSE\tabla_4_wald_cohortes.csv (Sección 6 del
// dofile principal, misma especificación de modelo) — ese resultado
// podría estar comparando un coeficiente real contra uno fijado en 0 por
// colinealidad, sin que haya saltado ningún error visible.
//
// Do-file chico y AUTOCONTENIDO: 15 modelos (uno por institución×
// especificación, sin modelo reducido ni lrtest) — más rápido que
// lr_bargsted_maldonado.do.
// ============================================================================

global DATA      "C:\Users\gonza\Dropbox\Proyectos personales\02.- DATOS\Bicentenario\bicentenario_panel_armonizado.dta"
global AUXILIAR  "C:\Users\gonza\Dropbox\Proyectos personales\01.- Desarrollo investigación\Quintero, Bustamante\Análisis final\Auxiliar_NSE"


// ----------------------------------------------------------------------------
// Preparación de datos (idéntica a la Sección 1 del dofile principal)
// ----------------------------------------------------------------------------

use "$DATA", clear

gen int birthyear = year - edad
keep if birthyear >= 1930 & birthyear <= 2007
keep if edad >= 18 & edad <= 85

gen cohort5 = 5 * floor(birthyear / 5)
recode cohort5 (min/1944 = 1944)

gen age_s  = edad / 10
gen age_s2 = age_s^2
gen mujer  = (sexo == 2) if !missing(sexo)

foreach v in conf_gobierno conf_parlamento conf_partidos conf_ffaa conf_iglesia {
    replace `v' = . if inlist(`v', 6, 7)
    gen `v'_bin = (`v' >= 4) if !missing(`v')
    bys year: egen `v'_m = mean(`v')
    bys year: egen `v'_s = sd(`v')
    gen `v'_z = (`v' - `v'_m) / `v'_s
    drop `v'_m `v'_s
}

local institutions "conf_gobierno conf_parlamento conf_partidos conf_ffaa conf_iglesia"
local labels        `""Gobierno" "Parlamento" "Partidos" "FF.AA." "Iglesia""'
local niveles_cohort "1945 1950 1955 1960 1965 1970 1975 1980 1985 1990 1995 2000 2005"


// ============================================================================
// DIAGNÓSTICO POR INSTITUCIÓN × ESPECIFICACIÓN
// ============================================================================

tempname fh
file open `fh' using "$AUXILIAR\diagnostico_omitidas_cohort5.csv", write replace
file write `fh' "especificacion,institucion,n_omitidas,cohortes_omitidas,n_obs_celdas_degeneradas" _n

foreach spec in binaria zscore ordinal {

    if "`spec'" == "binaria" {
        local dvsuf  "_bin"
        local estcmd "melogit"
        local estopt ", or vce(robust)"
    }
    else if "`spec'" == "zscore" {
        local dvsuf  "_z"
        local estcmd "mixed"
        local estopt ", mle vce(robust)"
    }
    else {
        local dvsuf  ""
        local estcmd "meologit"
        local estopt ", or vce(robust)"
    }

    local i = 1
    foreach v of local institutions {
        local lbl : word `i' of `labels'
        di as text _n "{hline 70}"
        di as text "Diagnóstico | Especificación: `spec' | Institución: `lbl'"
        di as text "{hline 70}"

        capture quietly `estcmd' `v'`dvsuf' age_s age_s2 i.cohort5 mujer i.educ4 i.nse4 [pweight=ponderador] || year: `estopt'

        if _rc != 0 {
            di as error "  El modelo completo no convergió (rc=`=_rc')."
            file write `fh' `"`spec'"' "," `"`lbl'"' "," "." "," "ERROR_ESTIMACION" "," "." _n
            local ++i
            continue
        }

        // ¿Cuáles de los 13 niveles siguen existiendo como coeficiente?
        // NOTA (corregido): `test <nivel>.cohort5` NO sirve para detectar
        // esto -- un coeficiente omitido por colinealidad queda como "cero
        // estructural" (el "o." de la tabla de resultados) y sigue siendo
        // testeable sin error. La señal correcta es que su error estándar
        // queda fijado exactamente en 0 (un coeficiente estimado de verdad,
        // aunque no sea significativo, siempre tiene se > 0).
        local omitidas ""
        local n_omit = 0
        foreach lvl of local niveles_cohort {
            capture local se_lvl = _se[`lvl'.cohort5]
            if _rc != 0 | missing(`se_lvl') | `se_lvl' == 0 {
                local omitidas "`omitidas' `lvl'"
                local ++n_omit
            }
        }

        // Observaciones en celdas cohorte×año sin ninguna variación en la DV
        // (todo el mundo respondió exactamente lo mismo ahí) — causa más
        // probable de la separación/colinealidad.
        quietly bys cohort5 year: egen cellsd = sd(`v'`dvsuf')
        quietly count if cellsd == 0 & !missing(`v'`dvsuf')
        local n_degen = r(N)
        quietly drop cellsd

        di as text "  cohortes omitidas (`n_omit'/13): [`omitidas']"
        di as text "  obs. en celdas cohorte×año degeneradas: `n_degen'"

        file write `fh' `"`spec'"' "," `"`lbl'"' "," (`n_omit') "," `"`omitidas'"' "," (`n_degen') _n

        local ++i
    }
}

file close `fh'

di as text _n "{hline 78}"
di as text "LISTO — diagnostico_omitidas_cohort5.csv en Auxiliar_NSE."
di as text "Si n_omitidas > 0 en algún institución×especificación, revisar si"
di as text "esas cohortes coinciden con fronteras ya reportadas en"
di as text "Principal_NSE\tabla_4_wald_cohortes.csv (Sección 6 del dofile"
di as text "principal) — esos resultados podrían estar comparando un"
di as text "coeficiente real contra uno fijado en 0 por colinealidad."
di as text "{hline 78}"
