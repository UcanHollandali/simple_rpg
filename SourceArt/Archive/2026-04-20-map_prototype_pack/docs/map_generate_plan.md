Evet, ana plan **tam olarak bu olmalı**:
**stage başında map tamamen oluşsun**, sonra sen yürüdükçe sadece **keşif açığa çıksın**. Yani “topology ve board layout frozen”, “discovery sadece görünürlüğü değiştiriyor” mantığı. Repo’nun şu anki yapısında stage graph zaten baştan realize ediliyor; save tarafında `active_map_template_id` ve `map_realized_graph` tutuluyor. Ayrıca board coordinates / spline points / decor placements save’e yazılmıyor; bunları composer sonradan runtime graph truth’tan türetiyor. ([GitHub][1])

Benim şu anki çıkarımım şu:
**Node graph büyük ölçüde baştan var, ama görünen node/edge katmanı visibility’ye göre yeniden kuruluyor.** `MapRouteBinding`, graph signature aynı kaldığında `world_positions` ve `forest_shapes` cache’ini koruyor; ama `visible_nodes` ve `visible_edges` sadece visibility signature değişmemişse aynen tutuyor. Visibility değişince composer bunları yeniden build ediyor. Composer tarafında da undiscovered node’lar görünür listeye hiç alınmıyor ve undiscovered node’a değen history edge’ler gösterilmiyor. Bu yüzden oyuncuya “harita büyüdükçe yollar değişiyor” hissi gelmesi çok olası. Kodunu çalıştırmadan yüzde yüz diyemem, ama en güçlü aday bu. ([GitHub][2])

İkinci problem de senin dediğin “alanı daha fazla kullanma” kısmı. Mevcut composer tarafında merkez ve margin oldukça sıkı tutuluyor: `BASE_CENTER_FACTOR = (0.50, 0.58)`, `MIN_BOARD_MARGIN = (118, 132)`, ayrıca depth step / spread sabitleri ve board içine clamp etme var. Doküman da mevcut stage graph truth’u için “controlled-scatter and compact, bounded portrait readability” diyor. Yani bugünkü sistem tasarım gereği biraz fazla kompakt kalıyor. ([GitHub][3])

Bence doğru hedef şu:

* **Stage start’ta full realized graph** zaten var, bu kalsın.
* Buna ek olarak **full board layout** da o anda freeze olsun:

  * tüm node world position’ları
  * tüm edge/path geometry
  * clearing/pocket alanları
  * forest/decor anchor’ları
* Sonra oyun sırasında sadece:

  * node visibility açılır
  * edge visibility açılır
  * fog/undiscovered mask kalkar
    Ama **pozisyonlar ve path şekilleri değişmez**.

Yani kural şu olmalı:
**“Reveal changes visibility, not layout.”**

Bunu Codex’e şöyle ver:

Map behavior fix:

Hedef:

* Stage başında map tamamen realize olsun.
* Oyuncu yürüdükçe sadece keşif açılsın.
* Harita büyüdükçe node pozisyonları veya yol geometrisi değişmesin.
* Reveal sadece visibility değiştirsin, layout değiştirmesin.
* Board mevcut alana daha fazla yayılsın; fazla kompakt kalmasın.

Mevcut problem:

* Graph runtime’da baştan var gibi duruyor ama visible node/edge composition visibility değiştikçe yeniden kuruluyor.
* Bu yüzden oyuncuya yollar anlık oluşuyor veya değişiyor hissi gelebiliyor.
* Board footprint de fazla center-clamped / compact.

İstediğim çözüm:

1. Stage start’ta full board layout snapshot üret:

   * all node world positions
   * all edge/path geometry
   * clearing data
   * forest/decor anchors
2. Bu full layout graph signature değişmedikçe sabit kalsın.
3. Sonraki refresh’lerde visible_nodes / visible_edges bu frozen full layout’tan filtrelensin.
4. Visible subset’ten yeniden edge control point / path geometry üretme.
5. Discovery sadece hidden -> visible geçişi olsun.
6. Board footprint’i genişlet:

   * margin’i azalt
   * outer depth radius/spread’i artır
   * start center bias’ı biraz gevşet
   * portrait readability, overlap safety ve edge crossing guard’ları koru
7. Sonuç:

   * map start game anında oluşmuş hissi versin
   * yürüdükçe sadece keşif açılsın
   * node’lar mevcut map alanına daha çok yayılsın
   * yollar sonradan şekil değiştirmesin

Audit et:

* Şu an tam olarak hangi dosyada visibility-driven recomposition hissi doğuyor?
* Hangi cache yüzeyleri frozen layout’a çevrilmeli?
* Minimum güvenli patch sırası ne?

Sonra patch uygula.

Net kararım:
Senin istediğin davranış **doğru hedef**. Şu an repo’da graph tarafı buna yakın, ama **board composition / visible-edge katmanı henüz tam “frozen map, progressive discovery” gibi davranmıyor**. Asıl düzeltilecek yer burası. ([GitHub][4])

[1]: https://raw.githubusercontent.com/UcanHollandali/simple_rpg/main/Docs/MAP_COMPOSER_V2_DESIGN.md "raw.githubusercontent.com"
[2]: https://github.com/UcanHollandali/simple_rpg/blob/main/Game/UI/map_route_binding.gd "simple_rpg/Game/UI/map_route_binding.gd at main · UcanHollandali/simple_rpg · GitHub"
[3]: https://github.com/UcanHollandali/simple_rpg/blob/main/Game/UI/map_board_composer_v2.gd "simple_rpg/Game/UI/map_board_composer_v2.gd at main · UcanHollandali/simple_rpg · GitHub"
[4]: https://raw.githubusercontent.com/UcanHollandali/simple_rpg/main/Docs/MAP_CONTRACT.md "raw.githubusercontent.com"
