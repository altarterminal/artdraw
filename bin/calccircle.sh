#!/bin/sh
set -eu

######################################################################
# 設定
######################################################################

print_usage_and_exit () {
  cat <<-USAGE 1>&2
	Usage   : ${0##*/} [パラメータ]
	Options :

	円が通過する座標（整数）を計算する。

	パラメータは以下の形式で指定する。
	  中心を(x,y)、半径をrとする円 -> "x,y,r"
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
if ! printf '%s\n' "$opr" | grep -Eq '^-?[0-9]+,-?[0-9]+,[0-9]+$'; then
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
  x0 = pary[1];
  y0 = pary[2];
  r0 = pary[3];

  # 起点の４点
  xb[1] =  r0; yb[1] =   0;
  xb[2] =   0; yb[2] =  r0;
  xb[3] = -r0; yb[3] =   0;
  xb[4] =   0; yb[4] = -r0;

  # 第２領域（x>0,y>0,x<y）をベースとする初期化
  d  = 3 - 2*r0;
  cx = 0;
  cy = r0;

  # 第２領域（x>0,y>0,x<y）をベースとして座標を計算
  while (cx <= cy) {
    n++;
    if   (d < 0) { d = d +  6 + 4*cx;              cx++; }
    else         { d = d + 10 + 4*cx - 4*cy; cy--; cx++; }

    x1[n] =  cy; y1[n] =  cx;
    x2[n] =  cx; y2[n] =  cy;
    x3[n] = -cx; y3[n] =  cy;
    x4[n] = -cy; y4[n] =  cx;
    x5[n] = -cy; y5[n] = -cx;
    x6[n] = -cx; y6[n] = -cy;
    x7[n] =  cx; y7[n] = -cy;
    x8[n] =  cy; y8[n] = -cx;
  }

  # 範囲外の座標を削除（境界の周辺でオーバーランした座標を削除）
  for (i = 1; i <= n; i++) {
    # 第２領域（x>0,y>0,x<y）をベースに探索
    if (x2[i] > y2[i]) { n = i - 1; break; }
  }

  # 起点に対してオフセットを加算
  for (i = 1; i <= 4; i++) {
    xb[i] = xb[i] + x0; yb[i] = yb[i] + y0;
  }

  # 近似点に対してオフセットを加算
  for (i = 1; i <= n; i++) {
    x1[i] = x1[i] + x0; y1[i] = y1[i] + y0;
    x2[i] = x2[i] + x0; y2[i] = y2[i] + y0;
    x3[i] = x3[i] + x0; y3[i] = y3[i] + y0;
    x4[i] = x4[i] + x0; y4[i] = y4[i] + y0;
    x5[i] = x5[i] + x0; y5[i] = y5[i] + y0;
    x6[i] = x6[i] + x0; y6[i] = y6[i] + y0;
    x7[i] = x7[i] + x0; y7[i] = y7[i] + y0;
    x8[i] = x8[i] + x0; y8[i] = y8[i] + y0;
  }

  # x座標正から反時計回りに出力
  print xb[1], yb[1];
  for (i = 1; i <= n; i++) { print x1[i], y1[i]; }
  for (i = n; i >= 1; i--) { print x2[i], y2[i]; }
  print xb[2], yb[2];
  for (i = 1; i <= n; i++) { print x3[i], y3[i]; }
  for (i = n; i >= 1; i--) { print x4[i], y4[i]; }
  print xb[3], yb[3];
  for (i = 1; i <= n; i++) { print x5[i], y5[i]; }
  for (i = n; i >= 1; i--) { print x6[i], y6[i]; }
  print xb[4], yb[4];
  for (i = 1; i <= n; i++) { print x7[i], y7[i]; }
  for (i = n; i >= 1; i--) { print x8[i], y8[i]; }

  exit;
}
'                                                                    |

# 各領域の境界に重複があれば削除（x=yの座標）
uniq
