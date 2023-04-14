#!/bin/sh
set -eu

######################################################################
# 設定
######################################################################

print_usage_and_exit () {
  cat <<-USAGE 1>&2
	Usage   : ${0##*/} [幾何学模様ファイル]
	Options : -s<区切り文字>

	2次元の幾何学模様として書かれたものを座標のリストに変換する。

	-sオプションで区切り文字を指定できる。デフォルトは" "（空白）。

	USAGE
  exit 1
}

######################################################################
# パラメータ
######################################################################

# 変数を初期化
opr=''
opt_s=' '

# 引数をパース
i=1
for arg in ${1+"$@"}
do
  case "$arg" in
    -h|--help|--version) print_usage_and_exit ;;
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

# 一文字であることを確認
if ! printf '%s\n' "$opt_s" | grep -Eq '^.?$'; then
  echo "${0##*/}: \"$opt_s\" invalid seperate character" 1>&2
  exit 31
fi

# パラメータを決定
geo=$opr
sep=$opt_s

######################################################################
# 本体処理
######################################################################

# コンテンツを入力
cat ${geo:+"$geo"}                                                   |

gawk -v FS="$sep" -v OFS=' ' '
{
  ridx = NR;

  for (cidx = 1; cidx <= NF; cidx++) {
     print ridx, cidx, $cidx;
  }
}
'
