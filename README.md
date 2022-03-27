# Chiina-Dazzler
6502 Graphics Board on CPLD
http://ponzu840w.starfree.jp/blog/blog.html?id=00030

# 仕様
- MAX Vにプログラミング
- 256\*192（DS画面サイズ)を1024\*768（XGA）に引き延ばして表示
- ~~4bitカラーパレット、12bit（RGB各4bit）DAC出力~~ RGB222、固定16色
- 16色モード/2色モード
- ~~線分描画などのアクセラレーション~~ 容量的に無理
- フレームバッファ4枚（1MbitRAMをVRAMとして接続）
- 6502CPUバスに直接インタフェース（R/Wを除く）
- 自由なタイミングでVRAM書き換え

# 使い方
これから書く

