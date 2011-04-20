
function sp_f_quofr() {
  # http://www.shell-fu.org
  # Tip #122
  curl -Is slashdot.org | egrep '^X-(F|B|L)' | cut -d \- -f 2
}
