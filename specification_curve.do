// ============================================================================
// CURVA DE ESPECIFICACIONES — LAS TRES ENCRUCIJADAS DE COHORTES
// Confianza institucional y cohortes generacionales en Chile
// Bustamante & Quintero — Congreso Triada 2026
//
// Do-file chico y AUTOCONTENIDO, CERO estimación nueva: solo importa
// tabla_4_wald_cohortes.csv (ya generado por la sección 6 del dofile
// principal) y lo grafica. Corre en segundos.
//
// Muestra las 10 fronteras candidatas de las tres encrucijadas juntas
// (teórica + importada + Balcells) — a diferencia del gráfico de fronteras
// quinquenales (que solo mira dentro del esquema teórico), esta figura es
// la evidencia de robustez de la ELECCIÓN del esquema de cohorte en sí: de
// todas las fronteras candidatas razonables, ¿cuál sobrevive? Es una
// "specification curve" (Simonsohn, Simmons & Nelson 2020, Nature Human
// Behaviour) / "multiverse analysis" (Steegen et al. 2016) — mostrar todas
// las decisiones analíticas razonables a la vez, no solo la que se terminó
// usando, para que el lector vea que el resultado no depende de haber
// elegido convenientemente una sola especificación.
// ============================================================================

global PRINCIPAL "C:\Users\gonza\Dropbox\Proyectos personales\01.- Desarrollo investigación\Quintero, Bustamante\Análisis final\Principal_NSE"

import delimited "$PRINCIPAL\tabla_4_wald_cohortes.csv", clear varnames(1) case(preserve)
keep if tipo == "frontera" & especificacion == "ordinal"

// No usar la columna p tal cual: se guardó con solo 4 decimales, así que
// cualquier p menor a 0.0001 quedó redondeado a "0.0000", y -log10(0) es
// indefinido — esos puntos (los más significativos) desaparecerían del
// gráfico. Se recalcula el p-valor exacto desde el chi2 (guardado con más
// precisión) con chi2tail().
gen neglog10p = -log10(chi2tail(df, stat))

// Orden cronológico aproximado por año de la frontera candidata, mezclando
// las tres encrucijadas.
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
      ylabel(1 "Silenciosa/Boomer 1945/46 (importada)" 2 "Pre-masif. vs Edo. desarrollista, 1949/1950 (teorica)" 3 "Boomer/X 1964/65 (importada)" 4 "Edo. desarrollista vs Dictadura, 1964/1965 (teorica)" 5 "Plebiscito 1988, 1970/71 (corte único)" 6 "Retorno democracia, 1972/73 (corte único)" 7 "Dictadura vs Democracia neoliberal, 1979/1980 (teorica)" 8 "X/Millennial 1980/81 (importada)" 9 "Democracia neoliberal vs Estallido, 1994/1995 (teorica)" 10 "Millennial/Z 1996/97 (importada)", angle(0) labsize(vsmall)) ytitle("") ///
      xtitle("-log10(p), test de Wald (especificación ordinal)") ///
      title("Curva de especificaciones — fronteras de cohorte candidatas", size(medium)) ///
      legend(order(1 "Gobierno" 2 "Parlamento" 3 "Partidos" 4 "FF.AA." 5 "Iglesia") rows(1) position(6) size(small)) ///
      graphregion(color(white) margin(l=25)) plotregion(color(white)) xsize(13) ysize(7)
graph export "$PRINCIPAL\8_specification_curve.png", replace width(2400)

di as text _n "{hline 78}"
di as text "LISTO — 8_specification_curve.png en Principal."
di as text "{hline 78}"
