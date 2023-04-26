#!/bin/sh
set -eu

######################################################################
# 設定
######################################################################

print_usage_and_exit () {
  cat <<-USAGE 1>&2
	Usage   : ${0##*/} -p<開始座標> [座標ファイル]
	Options :

	開始座標から到達できる連続領域の座標を深さ優先順にソートする。

	-pオプションで探索の開始座標を指定する。

	座標ファイルのデータは以下の形式であることを想定する。
	 <x座標> <y座標>
	USAGE
  exit 1
}

######################################################################
# パラメータ
######################################################################

# 変数を初期化
opr=''
opt_p=''

# 引数をパース
i=1
for arg in ${1+"$@"}
do
  case "$arg" in
    -h|--help|--version) print_usage_and_exit ;;
    -p*)                 opt_p=${arg#-p}      ;;
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

# 有効な数値であるか判定
if ! printf '%s\n' "$opt_p" | grep -Eq '^[0-9]+,[0-9]+$'; then
  echo "${0##*/}: \"$opt_p\" invalid coordinate" 1>&2
  exit 31
fi

# パラメータを決定
coord=$opr
sp=$opt_p

######################################################################
# 本体処理
######################################################################

gawk '
######################################################################
# メイン
######################################################################

BEGIN {
  # パラメータを設定
  sp = "'"${sp}"'";

  # パラメータを初期化
  pn = 0;  # 入力点数
  inpx[1]; # 入力点のx座標
  inpy[1]; # 入力点のy座標

  # 座標の最大値を初期化
  pxmax = -1;
  pymax = -1;

  # 開始座標を分離
  split(sp, sary, ",");
  sx = sary[1];
  sy = sary[2];
}

{
  # 変数名をつける
  curpx = $1;
  curpy = $2;

  # 座標を記録
  pn++;
  inpx[pn] = curpx;
  inpy[pn] = curpy;

  # 最大値を更新
  pxmax = (pxmax < curpx) ? curpx : pxmax;
  pymax = (pymax < curpy) ? curpy : pymax;
}

END {
  # 別名の変数を作成
  width  = pxmax;
  height = pymax;

  # スタックを初期化（グローバル変数なので注意）
  st[1];
  nst = 1;

  # 空のキャンバスを作成
  for (j = 1; j <= height; j++) {
    for (i = 1; i <= width; i++) {
      map[j,i] = "blank";
    }
  }

  # 存在する座標をマップ上でチェック
  for (i = 1; i <= pn; i++) {
    map[inpy[i],inpx[i]] = "exist";
  }

  # 開始座標が領域に含まれていないならエラー
  if (map[sy,sx] == "blank") {
    msg = "'"${0##*/}"': invalid start point";
    print msg > "/dev/stderr";
    exit 41;
  }

  # 開始座標をスタックにプッシュ
  c[1] = sx; c[2] = sy; push(c);

  # 深さ優先探索を開始
  while(isempty() == "no") {
    # スタックが空でない限り継続

    # スタックから一要素を取得
    pop(c); cx = c[1]; cy = c[2];

    # 要素をマップ上でマーク
    map[cy,cx] = "marked";

    # 要素を出力
    print cx, cy;

    # 要素の周辺領域を探索
    if (map[cy-1,cx-1]=="exist") { c[1]=cx-1;c[2]=cy-1;push(c); }
    if (map[cy-1,cx  ]=="exist") { c[1]=cx  ;c[2]=cy-1;push(c); }
    if (map[cy-1,cx+1]=="exist") { c[1]=cx+1;c[2]=cy-1;push(c); }
    if (map[cy  ,cx-1]=="exist") { c[1]=cx-1;c[2]=cy  ;push(c); }
    if (map[cy  ,cx+1]=="exist") { c[1]=cx+1;c[2]=cy  ;push(c); }
    if (map[cy+1,cx-1]=="exist") { c[1]=cx-1;c[2]=cy+1;push(c); }
    if (map[cy+1,cx  ]=="exist") { c[1]=cx  ;c[2]=cy+1;push(c); }
    if (map[cy+1,cx+1]=="exist") { c[1]=cx+1;c[2]=cy+1;push(c); }
  }
}

######################################################################
# ユーティリティ
######################################################################

# スタックへのプッシュ（st,nstはグローバル変数）
function push(c,  x,y) {
  x = c[1];
  y = c[2];
  st[nst] = x "," y;
  nst++;
}

# スタックからのポップ（st,nstはグローバル変数）
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

# スタックが空か（st,nstはグローバル変数）
function isempty() {
  if (nst == 1) { return "yes"; }
  else          { return "no";  }
}
' ${coord-:"$coord"}
