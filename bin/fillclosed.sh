#!/bin/sh
set -eu

######################################################################
# 設定
######################################################################

print_usage_and_exit () {
  cat <<-USAGE 1>&2
	Usage   : ${0##*/} -p<座標> [キャンバスファイル]
	Options : -r<行数> -c<列数> -s<文字>

	座標（"x,y"のように指定）と４連結している閉曲線内を塗りつぶす。
	閉曲線は"■"で、閉曲線内は"□"で構成されているとする。

	-pオプションで塗りつぶしたい閉曲線内の一点の座標を指定する。
	-rオプションで出力する画像の行数を指定できる。デフォルトは20。
	-cオプションで出力する画像の列数を指定できる。デフォルトは40。
	-sオプションで塗りつぶしの文字を指定する。デフォルトは"■"
	USAGE
  exit 1
}

######################################################################
# パラメータ
######################################################################

# 変数を初期化
opr=''
opt_r='20'
opt_c='40'
opt_s='■'

# 引数をパース
i=1
for arg in ${1+"$@"}
do
  case "$arg" in
    -h|--help|--version) print_usage_and_exit ;;
    -p*)                 opt_p=${arg#-p}      ;;
    -r*)                 opt_r=${arg#-r}      ;;
    -c*)                 opt_c=${arg#-c}      ;;
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

# 有効な数値であるか判定
if ! printf '%s\n' "$opt_r" | grep -Eq '^[0-9]+$'; then
  echo "${0##*/}: \"$opt_r\" invalid number" 1>&2
  exit 41
fi

# 有効な数値であるか判定
if ! printf '%s\n' "$opt_c" | grep -Eq '^[0-9]+$'; then
  echo "${0##*/}: \"$opt_c\" invalid number" 1>&2
  exit 51
fi

# 有効な文字であるか判定
if ! printf '%s\n' "$opt_s" | grep -q '^.$'; then
  echo "${0##*/}: \"$opt_s\" invalid charactor" 1>&2
  exit 61
fi

# パラメータを決定
content=$opr
c0=$opt_p
height=$opt_r
width=$opt_c
fchar=$opt_s

######################################################################
# 本体処理
######################################################################

# 輝度値を入力
cat ${content-:"$content"}                                           |

gawk -v FS='' '
BEGIN {
  # 開始座標の情報を設定（x,y）
  c0 = "'"${c0}"'";
  split(c0, ary, ",");
  x0 = ary[1];
  y0 = ary[2];

  # 塗りつぶし文字を設定
  fchar = "'"${fchar}"'"

  # パラメータを設定
  height = '"${height}"';
  width  = '"${width}"';
}

{
  # キャンバスを入力
  for (i = 1; i <= NF; i++) { buf[NR,i] = $i; }
}

END {
  # スタックを初期化（グローバル変数）
  st[1];
  nst = 1;

  # スタックの底に開始座標を入れる
  c[1] = x0; c[2] = y0;
  push(c);

  while(1) {
    pop(c); x = c[1]; y = c[2];
    if (x == "null") { break; }
    else {
      if (buf[y,x+1]=="□"){buf[y,x+1]=fchar;c[1]=x+1;c[2]=y;  push(c);}
      if (buf[y,x-1]=="□"){buf[y,x-1]=fchar;c[1]=x-1;c[2]=y;  push(c);}
      if (buf[y+1,x]=="□"){buf[y+1,x]=fchar;c[1]=x  ;c[2]=y+1;push(c);}
      if (buf[y-1,x]=="□"){buf[y-1,x]=fchar;c[1]=x  ;c[2]=y-1;push(c);}
    }
  }

  width  = NF;
  height = NR;

  # キャンバスを出力
  for (i = 1; i <= height; i++) {
    for (j = 1; j <= width; j++) {
      printf "%s", buf[i,j];
    }

    print "";
  }
}

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
'
