// ============================================================================
// BRECHA ESTALLIDO EN ESCALA DE PROBABILIDAD
// Confianza institucional y cohortes generacionales en Chile
// Bustamante & Quintero — Congreso Triada 2026
//
// Do-file chico y AUTOCONTENIDO: corre completo de una sola vez sin riesgo
// de gatillar los ~45 modelos multinivel del do-file principal. Sí estima 5
// modelos nuevos (meologit, uno por institución), pero cada uno tiene un
// solo predictor de cohorte (post_estallido) y ningún grid de márgenes —
// nada parecido a la Sección 4. Debería tardar un par de minutos en total,
// no horas.
//
// Es una copia de la Sección 0 (config) + Sección 1 (prep de datos) +
// Sección 10 del dofile final. Si ese archivo cambia, actualizar acá
// también.
// ============================================================================

global DATA      "C:\Users\gonza\Dropbox\Proyectos personales\02.- DATOS\Bicentenario\bicentenario_panel_armonizado.dta"
global PRINCIPAL "C:\Users\gonza\Dropbox\Proyectos personales\01.- Desarrollo investigación\Quintero, Bustamante\Análisis final\Principal"


// ----------------------------------------------------------------------------
// Preparación de datos mínima (solo lo que necesita la sección 10)
// ----------------------------------------------------------------------------

use "$DATA", clear

gen int birthyear = year - edad
keep if birthyear >= 1930 & birthyear <= 2007
keep if edad >= 18 & edad <= 85

gen age_s  = edad / 10
gen age_s2 = age_s^2
gen mujer  = (sexo == 2) if !missing(sexo)

gen post_estallido = (birthyear >= 1995) if !missing(birthyear)
label define post_estallidolbl 0 "Pre-estallido (<1995)" 1 "Post-estallido (1995+)"
label values post_estallido post_estallidolbl

foreach v in conf_gobierno conf_parlamento conf_partidos conf_ffaa conf_iglesia {
    replace `v' = . if inlist(`v', 6, 7)
}

local institutions "conf_gobierno conf_parlamento conf_partidos conf_ffaa conf_iglesia"
local labels        `""Gobierno" "Parlamento" "Partidos" "FF.AA." "Iglesia""'


// ============================================================================
// >>> SECCIÓN 10: BRECHA ESTALLIDO EN ESCALA DE PROBABILIDAD
// ============================================================================
// Misma lógica que la sección 7 del dofile principal (brecha pre/post
// estallido), pero con el modelo ordinal en vez de z-score, graficando
// P(confía) = P(Y=4)+P(Y=5) — más intuitivo para una audiencia de congreso.

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
    quietly meologit `v' age_s age_s2 i.post_estallido mujer i.educ4 [pweight=ponderador] || year:, or vce(robust)
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


di as text _n "{hline 78}"
di as text "LISTO — 7_brecha_estallido_prob.png en Principal."
di as text "{hline 78}"
