// ============================================================================
// COBERTURA DE LAS 5 VARIABLES DEPENDIENTES POR OLA
// Confianza institucional y cohortes generacionales en Chile
// Bustamante & Quintero — Congreso Triada 2026
//
// Do-file chico y AUTOCONTENIDO, puramente descriptivo (ningún modelo, solo
// `tab`) — corre en segundos. Genera el insumo para el cuadro de cobertura
// del README: N total y número de olas con datos, por institución, más el
// detalle año a año en un csv aparte.
// ============================================================================

global DATA      "C:\Users\gonza\Dropbox\Proyectos personales\02.- DATOS\Bicentenario\bicentenario_panel_armonizado.dta"
global PRINCIPAL "C:\Users\gonza\Dropbox\Proyectos personales\01.- Desarrollo investigación\Quintero, Bustamante\Análisis final\Principal"

use "$DATA", clear

gen int birthyear = year - edad
keep if birthyear >= 1930 & birthyear <= 2007
keep if edad >= 18 & edad <= 85

foreach v in conf_gobierno conf_parlamento conf_partidos conf_ffaa conf_iglesia {
    replace `v' = . if inlist(`v', 6, 7)
}

local institutions "conf_gobierno conf_parlamento conf_partidos conf_ffaa conf_iglesia"
local labels        `""Gobierno" "Parlamento" "Partidos" "FF.AA." "Iglesia""'

// --- Detalle año a año (para el csv) ---------------------------------------
tempname fh
file open `fh' using "$PRINCIPAL\cobertura_variables_detalle.csv", write replace
file write `fh' "institucion,year,n" _n

local i = 1
foreach v of local institutions {
    local lbl : word `i' of `labels'
    quietly levelsof year, local(anios)
    foreach a of local anios {
        quietly count if year == `a' & !missing(`v')
        file write `fh' `""`lbl'""' "," (`a') "," (`r(N)') _n
    }
    local ++i
}
file close `fh'

// --- Resumen: N total y número de olas con datos (para el README) ---------
tempname fh2
file open `fh2' using "$PRINCIPAL\cobertura_variables_resumen.csv", write replace
file write `fh2' "institucion,n_total,n_olas_con_datos,n_olas_total" _n

quietly levelsof year, local(anios_todas)
local n_olas_total : word count `anios_todas'

local i = 1
foreach v of local institutions {
    local lbl : word `i' of `labels'
    quietly count if !missing(`v')
    local ntot = r(N)

    local olas_con_datos = 0
    foreach a of local anios_todas {
        quietly count if year == `a' & !missing(`v')
        if r(N) > 0 local olas_con_datos = `olas_con_datos' + 1
    }
    di as text "`lbl': N=" `ntot' ", olas con datos=" `olas_con_datos' "/" `n_olas_total'
    file write `fh2' `""`lbl'""' "," (`ntot') "," (`olas_con_datos') "," (`n_olas_total') _n
    local ++i
}
file close `fh2'

di as text _n "{hline 78}"
di as text "LISTO — cobertura_variables_resumen.csv y _detalle.csv en Principal."
di as text "{hline 78}"
