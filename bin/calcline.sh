#!/bin/sh
set -eu

######################################################################
# 設定
######################################################################

print_usage_and_exit () {
  cat <<-USAGE 1>&2
	Usage   : ${0##*/} [パラメータ]
	Options :

	2点を端点とする線分が通過する座標（整数）を計算する。

	パラメータは以下の形式で指定する。
	  (x1,y1),(x2,y2)を通る線分 -> "x1,y1,x2,y2"
	USAGE
  exit 1
}

######################################################################
# パラメータ
######################################################################

# 変数を初期化
opr=''

# 引数をパース
i=1
for arg in ${1+"$@"}
do
  case "$arg" in
    -h|--help|--version) print_usage_and_exit ;;
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
if ! printf '%s\n' "$opr" | grep -Eq '^[0-9]+,[0-9]+,[0-9]+,[0-9]+$'; then
  echo "${0##*/}: \"$opr\" invalid parameter" 1>&2
  exit 21
fi
  
# パラメータを決定
param=$opr

######################################################################
# 本体処理
######################################################################

gawk '
BEGIN {
  param = "'"${param}"'";

  # パラメータを分離
  split(param, pary, ",");
  x1 = pary[1];
  y1 = pary[2];
  x2 = pary[3];
  y2 = pary[4];

  # 差分
  dx = x2 - x1;
  dy = y2 - y1;

  # 線の進行方向
  ix = 1;
  iy = 1;

  # 傾きと進行方向を補正  
  if (dx < 0) { ix = -1 * ix; dx = -1 * dx; }
  if (dy < 0) { iy = -1 * iy; dy = -1 * dy; }

  # パラメータを決定
  if (dx >= dy) {
    d =  1 + dx;
    e = -1 * dx;
    a =  2 * dy;
    b = -2 * dx;
    ax = ix;
    ay = 0;
    bx = 0;
    by = iy;
  } else {
    d =  1 + dy;
    e = -1 * dy;
    a =  2 * dx;
    b = -2 * dy;
    ax = 0;
    ay = iy;
    bx = ix;
    by = 0;
  }

  # この変数を変化させてxとyを決定していく
  xtmp = x1;
  ytmp = y1;

  # すべての点の座標を計算
  for (i = 1; i <= d; i++) {
    x[i] = xtmp;
    y[i] = ytmp;

    xtmp = xtmp + ax;
    ytmp = ytmp + ay;
    e = e + a;

    if (e >= 0) {
      xtmp = xtmp + bx;
      ytmp = ytmp + by;
      e = e + b;
    }
  }

  # 作成した座標を出力
  for (i = 1; i <= d; i++) {
    print x[i], y[i];
  }

  exit;
}
'
