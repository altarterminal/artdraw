#!/bin/sh
set -eu

######################################################################
# 設定
######################################################################

print_usage_and_exit () {
  cat <<-USAGE 1>&2
	Usage   : ${0##*/} -p<開始座標> [座標ファイル]
	Options : -r -w

	開始座標から到達できる連続領域の座標を深さ優先順にソートする。

	-pオプションで探索の開始座標を指定する。
	-rオプションで開始座標から到達しない領域の座標を標準エラー出力に出力する。
	-wオプションで探索を幅優先で行う。

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
opt_r='no'
opt_w='no'

# 引数をパース
i=1
for arg in ${1+"$@"}
do
  case "$arg" in
    -h|--help|--version) print_usage_and_exit ;;
    -p*)                 opt_p=${arg#-p}      ;;
    -r)                  opt_r='yes'          ;;
    -w)                  opt_w='yes'          ;;
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
crd=$opr
sp=$opt_p
isrev=$opt_r
iswfirst=$opt_w

######################################################################
# 本体処理
######################################################################

gawk '
BEGIN {
######################################################################
# 座標列を入力
######################################################################

  # パラメータを設定
  sp       = "'"${sp}"'";
  isrev    = "'"${isrev}"'";
  iswfirst = "'"${iswfirst}"'";

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
######################################################################
# メイン
######################################################################

  # 別名の変数を作成
  width  = pxmax;
  height = pymax;

  # マップを初期化
  initmap(inpx, inpy, pn, width, height);

  # データ構造を初期化
  initdatastructure();

  # 開始座標をバッファに投入
  consumeneighbor(sx, sy);

  # 深さ優先探索を開始
  while(isempty() == "no") {
    # バッファが空でない限り継続

    # バッファから一要素を取得
    getnext(c); cx = c[1]; cy = c[2];

    # 要素を出力
    print cx, cy;

    # 要素の周辺領域を探索
    if (canconsume(cx-1,cy-1)=="yes") { consumeneighbor(cx-1,cy-1); }
    if (canconsume(cx  ,cy-1)=="yes") { consumeneighbor(cx  ,cy-1); }
    if (canconsume(cx+1,cy-1)=="yes") { consumeneighbor(cx+1,cy-1); }
    if (canconsume(cx-1,cy  )=="yes") { consumeneighbor(cx-1,cy  ); }
    if (canconsume(cx+1,cy  )=="yes") { consumeneighbor(cx+1,cy  ); }
    if (canconsume(cx-1,cy+1)=="yes") { consumeneighbor(cx-1,cy+1); }
    if (canconsume(cx  ,cy+1)=="yes") { consumeneighbor(cx  ,cy+1); }
    if (canconsume(cx+1,cy+1)=="yes") { consumeneighbor(cx+1,cy+1); }
  }

  # 到達しなかった座標を出力
  if (isrev == "yes") {
    nr = getunmarked(rx, ry);

    for (i=1;i<=nr;i++) { print rx[i], ry[i] > "/dev/stderr"; }
  }
}

######################################################################
# マップユーティリティ
######################################################################

# マップの状態を設定（mapはグローバル変数）
function getmap(x,y) {
  return map[y,x];
}

# マップの状態を取得（mapはグローバル変数）
function setmap(x,y,state) {
  map[y,x] = state;
}

# マップを初期化
function initmap(x,y,n,w,h,  i,j) {
  # パラメータをセット
  mapw = w;
  maph = h;

  # 空のキャンバスを作成
  for (j = 1; j <= maph; j++) {
    for (i = 1; i <= mapw; i++) {
      setmap(i, j, "blank");
    }
  }

  # 存在する座標をマップ上でチェック
  for (i=1;i<=n;i++) { setmap(x[i],y[i],"unmarked"); }
}

# 未到達の座標を取得
function getunmarked(x,y,  n,i,j) {
  n = 0;

  for (j = 1; j <= maph; j++) {
    for (i = 1; i <= mapw; i++) {
      if (getmap(i, j) == "unmarked") {
        n++; x[n] = i; y[n] = j;
      }
    }
  }

  return n;
}

function canconsume(x,y) {
  if   (getmap(x,y) == "unmarked") { return "yes"; }
  else                             { return "no";  }
}

function consumeneighbor(x,y,  c) {
  setmap(x, y, "marked");

  c[1] = x; c[2] = y;
  if   (iswfirst == "yes") { enq(c);  }
  else                     { push(c); }
}

function getnext(c) {
  if   (iswfirst == "yes") { deq(c); }
  else                     { pop(c); }
}

function isempty() {
  if   (iswfirst == "yes") { return isemptyq();  }
  else                     { return isemptyst(); } 
}

function initdatastructure() {
  if   (iswfirst == "yes") { initq();  }
  else                     { initst(); } 
}

######################################################################
# スタックユーティリティ
######################################################################

# スタックを初期化
function initst() {
  st[1];   # スタック本体
  nst = 1; # 次に要素を格納する場所
}

# スタックへのプッシュ（st,nstはグローバル変数）
function push(c,  x,y) {
  x = c[1]; y = c[2];
  st[nst] = x "," y;
  nst++;
}

# スタックからのポップ（st,nstはグローバル変数）
function pop(c,  ary) {
  if (nst == 1) {
    c[1] = "null"; c[2] = "null";
  }
  else {
    nst--;
    split(st[nst], ary, ",");
    c[1] = ary[1]; c[2] = ary[2];
  }
}

# スタックが空か
function isemptyst() {
  if   (nst == 1) { return "yes"; }
  else            { return "no";  }
}

######################################################################
# キューユーティリティ
######################################################################

# キューを初期化
function initq() {
  q[1];        # キュー本体
  qhead = 1;   # 次に要素を格納するインデックス
  qtail = 1;   # 次に要素を取り出すインデックス
  qlen  = 100; # キューの長さ（利用可能領域は1だけ小さい）
}

# エンキュー
function enq(c,   x,y) {
  x = c[1]; y = c[2];

  # キューが満杯だったらエラー
  if ((qhead % qlen + 1) == qtail) {
    msg = "'"${0##*/}"': queue is full";
    print msg > "/dev/stderr";
    exit 51;
  }

  q[qhead] = x "," y;
  qhead = qhead % qlen + 1;
}

# デキュー
function deq(c,  ary) {
  # キューが空だったら何も返さない
  if (qhead == qtail) {
    c[1] = "null"; c[2] = "null";
  }
  else {
    split(q[qtail], ary, ",");
    c[1] = ary[1]; c[2] = ary[2];

    qtail = qtail % qlen + 1;
  }
}

function isemptyq() {
  if   (qhead == qtail) { return "yes"; }
  else                  { return "no";  }
}
' ${crd-:"$crd"}
