# Chiina-Dazzler
6502 Graphics Board

# 予定する仕様
- MAX Vにプログラミング
- 256\*192（DS画面サイズ)のフレームバッファ1か2枚を1024\*768（XGA）に引き延ばして表示
- 4bitカラーパレット、12bit（RGB各4bit）DAC出力
- 線分描画などのアクセラレーション

# 使用法
 - 今のところQuartusに依存しています。トップレベルが回路図（ChiinaDazzler.bdf）のため。
 - また Design Wave Magazine 2008年10月号の配布データ（ https://www.cqpub.co.jp/dwm/download/dwm0810toku_3/top.htm ）中のlist1-1.txtをVideoTimingGenerator.vにリネームして組み込む必要があります。
  - そのうち不要にする
