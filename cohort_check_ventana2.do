// ============================================================================
// RE-TESTEO ENCRUCIJADAS 1 Y 3 (IMPORTADA / BALCELLS) CON VENTANA ±2 AÑOS
// Confianza institucional y cohortes generacionales en Chile
// Bustamante & Quintero — Congreso Triada 2026
//
// Do-file chico y AUTOCONTENIDO. Reemplaza cohort_check por una versión con
// ventana ±2 años alrededor de cada frontera candidata (antes comparaba
// solo un año contra el siguiente — muy poca potencia). Balcells (1970/71 y
// 1972/73) queda en ventana ±1 porque los dos cortes están a solo 2 años de
// distancia y una ventana ±2 en ambos se superpondría.
//
// Sí estima 15 modelos nuevos (3 especificaciones x 5 instituciones, con
// cohort_check en vez de cohort5) — la encrucijada 2 (esquema teórico) NO
// se re-estima, se reutiliza tal cual del csv existente porque no cambió.
// Sin margins, debería tardar unos minutos, no horas.
//
// Al final actualiza tabla_4_wald_cohortes.csv en el lugar (reemplaza solo
// las filas "importada"/"balcells", deja "teorica" intacta) para que
// specification_curve.do siga funcionando sin cambios.
// ============================================================================

global DATA      "C:\Users\gonza\Dropbox\Proyectos personales\02.- DATOS\Bicentenario\bicentenario_panel_armonizado.dta"
global PRINCIPAL "C:\Users\gonza\Dropbox\Proyectos personales\01.- Desarrollo investigación\Quintero, Bustamante\Análisis final\Principal"


// ----------------------------------------------------------------------------
// Preparación de datos
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

// Ventana ±2 años alrededor de cada frontera candidata (Balcells en ±1 por
// la cercanía entre sus dos cortes — ver nota en dofile principal, sección 1).
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
// Encrucijadas 1 y 3 (importada / Balcells) — modelos con cohort_check
// ============================================================================

capture program drop wald_row
program define wald_row
    args fh especificacion esquema institucion bloque tipo
    local stat = r(chi2)
    file write `fh' `"`especificacion'"' "," `"`esquema'"' "," `"`institucion'"' "," ///
        `"`bloque'"' "," `"`tipo'"' "," `"chi2"' "," ///
        %9.3f (`stat') "," %3.0f (r(df)) "," %9.4f (r(p)) _n
end

tempname fh_new
tempfile new_rows
file open `fh_new' using "`new_rows'", write replace
file write `fh_new' "especificacion,esquema,institucion,bloque,tipo,stat_type,stat,df,p" _n

foreach spec in binaria zscore ordinal {
    if "`spec'" == "binaria" {
        local estcmd    "melogit"
        local dvsuf     "_bin"
        local estopt    ", or vce(robust)"
    }
    else if "`spec'" == "zscore" {
        local estcmd    "mixed"
        local dvsuf     "_z"
        local estopt    ", mle vce(robust)"
    }
    else {
        local estcmd    "meologit"
        local dvsuf     ""
        local estopt    ", or vce(robust)"
    }

    local i = 1
    foreach v of local institutions {
        local lbl : word `i' of `labels'
        quietly `estcmd' `v'`dvsuf' age_s age_s2 i.cohort_check mujer i.educ4 [pweight=ponderador] || year: `estopt'

        quietly test 11002.cohort_check = 11001.cohort_check
        wald_row `fh_new' "`spec'" "importada" "`lbl'" "frontera Silenciosa/Boomer (1945/1946)" "frontera"
        quietly test 1960.cohort_check = 1965.cohort_check
        wald_row `fh_new' "`spec'" "importada" "`lbl'" "frontera Boomer/X (1964/1965)" "frontera"
        quietly test 12002.cohort_check = 12001.cohort_check
        wald_row `fh_new' "`spec'" "importada" "`lbl'" "frontera X/Millennial (1980/1981)" "frontera"
        quietly test 13002.cohort_check = 13001.cohort_check
        wald_row `fh_new' "`spec'" "importada" "`lbl'" "frontera Millennial/Z (1996/1997)" "frontera"

        quietly test 20002.cohort_check = 20001.cohort_check
        wald_row `fh_new' "`spec'" "balcells" "`lbl'" "frontera plebiscito 1988 (1970/1971)" "frontera"
        quietly test 20004.cohort_check = 20003.cohort_check
        wald_row `fh_new' "`spec'" "balcells" "`lbl'" "frontera retorno democracia 1990 (1972/1973)" "frontera"

        local ++i
    }
}
file close `fh_new'


// ============================================================================
// Actualizar tabla_4_wald_cohortes.csv: mantiene "teorica" (no cambió),
// reemplaza "importada"/"balcells" por las filas nuevas.
// ============================================================================

preserve
import delimited "$PRINCIPAL\tabla_4_wald_cohortes.csv", clear varnames(1) case(preserve) stringcols(_all)
keep if esquema == "teorica"
tempfile teorica_rows
save "`teorica_rows'", replace
restore

preserve
import delimited "`new_rows'", clear varnames(1) case(preserve) stringcols(_all)
append using "`teorica_rows'"
export delimited "$PRINCIPAL\tabla_4_wald_cohortes.csv", replace
restore

di as text _n "{hline 78}"
di as text "LISTO — tabla_4_wald_cohortes.csv actualizada (importada/balcells con ventana ±2)."
di as text "Corre specification_curve.do para regenerar el gráfico con los valores nuevos."
di as text "{hline 78}"
