// ============================================================================
// TENDENCIA TEMPORAL 2006-2025
// Confianza institucional y cohortes generacionales en Chile
// Bustamante & Quintero — Congreso Triada 2026
//
// Do-file chico y AUTOCONTENIDO: corre completo de una sola vez ("Run" o
// Ctrl+D sobre todo el archivo) sin riesgo de gatillar los ~45 modelos
// multinivel del do-file principal — acá no hay ningún melogit/mixed/
// meologit/margins. Debería tardar menos de un minuto en total.
//
// (El forest plot de fronteras quinquenales, antes también acá, ahora
// necesita estimar modelos de verdad — se movió a su propio script,
// fronteras_quinquenales.do.)
//
// Es una copia de la Sección 0 (config) + Sección 1 (prep de datos, sin
// modelos) + Sección 9 del dofile final. Si ese archivo cambia, actualizar
// acá también.
// ============================================================================

global DATA      "C:\Users\gonza\Dropbox\Proyectos personales\02.- DATOS\Bicentenario\bicentenario_panel_armonizado.dta"
global PRINCIPAL "C:\Users\gonza\Dropbox\Proyectos personales\01.- Desarrollo investigación\Quintero, Bustamante\Análisis final\Principal"


// ----------------------------------------------------------------------------
// Preparación de datos mínima (solo lo que necesita la sección 9)
// ----------------------------------------------------------------------------

use "$DATA", clear

gen int birthyear = year - edad
keep if birthyear >= 1930 & birthyear <= 2007
keep if edad >= 18 & edad <= 85

foreach v in conf_gobierno conf_parlamento conf_partidos conf_ffaa conf_iglesia {
    replace `v' = . if inlist(`v', 6, 7)
    gen `v'_bin = (`v' >= 4) if !missing(`v')
    label var `v'_bin "`v' confía (top-2-box: 4-5=1, 1-3=0)"
}

local institutions "conf_gobierno conf_parlamento conf_partidos conf_ffaa conf_iglesia"


// ============================================================================
// >>> SECCIÓN 9: TENDENCIA TEMPORAL 2006-2025 (contexto descriptivo)
// ============================================================================
// Proporción ponderada simple por año (comando `mean`, no un modelo
// multinivel, no margins). Corre en segundos (18 años x 5 instituciones =
// 90 medias ponderadas simples).

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


di as text _n "{hline 78}"
di as text "LISTO — 6_tendencia_temporal.png en Principal."
di as text "{hline 78}"
