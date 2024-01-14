#!/bin/sh
set -eu

######################################################################
# 設定
######################################################################

print_usage_and_exit () {
  cat <<-USAGE 1>&2
	Usage   : ${0##*/} -s<開始座標> [コンテンツファイル]
	Options : -t<対象文字> -b<境界文字> 

	コンテンツの有効部分の境界を抽出する。

	-sオプションで探索開始座標を指定する。形式は"x,y"。

	-tオプションで探索対象の文字を指定できる。デフォルトは■。
	-bオプションで境界を表す文字を指定できる。デフォルトは★。
	USAGE
  exit 1
}

######################################################################
# パラメータ
######################################################################

opr=''
opt_s=''
opt_t='■'
opt_b='★'

i=1
for arg in ${1+"$@"}
do
  case "$arg" in
    -h|--help|--version) print_usage_and_exit ;;
    -s*)                 opt_s=${arg#-s}      ;;
    -t*)                 opt_t=${arg#-t}      ;;
    -b*)                 opt_b=${arg#-b}      ;;

    *)
      if [ $i -eq $# ] && [ -z "$opr" ] ; then
        opr=$arg
      else
        echo "${0##*/}: invalid args"
        exit 11
      fi
      ;;
  esac

  i=$((i + 1))
done

if   [ "_$opr" = '_' ] || [ "_$opr" = '_-' ]; then     
  opr=''
elif [ ! -f "$opr"   ] || [ ! -r "$opr"    ]; then
  echo "${0##*/}: \"$opr\" cannot be opened" 1>&2
  exit 21
else
  :
fi

if ! printf '%s' "$opt_s" | grep -Eq '^[0-9]+,[0-9]+$'; then
  echo "${0##*/}: invalid coordinate specified (${opt_s})" 1>&2
  exit 22
fi

if ! printf '%s' "$opt_t" | grep -q '^.$'; then
  echo "${0##*/}: a character must be specified (${opt_t})" 1>&2
  exit 23
fi

if ! printf '%s' "$opt_b" | grep -q '^.$'; then
  echo "${0##*/}: a character must be specified (${opt_b})" 1>&2
  exit 24
fi

content=$opr
scrd=$opt_s
tchar=$opt_t
bchar=$opt_b

######################################################################
# 本体処理
######################################################################

gawk -v FS='' -v OFS='' '
BEGIN {
  scrd  = "'"${scrd}"'";
  tchar = "'"${tchar}"'";
  bchar = "'"${bchar}"'";
  
  n = split(scrd, sary, ",");
  sx = sary[1];
  sy = sary[2];
}

{
  # すべてのコンテンツを読み込む
  for (i = 1; i <= NF; i++) { 
    buf[NR, i] = $i; 
  }
}

END {
  width  = NF;
  height = NR;

  # 全領域に未探索をマーク
  for (j = 1; j <= height; j++) {
    for (i = 1; i <= width; i++) {
      sbuf[j,i] = "n";
    }
  }

  # 探索ターゲット座標のスタック
  st[1];
  sti = 0;

  # 境界判定済み座標のスタック
  bst[1];
  bsti = 0;

  # 探索開始座標を設定
  set(sx, sy);

  while (isempty() == "n") {
    # 次の探索座標を取得
    split(get(), nary, ",");
    nx = nary[1];
    ny = nary[2];

    # 探索済みをマーク
    mark(nx, ny);

    # 現在の座標が境界上か判定
    isborder = "n";
    if (isout(nx-1, ny) == "y") { isborder = "y"; }
    if (isout(nx+1, ny) == "y") { isborder = "y"; }
    if (isout(nx, ny-1) == "y") { isborder = "y"; }
    if (isout(nx, ny+1) == "y") { isborder = "y"; }

    if (isborder == "y") {
      bsti++;
      bst[bsti] = nx "," ny;
    }

    # 次の探索先を保存
    if (isout(nx-1,ny)=="n" && ismark(nx-1,ny)=="n") {set(nx-1,ny);}
    if (isout(nx+1,ny)=="n" && ismark(nx+1,ny)=="n") {set(nx+1,ny);}
    if (isout(nx,ny-1)=="n" && ismark(nx,ny-1)=="n") {set(nx,ny-1);}
    if (isout(nx,ny+1)=="n" && ismark(nx,ny+1)=="n") {set(nx,ny+1);}
  }

  # 抽出した境界をもとのバッファに上書き
  for (i = 1; i <= bsti; i++) {
    split(bst[i], bary, ",");
    bx = bary[1];
    by = bary[2];

    buf[by,bx] = bchar;
  }

  # 境界を上書きしたバッファを出力
  for (j = 1; j <= height; j++) {
    for (i = 1; i <= width; i++) { printf "%s", buf[j,i]; }
    print "";
  }

}

function isout(x, y) {
  if   (buf[y,x] != tchar) { return "y"; }
  else                     { return "n"; }
}

function mark(x, y) {
  sbuf[y,x] = "y";
}

function ismark(x, y) {
  return sbuf[y,x];
}

function set(x, y) {
  sti++;
  st[sti] = x "," y;
}

function get(  e) {
  e = st[sti];
  sti--;
  return e;
}

function isempty() {
  if   (sti == 0) { return "y"; }
  else            { return "n"; }
}
' ${content:+"$content"}
