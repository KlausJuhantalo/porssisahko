




CORSS tuki palvelimelle tms ratkaisu jos haluaa että toimii myös web.


Lisää huomisen hinnat myös niin pitkälle kun ne saa


https://sahkohinta-api.fi/documentation.htm
https://sahkohinta-api.fi/openapi.htm



TIETOAINEISTOT - löytyy vaikka mitä
https://data.fingrid.fi/datasets


https://data.fingrid.fi/instructions

https://developer-data.fingrid.fi/

sahkotiedot

Primary key
df6b31248f3f42219540f926c1f85054

Secondary key
539ac802dd0c48f589a838d46646accc



curl -X GET "https://data.fingrid.fi/v1/variable/65/events/current" -H "x-api-key: df6b31248f3f42219540f926c1f85054"


curl -X GET "https://data.fingrid.fi/api/notifications/active" -H "x-api-key: df6b31248f3f42219540f926c1f85054"

curl -X GET "https://data.fingrid.fi/api/datasets/245" -H "x-api-key: df6b31248f3f42219540f926c1f85054"


curl -X GET "https://data.fingrid.fi/api/datasets/245/data" -H "x-api-key: df6b31248f3f42219548f926c1f85054"


curl -X GET "https://data.fingrid.fi/api/datasets/245/data/latest" -H "x-api-key: df6b31248f3f42219548f926c1f85054"



curl -v -X GET "https://data.fingrid.fi/api/data?datasets={datasets}" -H "Cache-Control: no-cache" -H "x-api-key: df6b31248f3f42219548f926c1f85054"

curl -v -X GET "https://data.fingrid.fi/api/data?datasets=245" -H "Cache-Control: no-cache" -H "x-api-key: df6b31248f3f42219548f926c1f85054"


https://fingridavoindata.b2clogin.com/fingridavoindata.onmicrosoft.com/b2c_1a_signup_signin/oauth2/v2.0/authorize?client_id=46a6aed3-decd-4426-9c56-21e3c3201a46&scope=openid%20email%20profile%20offline_access&redirect_uri=https%3A%2F%2Fdeveloper-data.fingrid.fi%2Fsignin&client-request-id=92fdc55e-3181-4be1-8bb6-c783f878795b&response_mode=fragment&response_type=code&x-client-SKU=msal.js.browser&x-client-VER=2.38.3&client_info=1&code_challenge=xR-S7fCXqLySXn4SfzBuDmCOX27yQBLaPgJxI_AgT_0&code_challenge_method=S256&nonce=d161f3a7-e8d2-4813-8fac-893fe4dfdac4&state=eyJpZCI6ImFhNDY4NWE3LTg5MGQtNGRiNS04OGMxLTg2M2EzZjdlNGZlOSIsIm1ldGEiOnsiaW50ZXJhY3Rpb25UeXBlIjoicG9wdXAifX0%3D

klaus.juhantalo@gmail.com
sahkoapi68!






https://transparency.entsoe.eu/



Huomioita ja jatkokehitysideoita:

Päivämäärä kaavioon: Tässä esimerkissä X-akselin otsikoissa näkyy vain kellonaika. 
Haluat ehkä lisätä myös päivämäärän näkyviin, jos hintatiedot kattavat useampia päiviä. Voit muokata _formatTime -funktiota ja getTitlesWidget -funktiota FlTitlesData -osassa näyttämään päivämäärän tarpeen mukaan.

Kaavion mukautus: fl_chart -kirjasto tarjoaa paljon enemmän mukautusmahdollisuuksia. Voit muuttaa värejä, viivojen tyylejä, datapisteiden ulkoasua, otsikoiden muotoilua, lisätä legendaa, ym. Tutustu fl_chart -kirjaston dokumentaatioon https://pub.dev/packages/fl_chart saadaksesi lisätietoa mukautusmahdollisuuksista.

Interaktiivisuus: Voit lisätä kaavioon interaktiivisuutta, kuten zoomaus, panorointi, datapisteiden korostus, ym. fl_chart tukee myös interaktiivisia ominaisuuksia.
Reaaliaikainen data: Jos haluat, että kaavio päivittyy reaaliaikaisesti uusilla hintatiedoilla, sinun pitää toteuttaa datan automaattinen päivitys ja kaavion uudelleenpiirto tietyin väliajoin.







# nordpool_sahkonhinta

UI:n huomioita:

NordpoolService instanssi: Luodaan NordpoolService -luokasta instanssi, jota käytetään datan hakemiseen.
priceDataList: Lista PriceData -olioita, joka sisältää haetut hintatiedot.
_isLoading: Boolean-muuttuja lataustilan hallintaan.
initState() ja _fetchData(): _fetchData() kutsutaan initState():ssa hakemaan data heti näytön latautuessa. _fetchData() asettaa lataustilan, kutsuu nordpoolService.fetchPriceData(), päivittää priceDataList:in onnistuneen haun jälkeen ja käsittelee virheet.
CircularProgressIndicator(): Näytetään latausindikaattori datan latauksen aikana.
ListView.builder(): Listaa hintatiedot ListTile -komponentteina. DateFormat muotoilee päivämäärän ja ajan.
FloatingActionButton: "Päivitä" -nappi, joka kutsuu _fetchData() -funktiota manuaalista päivitystä varten.
Virheenkäsittely: Käytetään ScaffoldMessenger.of(context).showSnackBar näyttämään virheilmoitus käyttäjälle, jos datan haku epäonnistuu.
7. Testaus ja mukauttaminen

---------------


Se on erinomainen ehdotus! `sahkohinta-api.fi` vaikuttaa juuri tähän tarkoitukseen suunnitellulta ja voi olla paljon helpompi käyttää kuin `entsoe-eic` API.  Katsotaanpa, miten voimme siirtyä käyttämään sitä Flutter-sovelluksessamme.

**Hyödyt `sahkohinta-api.fi` API:n käytössä:**

*   **Suomen sähkönhintoihin keskittynyt:**  Vaikuttaa tarjoavan suoraan Suomen alueen hintatietoja, mikä on juuri mitä tarvitsemme.
*   **Yksinkertaisempi:**  Dokumentaation perusteella vaikuttaa hyvin suoraviivaiselta ja RESTful API:lta.
*   **Ei API-avainta:**  Dokumentaatio ei mainitse API-avaimen tarvetta, mikä tekee käytöstä paljon helpompaa ja nopeampaa aloittaa.
*   **Selkeä dokumentaatio:**  `openapi.htm` -dokumentaatio on ytimekäs ja näyttää riittävän tiedon API:n käyttämiseen.

**Muutokset Flutter-sovelluksessa `sahkohinta-api.fi` API:lle siirryttäessä:**

Meidän on pääasiassa muutettava datapalveluamme (`NordpoolService`) ja mahdollisesti hieman tietomalliamme (`PriceData`) vastaamaan `sahkohinta-api.fi` API:n tarjoamaa dataa.

**1. Tutkitaan `sahkohinta-api.fi` dokumentaatiota:**

Avaa linkki [https://www.sahkohinta-api.fi/openapi.htm](https://www.sahkohinta-api.fi/openapi.htm) selaimesi. Dokumentaatio on Swagger UI:ssa, joka tekee API:n tutkimisesta helppoa.

**Keskeiset tiedot dokumentaatiosta:**

*   **Perus URL:**  `https://api.sahkohinta-api.fi/v1`
*   **Endpoint sähkön hinnoille:**  `/prices`  (GET-pyyntö)
*   **Parametrit `/prices` endpointille:**
    *   `area`: (Valinnainen) Alueen tunnus.  Jos ei anneta, palauttaa kaikkien alueiden hinnat. Vaikuttaa siltä, että Suomelle sopivat aluekoodit ovat: `FI` (koko Suomi), `FI_1`, `FI_2`, `FI_3` (aluekohtaiset).  Käytetään aluksi koko Suomen aluetta (`FI`).
    *   `date`: (Valinnainen) Päivämäärä muodossa `YYYY-MM-DD`. Jos ei anneta, palauttaa tämän päivän hinnat.  Voimme aluksi jättää tämän pois, jotta saamme tämän päivän hinnat.

*   **Vastausmuoto (JSON):**  Vastaus on JSON-muodossa ja näyttää sisältävän listan hintaolioita. Jokainen hintaolio sisältää:
    *   `area`: Aluekoodi (esim. "FI")
    *   `startTime`:  Ajankohta, jolloin hinta alkaa (esim. "2024-01-29T00:00:00+02:00")
    *   `price`:  Hinta (esim. 4.25). Yksikkö todennäköisesti senttiä/kWh tai euroa/MWh (tämä pitää tarkistaa tarkemmin, oletetaan aluksi senttiä/kWh).

**2. Päivitetään `PriceData` -tietomalli:**

Tietomallimme `PriceData` on jo melko lähellä `sahkohinta-api.fi` API:n vastausmuotoa. Voimme hieman muokata `fromJson` -funktiota.

Avaa `models/price_data.dart` ja päivitä `PriceData.fromJson` -funktio näin:

```dart
class PriceData {
  final DateTime timestamp;
  final double price; // Hinta voi olla esim. senttiä/kWh
  final String area; // Lisätään aluekoodi

  PriceData({required this.timestamp, required this.price, required this.area});

  factory PriceData.fromJson(Map<String, dynamic> json) {
    return PriceData(
      timestamp: DateTime.parse(json['startTime']),
      price: (json['price'] as num).toDouble(), // Käytetään 'price' kenttää
      area: json['area'] as String,           // Haetaan aluekoodi 'area' kentästä
    );
  }
}
```

**Muutokset `PriceData` -tietomalliin:**

*   Lisätty `area` kenttä String-tyyppinä, jotta voimme tallentaa aluekoodin.
*   Päivitetty `PriceData.fromJson` käyttämään `json['startTime']` aikaleimalle ja `json['price']` hinnan hakemiseen. Lisätty myös `json['area']` aluekoodille.

**3. Päivitetään `NordpoolService` -datapalvelu:**

Nyt muutetaan `NordpoolService` käyttämään `sahkohinta-api.fi` API:a.

Avaa `services/nordpool_service.dart` ja korvaa sen sisältö seuraavalla koodilla:

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/price_data.dart';

class NordpoolService {
  // Ei tarvita API-avainta tälle API:lle!
  final String areaCode = 'FI'; // Käytetään koko Suomen aluetta, voi muuttaa esim. 'FI_1' jos haluaa aluekohtaisesti

  Future<List<PriceData>> fetchPriceData() async {
    final url = Uri.parse('https://api.sahkohinta-api.fi/v1/prices?area=$areaCode'); // Muutettu API URL

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body); // Vastaus on lista suoraan
      List<PriceData> prices = [];

      for (var item in jsonData) {
        prices.add(PriceData.fromJson(item));
      }

      return prices;

    } else {
      throw Exception('Failed to fetch price data: ${response.statusCode}');
    }
  }
}
```

**Muutokset `NordpoolService` -datapalveluun:**

*   **Poistettu API-avain:** `sahkohinta-api.fi` ei tarvitse API-avainta, joten `apiKey` -kenttä ja sen käyttö on poistettu.
*   **Päivitetty API URL:**  `url` muuttujaan asetettu uusi API URL: `https://api.sahkohinta-api.fi/v1/prices?area=$areaCode`.  Käytetään oletuksena koko Suomen aluetta (`FI`).
*   **Yksinkertaistettu JSON-parsinta:**  `sahkohinta-api.fi` näyttää palauttavan suoraan listan JSON-olioita, joten parsinta on yksinkertaisempaa.  `jsonDecode(response.body)` palauttaa suoraan `List<dynamic>` -listan, jonka voimme iteroida ja parsia `PriceData.fromJson` avulla.

**4. UI (main.dart) ei tarvitse muutoksia:**

`main.dart` -tiedostossa oleva UI-koodi pitäisi toimia ilman muutoksia, koska olemme vain muuttaneet datan hakemista ja mallia, mutta emme sitä miten data näytetään UI:ssa.

**5. Testaus ja suoritus:**

1.  **Tallenna kaikki muutetut tiedostot** (`price_data.dart` ja `nordpool_service.dart`).
2.  **Käynnistä sovellus uudelleen** (Full Restart on suositeltava).
3.  **Katso, näkyykö hinnat nyt sovelluksessa.**  Latausindikaattorin jälkeen pitäisi tulla lista sähkönhinnoista.

**Jos "Hinnatietoja ei saatavilla" -viesti jatkuu:**

*   **Tarkista konsolin virheilmoitukset jälleen.** Katso, mitä virhettä konsoli tulostaa. Se voi antaa vihjeitä ongelman syystä.
*   **Lisää `print(response.body)` `NordpoolService` -luokkaan** heti `final response = await http.get(url);` rivin jälkeen. Tämä tulostaa API:n vastausbody konsoliin. Tutki vastausta. Onko se odotetun muotoinen? Onko se virheilmoitus?  Vertaile vastausta `sahkohinta-api.fi` dokumentaatioon.
*   **Varmista aluekoodi:**  Kokeile muuttaa `areaCode` arvoa `NordpoolService` luokassa (esim. `FI_1`, `FI_2`, `FI_3`, tai jättää se tyhjäksi `''` jolloin se palauttaa kaikki alueet).  Ehkä oletusaluekoodi `FI` ei toimi jostain syystä.

**Yhteenveto:**

Siirtyminen `sahkohinta-api.fi` API:n käyttöön vaikuttaa erittäin lupaavalta. Se yksinkertaistaa koodia ja toivottavasti korjaa ongelmat, joita meillä oli `entsoe-eic` API:n kanssa. Kokeile näitä muutoksia ja kerro, miten se sujuu! Olen valmis auttamaan sinua vianetsinnässä, jos tarvitset apua.

---


Column -widgetti: Muutimme _PriceListView:n juuriwidgetin Column -widgetiksi, jotta voimme sijoittaa sekä kaavion että listan pystysuunnassa allekkain.
AspectRatio ja LineChart -widgetit: Lisäsimme AspectRatio -widgetin sisään LineChart -widgetin. AspectRatio varmistaa, että kaavio saa tietyn korkeus-leveyssuhteen (tässä tapauksessa leveyden kaksi kertaa korkeammaksi). LineChart on fl_chart -kirjaston viivakaavio-widgetti, jota käytetään itse kaavion piirtämiseen.
LineChartData: Määrittelemme LineChartData -olion avulla kaavion datan, akselit, otsikot, ruudukon ja muut ulkoasulliset seikat. Koodissa on kommentit selventämässä kunkin ominaisuuden toimintaa.
_generateChartDataPoints(prices) -apufunktio: Tämä apufunktio muuntaa listan PriceData -olioita List<FlSpot> -muotoon, joka on fl_chart -kirjaston vaatima datapisteiden muoto viivakaaviota varten. X-akselin arvoiksi asetetaan datapisteiden indeksit listassa (0, 1, 2, ...), ja Y-akselin arvoiksi hinnat.
_getMinPrice(prices) ja _getMaxPrice(prices) -apufunktiot: Nämä apufunktiot laskevat listan hintatietojen pienimmän ja suurimman hinnan, jotta voimme asettaa Y-akselin minimi- ja maksimiarvot sopiviksi.
_formatTime(dateTime) -apufunktio: Sama apufunktio kuin aiemmin, muotoilemaan aikaleimat lyhyemmäksi kaavion X-akselin otsikoita varten.