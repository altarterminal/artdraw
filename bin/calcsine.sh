#!/bin/sh
set -eu

######################################################################
# 設定
######################################################################

print_usage_and_exit () {
  cat <<-USAGE 1>&2
	Usage   : ${0##*/} [出力長]
	Options : -t<周期> -i<位相> -a<振幅>

	正弦の値を計算する。

	-tオプションで周期の長さ（ピクセル）を指定できる。デフォルトは40ピクセル。
	-iオプションで初期位相（度数法）を指定できる。デフォルトは0。
	-aオプションで振幅（ピクセル）を指定できる。デフォルトは10ピクセル。
	USAGE
  exit 1
}

######################################################################
# パラメータ
######################################################################

# 変数を初期化
opr=''
opt_t='40'
opt_i='0'
opt_a='10'

# 引数をパース
i=1
for arg in ${1+"$@"}
do
  case "$arg" in
    -h|--help|--version) print_usage_and_exit ;;
    -t*)                 opt_t=${arg#-t}      ;;
    -i*)                 opt_i=${arg#-i}      ;;
    -a*)                 opt_a=${arg#-a}      ;;
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

# 有効な数値であるか判定
if ! printf '%s\n' "$opr" | grep -Eq '^[0-9]+$'; then
  echo "${0##*/}: \"$opr\" invalid number" 1>&2
  exit 21
fi

# 有効な数値であるか判定
if ! printf '%s\n' "$opt_t" | grep -Eq '^[0-9]+$'; then
  echo "${0##*/}: \"$opt_t\" invalid number" 1>&2
  exit 31
fi

# 有効な数値であるか判定
if ! printf '%s\n' "$opt_i" | grep -Eq '^[0-9]+$'; then
  echo "${0##*/}: \"$opt_i\" invalid number" 1>&2
  exit 41
fi

# 有効な数値であるか判定
if ! printf '%s\n' "$opt_a" | grep -Eq '^[0-9]+$'; then
  echo "${0##*/}: \"$opt_a\" invalid number" 1>&2
  exit 51
fi

# パラメータを決定
len=$opr
period=$opt_t
iniphase=$opt_i
amp=$opt_a

######################################################################
# 本体処理
######################################################################

gawk '
BEGIN {
  # パラメータを設定
  period   = '"${period}"';
  iniphase = '"${iniphase}"';
  amp      = '"${amp}"';
  len      = '"${len}"';

  # 定数を定義
  pi  = 3.141592;
  pi2 = pi * 2.0;

  # ピクセルあたりの物理次元の長さ（浮動小数点数）
  physperiod = pi2 / period;

  # 物理次元での振幅（浮動小数点数）
  physamp = 1.0 * amp;

  # 弧度法での初期位相（浮動小数点数）
  radiniphase = pi2 * iniphase / 360.0;

  for (i = 1; i <= len; i++) {
    # 浮動小数点数での計算
    buf[i] = physamp * sin((i-1) * physperiod + radiniphase);
  }

  # 値を丸めて出力
  for (i = 1; i <= len; i++) { print round(buf[i]); }

  exit;
}

function round(x) {
  if (x >= 0) { return int(x + 0.5);       }
  else        { return -1*int(-1*x + 0.5); }
}
'
