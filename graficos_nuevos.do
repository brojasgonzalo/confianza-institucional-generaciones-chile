// ============================================================================
// GRÁFICOS NUEVOS — forest plot de encrucijadas + tendencia temporal
// Confianza institucional y cohortes generacionales en Chile
// Bustamante & Quintero — Congreso Triada 2026
//
// Do-file chico y AUTOCONTENIDO: corre completo de una sola vez ("Run" o
// Ctrl+D sobre todo el archivo) sin riesgo de gatillar los ~45 modelos
// multinivel del do-file principal — acá no hay ningún melogit/mixed/
// meologit/margins. Debería tardar menos de un minuto en total.
//
// Es una copia de la Sección 0 (config) + Sección 1 (prep de datos, sin
// modelos) + Secciones 8 y 9 del dofile final. Si ese archivo cambia,
// actualizar acá también.
// ============================================================================

global DATA      "C:\Users\gonza\Dropbox\Proyectos personales\02.- DATOS\Bicentenario\bicentenario_panel_armonizado.dta"
global PRINCIPAL "C:\Users\gonza\Dropbox\Proyectos personales\01.- Desarrollo investigación\Quintero, Bustamante\Análisis final\Principal"


// ----------------------------------------------------------------------------
// Preparación de datos mínima (solo lo que necesitan las secciones 8 y 9 —
// no arma cohort5/cohort_teorica/cohort_check, no hace falta para esto)
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
// >>> SECCIÓN 8: FOREST PLOT — LAS TRES ENCRUCIJADAS DE COHORTES
// ============================================================================
// No estima nada nuevo — solo importa tabla_4_wald_cohortes.csv (ya
// generado por el dofile principal) y lo grafica. Un punto por frontera
// candidata x institución, especificación ordinal (la principal). Eje x:
// -log10(p) del test de Wald — más a la derecha = más significativo, línea
// de referencia en p=.05.

preserve
import delimited "$PRINCIPAL\tabla_4_wald_cohortes.csv", clear varnames(1) case(preserve)
keep if tipo == "frontera" & especificacion == "ordinal"

// No usar la columna p tal cual: se guardó con solo 4 decimales en la
// sección 6, así que cualquier p menor a 0.0001 quedó redondeado a "0.0000"
// en el csv, y -log10(0) es indefinido — esos puntos (los más significativos,
// justo los que más importan) desaparecerían del gráfico. Se recalcula el
// p-valor exacto desde el estadístico chi2 (guardado con más precisión) con
// chi2tail(), sin necesidad de volver a estimar nada.
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

// Jitter vertical pequeño para que las 5 instituciones no se encimen en la
// misma fila.
gen front_jit = front_pos + cond(institucion=="Gobierno",-0.24, ///
    cond(institucion=="Parlamento",-0.12,cond(institucion=="Partidos",0, ///
    cond(institucion=="FF.AA.",0.12,0.24))))

// El texto va directo en ylabel() (no como value label) porque front_jit
// trae el jitter y sus valores no caen justo en los enteros 1-10 — un
// value label ahí no calzaría con ningún punto exacto.
twoway ///
    (scatter front_jit neglog10p if institucion=="Gobierno",   mcolor(navy)    msymbol(O)) ///
    (scatter front_jit neglog10p if institucion=="Parlamento", mcolor(maroon)  msymbol(D)) ///
    (scatter front_jit neglog10p if institucion=="Partidos",   mcolor(dkgreen) msymbol(T)) ///
    (scatter front_jit neglog10p if institucion=="FF.AA.",     mcolor(orange)  msymbol(S)) ///
    (scatter front_jit neglog10p if institucion=="Iglesia",    mcolor(purple)  msymbol(X)) ///
    , xline(1.301, lpattern(dash) lcolor(gs8)) ///
      ylabel(1 "Silenciosa/Boomer 1945/46 (importada)" 2 "Bloque 1-2, 1949/1950 (teorica)" 3 "Boomer/X 1964/65 (importada)" 4 "Bloque 2-3, 1964/1965 (teorica)" 5 "Plebiscito 1988, 1970/71 (balcells)" 6 "Retorno democracia, 1972/73 (balcells)" 7 "Bloque 3-4, 1979/1980 (teorica)" 8 "X/Millennial 1980/81 (importada)" 9 "Bloque 4-5, 1994/1995 (teorica)" 10 "Millennial/Z 1996/97 (importada)", angle(0) labsize(vsmall)) ytitle("") ///
      xtitle("-log10(p), test de Wald (especificación ordinal)") ///
      title("Solo una frontera generacional" "sobrevive a las tres encrucijadas", size(medium)) ///
      subtitle("Línea punteada = umbral p=.05. Más a la derecha = más significativo.", size(vsmall)) ///
      legend(order(1 "Gobierno" 2 "Parlamento" 3 "Partidos" 4 "FF.AA." 5 "Iglesia") rows(1) position(6) size(small)) ///
      graphregion(color(white)) xsize(10) ysize(7)
graph export "$PRINCIPAL\5_forest_encrucijadas.png", replace width(2400)
restore


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
di as text "LISTO — 5_forest_encrucijadas.png y 6_tendencia_temporal.png en Principal."
di as text "{hline 78}"
