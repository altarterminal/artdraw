#!/bin/sh
set -eu

######################################################################
# 設定
######################################################################

print_usage_and_exit () {
  cat <<-USAGE 1>&2
	Usage   : ${0##*/} -p<座標> [キャンバスファイル]
	Options : -s<文字>

	座標（"x,y"のように指定）と４連結している閉曲線内を塗りつぶす。
	閉曲線は"■"で、閉曲線内は"□"で構成されているとする。

	-pオプションで塗りつぶしたい閉曲線内の座標（探索開始座標）を指定する。
	-sオプションで塗りつぶしの文字を指定する。デフォルトは"■"
	USAGE
  exit 1
}

######################################################################
# パラメータ
######################################################################

# 変数を初期化
opr=''
opt_p=''
opt_s='■'

# 引数をパース
i=1
for arg in ${1+"$@"}
do
  case "$arg" in
    -h|--help|--version) print_usage_and_exit ;;
    -p*)                 opt_p=${arg#-p}      ;;
    -s*)                 opt_s=${arg#-s}      ;;
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

# 標準入力または読み取り可能な通常ファイルであるか判定
if   [ "_$opr" = '_' ] || [ "_$opr" = '_-' ]; then     
  opr=''
elif [ ! -f "$opr"   ] || [ ! -r "$opr"    ]; then
  echo "${0##*/}: \"$opr\" cannot be opened" 1>&2
  exit 21
else
  :
fi

# 有効な座標であるか判定
if ! printf '%s\n' "$opt_p" | grep -Eq '^-?[0-9]+,-?[0-9]+$'; then
  echo "${0##*/}: \"$opt_p\" invalid number" 1>&2
  exit 31
fi

# 有効な文字であるか判定
if ! printf '%s\n' "$opt_s" | grep -q '^.$'; then
  echo "${0##*/}: \"$opt_s\" invalid charactor" 1>&2
  exit 41
fi

# パラメータを決定
content=$opr
sp=$opt_p
fchar=$opt_s

######################################################################
# 本体処理
######################################################################

gawk -v FS='' '
######################################################################
# メイン
######################################################################

BEGIN {
  # パラメータを設定
  sp    = "'"${sp}"'";
  fchar = "'"${fchar}"'";

  # 開始座標の情報を分離
  split(sp, ary, ",");
  sx = ary[1];
  sy = ary[2];
}

{
  # キャンバスを入力
  for (i = 1; i <= NF; i++) { buf[NR,i] = $i; }
}

END {
  # 別の変数名をつける
  width  = NF;
  height = NR;

  # スタックを初期化（グローバル変数）
  st[1];
  nst = 1;

  # スタックの底に開始座標を入れる
  buf[sy,sx] = fchar;
  c[1] = sx; c[2] = sy; push(c);

  # スタックが空になるまで繰り返す
  while (isempty() == "no") {
    pop(c); x = c[1]; y = c[2];

    if (buf[y,x+1]=="□"){buf[y,x+1]=fchar;c[1]=x+1;c[2]=y  ;push(c);}
    if (buf[y,x-1]=="□"){buf[y,x-1]=fchar;c[1]=x-1;c[2]=y  ;push(c);}
    if (buf[y+1,x]=="□"){buf[y+1,x]=fchar;c[1]=x  ;c[2]=y+1;push(c);}
    if (buf[y-1,x]=="□"){buf[y-1,x]=fchar;c[1]=x  ;c[2]=y-1;push(c);}
  }

  # キャンバスを出力
  for (i = 1; i <= height; i++) {
    for (j = 1; j <= width; j++) { printf "%s", buf[i,j]; }
    print "";
  }
}

######################################################################
# ユーティリティ
######################################################################

function push(c,  x,y) {
  x = c[1];
  y = c[2];
  st[nst] = x "," y;
  nst++;
}

function pop(c,  ary) {
  if (nst == 1) {
    c[1] = "null";
    c[2] = "null";
  }
  else {
    nst--;
    split(st[nst], ary, ",");
    c[1] = ary[1];
    c[2] = ary[2];
  }
}

function isempty() {
  if (nst == 1) { return "yes"; }
  else          { return "no";  }
}
' ${content-:"$content"}
