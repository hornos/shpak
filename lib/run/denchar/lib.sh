
sp_f_load run/siesta

function sp_f_denchar_check() {
  sp_f_siesta_check
}

function sp_f_denchar_prepare() {
  sp_f_siesta_prepare "${sp_s_sion}"
}

function sp_f_denchar_finish() {
  sp_f_siesta_finish
}

function sp_f_denchar_collect() {
  sp_f_siesta_collect
}
