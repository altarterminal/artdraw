#!/bin/sh
set -eu

######################################################################
# 設定
######################################################################

print_usage_and_exit () {
  cat <<-USAGE 1>&2
	Usage   : ${0##*/} [パラメータ]
	Options : -t<周期> -o<位相> -a<振幅> -d<出力長>

	正弦の値を計算する。

	-tオプションで周期の長さ（ピクセル）を指定できる。デフォルトは40ピクセル。
	-oオプションで初期位相（度数法）を指定できる。デフォルトは0。
	-aオプションで振幅（ピクセル）を指定できる。デフォルトは10ピクセル。
	-dオプションで出力長（ピクセル）を指定できる。デフォルトは40ピクセル。
	USAGE
  exit 1
}

######################################################################
# パラメータ
######################################################################

# 変数を初期化
opr=''
opt_t='40'
opt_o='0'
opt_a='10'
opt_d='40'

# 引数をパース
i=1
for arg in ${1+"$@"}
do
  case "$arg" in
    -h|--help|--version) print_usage_and_exit ;;
    -t*)                 opt_t=${arg#-t}      ;;
    -o*)                 opt_o=${arg#-o}      ;;
    -a*)                 opt_a=${arg#-a}      ;;
    -d*)                 opt_d=${arg#-d}      ;;
    *)
      if [ $i -eq $# ] && [ -z "$opr" ]; then
        opr=$arg
      else
        echo "${0##*/}: invalid args" 1>&2
        exit 11
      fi
      ;;
  esac

  i=$((i + 1))
done

# 有効なパラメータ指定か確認
# if ! printf '%s\n' "$opr" | grep -Eq '^[0-9]+,[0-9]+,[0-9]+,[0-9]+$'; then
#   echo "${0##*/}: \"$opr\" invalid parameter" 1>&2
#   exit 21
# fi


# 有効な数値であるか判定
if ! printf '%s\n' "$opt_t" | grep -Eq '^[0-9]+$'; then
  echo "${0##*/}: \"$opt_t\" invalid number" 1>&2
  exit 31
fi

# 有効な数値であるか判定
if ! printf '%s\n' "$opt_o" | grep -Eq '^[0-9]+$'; then
  echo "${0##*/}: \"$opt_o\" invalid number" 1>&2
  exit 41
fi

# 有効な数値であるか判定
if ! printf '%s\n' "$opt_a" | grep -Eq '^[0-9]+$'; then
  echo "${0##*/}: \"$opt_a\" invalid number" 1>&2
  exit 51
fi

# 有効な数値であるか判定
if ! printf '%s\n' "$opt_d" | grep -Eq '^[0-9]+$'; then
  echo "${0##*/}: \"$opt_d\" invalid number" 1>&2
  exit 61
fi

# パラメータを決定
param=$opr
period=$opt_t
phase=$opt_o
amp=$opt_a
duration=$opt_d

######################################################################
# 本体処理
######################################################################

gawk '
BEGIN {
  # パラメータを設定
  period   = '"${period}"';
  phase    = '"${phase}"';
  amp      = '"${amp}"';
  duration = '"${duration}"';

  pi  = 3.1415;
  pi2 = pi * 2.0;

  # ピクセルあたりの物理次元の長さ（浮動小数点数）
  physperiod = pi2 / period;

  # 物理次元での振幅（浮動小数点数）
  physamp = 1.0 * amp;

  # 物理次元での初期位相（浮動小数点数）
  physphase = pi2 * phase / 360.0;

  for (i = 1; i <= duration; i++) {
    # 浮動小数点数での計算
    buf[i] = physamp * sin((i-1) * physperiod + physphase);
  }

  # 出力
  for (i = 1; i <= duration; i++) {
    print round(buf[i]), i;
  }

  exit;
}

function round(x) {
  if (x >= 0) { return int(x);       }
  else        { return -1*int(-1*x); }
}
'
