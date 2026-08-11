// ============================================================================
// TEST DE BARGSTED & MALDONADO (2018): SIGNIFICANCIA GLOBAL DEL BLOQUE DE
// COHORTE, VÍA RAZÓN DE VEROSIMILITUD (LR)
// Confianza institucional y cohortes generacionales en Chile
// Bustamante & Quintero — Congreso Triada 2026
//
// Bargsted & Maldonado (2018, JPLA), la fuente del esquema quinquenal y de
// la especificación edad/cohorte-fijos + período-aleatorio que usamos (ver
// README.md, "Especificación metodológica"), testean si el bloque COMPLETO
// de dummies de cohorte aporta algo comparando (LR test) el modelo completo
// contra un modelo anidado que elimina TODOS los dummies de cohorte a la
// vez, dejando edad, período y controles (p. 48: χ²=24.5, df=14, p=0.04).
//
// Es una pregunta distinta a la de nuestros tests de Wald (Sección 6 del
// dofile principal, tabla_4_wald_cohortes.csv): esos preguntan "¿dónde está
// exactamente la ruptura?" (punto a punto, quinquenio por quinquenio o
// bloque por bloque). Este dofile pregunta lo más básico posible: "¿existe
// *algún* efecto de cohorte, aunque sea uno solo?" — si esto fallara en
// alguna especificación, sería motivo de alarma para toda la sección de
// fronteras, porque no tendría sentido buscar UNA frontera específica en un
// bloque que ni siquiera es conjuntamente significativo.
//
// Nota metodológica — por qué esto es una aproximación, no un test exacto:
// Bargsted & Maldonado no usan pweight/vce(robust) en su tabla principal, así
// que su LR test es el clásico, sin ajuste. Nuestros modelos sí usan pweight
// + vce(robust) en todos los modelos multinivel (ver README.md, "diseño
// muestral"), lo que técnicamente invalida el supuesto de referencia
// asintótica chi-cuadrado del LR test bajo el que se construyó ese test. El
// log-likelihood en sí NO cambia con vce(robust) — vce(robust) solo ajusta
// los errores estándar reportados, no el punto estimado ni la verosimilitud
// — así que el estadístico LR es el mismo número que se obtendría sin
// vce(robust); lo que se pierde es la garantía teórica de que ese número se
// distribuya exactamente chi-cuadrado bajo la especificación robusta. Stata
// se niega a correr `lrtest` en este caso salvo que se fuerce con la opción
// `force`; se usa acá, y el resultado debe leerse como una aproximación
// informal (igual que el resto de los tests de este proyecto bajo
// vce(robust) — ver la nota de diseño en la Sección 1 del dofile principal),
// no como un test exacto.
//
// Es un do-file chico y AUTOCONTENIDO: corre completo de una sola vez.
// Estima 30 modelos nuevos (2 por institución × 3 especificaciones: completo
// y reducido), cada uno sin ningún grid de márgenes — nada parecido a la
// Sección 4 del dofile principal. Debería tardar varios minutos, no horas.
// ============================================================================

global DATA      "C:\Users\gonza\Dropbox\Proyectos personales\02.- DATOS\Bicentenario\bicentenario_panel_armonizado.dta"
global PRINCIPAL "C:\Users\gonza\Dropbox\Proyectos personales\01.- Desarrollo investigación\Quintero, Bustamante\Análisis final\Principal_NSE"


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


// ============================================================================
// TEST LR: MODELO COMPLETO (con i.cohort5) VS. MODELO REDUCIDO (sin cohorte)
// ============================================================================

// ACTUALIZACIÓN (2026-08-11): se agregó un test de Wald conjunto sobre los
// 13 coeficientes de cohort5 (columnas wald_*), calculado sobre el mismo
// modelo_full, como alternativa al LR test. Motivo: en binaria y ordinal el
// LR test salió con df muy por debajo de 13 (hasta df=0, p indefinido en
// Parlamento/FF.AA. ordinal). Se descartó que fuera por dummies de cohorte
// omitidos por colinealidad (ver diagnostico_omitidas_cohort5.do — 0
// omitidas en las 15 combinaciones, con dos chequeos distintos). La causa
// más probable es que `lrtest` bajo vce(robust) usa e(rank), que en
// melogit/meologit puede no coincidir con el conteo simple de parámetros —
// una rareza de cómputo del LR test bajo errores robustos, no un problema
// de los datos ni del modelo. El test de Wald conjunto no depende de
// e(rank) (usa directamente el vector de coeficientes y su matriz de
// varianzas robusta, igual que el resto de los tests de la Sección 6), así
// que no tiene ese problema: se mantiene en df=13 siempre. Se dejan ambos
// resultados en el csv para que quede documentada la discrepancia.

tempname fh
file open `fh' using "$PRINCIPAL\lr_bargsted_maldonado.csv", write replace
file write `fh' "especificacion,institucion,ll_full,ll_reducido,chi2,df,p,wald_chi2,wald_df,wald_p" _n

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
        di as text "LR test Bargsted-Maldonado | Especificación: `spec' | Institución: `lbl'"
        di as text "{hline 70}"

        // Modelo completo: igual a la Sección 2 del dofile principal.
        quietly `estcmd' `v'`dvsuf' age_s age_s2 i.cohort5 mujer i.educ4 i.nse4 [pweight=ponderador] || year: `estopt'
        local ll_full = e(ll)
        estimates store modelo_full

        // Test de Wald conjunto sobre los 13 coeficientes de cohort5, en el
        // modelo_full recién estimado (antes de que el modelo reducido pise
        // los resultados activos en e()). No depende de e(rank).
        quietly test 1945.cohort5 1950.cohort5 1955.cohort5 1960.cohort5 1965.cohort5 ///
            1970.cohort5 1975.cohort5 1980.cohort5 1985.cohort5 1990.cohort5 1995.cohort5 ///
            2000.cohort5 2005.cohort5
        local wald_chi2 = r(chi2)
        local wald_df   = r(df)
        local wald_p    = r(p)

        // Modelo reducido: idéntico, pero sin ningún dummy de cohorte.
        quietly `estcmd' `v'`dvsuf' age_s age_s2 mujer i.educ4 i.nse4 [pweight=ponderador] || year: `estopt'
        local ll_reducido = e(ll)
        estimates store modelo_reducido

        quietly lrtest modelo_full modelo_reducido, force

        di as text "  LR:   chi2=" %9.3f (r(chi2)) " df=" %3.0f (r(df)) " p=" %9.4f (r(p))
        di as text "  Wald: chi2=" %9.3f (`wald_chi2') " df=" %3.0f (`wald_df') " p=" %9.4f (`wald_p')

        file write `fh' `"`spec'"' "," `"`lbl'"' "," %12.3f (`ll_full') "," %12.3f (`ll_reducido') "," ///
            %9.3f (r(chi2)) "," %3.0f (r(df)) "," %9.4f (r(p)) "," ///
            %9.3f (`wald_chi2') "," %3.0f (`wald_df') "," %9.4f (`wald_p') _n

        local ++i
    }
}

file close `fh'

di as text _n "{hline 78}"
di as text "LISTO — lr_bargsted_maldonado.csv en Principal_NSE."
di as text "Lectura: p < 0.05 confirma que el bloque de cohorte (las 13"
di as text "categorías de cohort5 contra la base) es conjuntamente significativo,"
di as text "es decir, que existe ALGÚN efecto de cohorte más allá de edad y"
di as text "período — condición necesaria (no suficiente) para que valga la pena"
di as text "buscar UNA frontera específica dentro de ese bloque, como hace la"
di as text "Sección 6 del dofile principal."
di as text ""
di as text "Columnas chi2/df/p: LR test (fuera de zscore, df puede salir por"
di as text "debajo de 13 -- ver nota 2026-08-11 arriba, no usar para reportar)."
di as text "Columnas wald_chi2/wald_df/wald_p: test de Wald conjunto, df=13"
di as text "siempre -- esta es la que conviene citar en el paper."
di as text "{hline 78}"
