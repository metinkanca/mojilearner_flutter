// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get header => 'Dil Ayarları';

  @override
  String get iSpeak => 'Konuştuğum Dil';

  @override
  String get imLearning => 'Öğrendiğim Dil';

  @override
  String get currentSelection => 'Mevcut Seçim:';

  @override
  String get level => 'Seviye';

  @override
  String get xp => 'XP';

  @override
  String get streak => 'Günlük Seri';

  @override
  String get audio => 'Bot Sesi';

  @override
  String get designMojiBtn => 'Moji Tasarla';

  @override
  String get quizDesc => 'Bilgilerini test et.';

  @override
  String get scenarios => 'Kasaba';

  @override
  String get scenariosDesc => 'Gerçek hayat konuşmalarını pratik yap.';

  @override
  String get townSchool => 'Okul';

  @override
  String get placeCafe => 'Kafe';

  @override
  String get placeTownHall => 'Belediye';

  @override
  String get placeGazebo => 'Köşk';

  @override
  String get placeHospital => 'Hastane';

  @override
  String get placeShop => 'Dükkân';

  @override
  String get townTab => 'Kasaba';

  @override
  String get profile => 'Profil';

  @override
  String get shop => 'Mağaza';

  @override
  String get mistakes => 'HATALAR';

  @override
  String get noMistakesYet => 'HENÜZ HATA YOK!';

  @override
  String get profileDesc => 'İstatistiklerini ve ayarlarını gör.';

  @override
  String get voiceCall => 'Sesli Arama';

  @override
  String get voiceCallDesc => 'Gerçek zamanlı sesli konuşma pratiği yap.';

  @override
  String get practiceRealLife => 'Gerçek Hayatı Pratik Et';

  @override
  String get chooseSituation =>
      'Konuşma becerilerini geliştirmek için bir durum seç';

  @override
  String get createYourOwn => 'Kendi Senaryonu Yarat';

  @override
  String get startCustom => 'Özel Senaryo Başlat';

  @override
  String get customPlaceholder => 'Örn. Taksi şoförüsün...';

  @override
  String get orderingCoffee => 'Kahve Siparişi';

  @override
  String get jobInterview => 'İş Görüşmesi';

  @override
  String get askingDirections => 'Yol Sorma';

  @override
  String get atTheDoctor => 'Doktorda';

  @override
  String get shopping => 'Alışveriş';

  @override
  String get restaurant => 'Restoran';

  @override
  String get chats => 'Sohbetler';

  @override
  String get searchPlaceholder => 'Mesaj ara...';

  @override
  String get newChat => 'Yeni Sohbet';

  @override
  String get noChats => 'Henüz sohbet yok';

  @override
  String get startNewConversation => 'Yeni bir konuşma başlat';

  @override
  String get cancel => 'İptal';

  @override
  String get typeMessage => 'Mesajını yaz...';

  @override
  String get designMoji => 'Moji Tasarla';

  @override
  String get fullCustomization => 'Tam Özelleştirme';

  @override
  String get tapToChange => 'Duyguyu değiştirmek için dokun';

  @override
  String get mascotColor => 'Maskot Rengi';

  @override
  String get backgroundColor => 'Arka Plan Rengi';

  @override
  String get faceExpressions => 'Yüz İfadeleri';

  @override
  String get personalityFaces => 'Kişilik & Yüzler';

  @override
  String get selectFaces => 'Maskotunun kullanacağı yüzleri seç.';

  @override
  String get locked => 'Kilitli';

  @override
  String unlockMessage(Object level) {
    return 'Bu yüzü açmak için $level. seviyeye ulaş!';
  }

  @override
  String get yourMistakes => 'Hataların';

  @override
  String get learnFromWrong => 'Yanlışlarından öğren';

  @override
  String get all => 'Tümü';

  @override
  String get grammar => 'Gramer';

  @override
  String get grammarBreakdown => 'Gramer Analizi';

  @override
  String get close => 'Kapat';

  @override
  String get noGrammarAnalysis => 'Gramer analizi mevcut değil.';

  @override
  String get vocabulary => 'Kelime';

  @override
  String get noMistakes => 'Hata bulunamadı!';

  @override
  String get yourAnswer => 'Senin Cevabın';

  @override
  String get correctAnswer => 'Doğru Cevap';

  @override
  String get explanation => 'Açıklama';

  @override
  String get story => 'Senaryolar';

  @override
  String get drills => 'Hatalar';

  @override
  String get shopTitle => 'Mağaza';

  @override
  String get categoryAll => 'Hepsi';

  @override
  String get categoryFood => 'Yiyecek';

  @override
  String get categoryDecor => 'Dekor';

  @override
  String get hideOwnedCosmetics => 'Sahip Olunan Kozmetikleri Gizle';

  @override
  String get noItems => 'Ürün Yok';

  @override
  String get owned => 'Sahip Olunan';

  @override
  String get alreadyOwned => 'Zaten Sahip';

  @override
  String get alreadyOwnedMessage => 'Bu ürüne zaten sahipsiniz!';

  @override
  String get quantity => 'Miktar';

  @override
  String get totalPrice => 'Toplam Fiyat';

  @override
  String get notEnoughCoins => 'Yetersiz Altın!';

  @override
  String get purchaseFailed => 'Satın Alma Başarısız';

  @override
  String get notEnoughCoinsMessage => 'Yetersiz altın!';

  @override
  String get buy => 'Satın Al';

  @override
  String get tooPoor => 'Çok Fakir';

  @override
  String get ok => 'Tamam';

  @override
  String get daily_reward => 'Günlük Ödül';

  @override
  String get claim_reward => 'Ödülü Al';

  @override
  String day_streak(Object X) {
    return '$X gün serisi';
  }

  @override
  String get come_back_tomorrow => 'Yarın tekrar gel!';

  @override
  String get keep_going => 'Devam et!';

  @override
  String get reward_claimed => 'Ödül Alındı!';

  @override
  String amazing_streak(Object X) {
    return 'Harika! $X gün serisi!';
  }

  @override
  String get whatsYourName => 'ADIN NE?';

  @override
  String get enterYourName => 'Adını gir';

  @override
  String get continueBtn => 'DEVAM';

  @override
  String get howWouldYouRate => 'SEVİYENİ NASIL';

  @override
  String get yourLevel => 'DEĞERLENDİRİRSİN?';

  @override
  String get beginner => 'BAŞLANGIÇ';

  @override
  String get intermediate => 'ORTA';

  @override
  String get advanced => 'İLERİ';

  @override
  String get beginnerDesc => 'Yeni başlıyorum. Çok az kelime biliyorum.';

  @override
  String get intermediateDesc =>
      'Temel konuşmalar yapabiliyor ve basit metinleri anlayabiliyorum.';

  @override
  String get advancedDesc =>
      'Akıcıyım veya neredeyse akıcıyım. Karmaşık konuları tartışabilirim.';

  @override
  String get whichLanguage => 'HANGİ DİLİ';

  @override
  String get doYouWantToLearn => 'ÖĞRENMEK İSTİYORSUN?';

  @override
  String get changeAnytime =>
      'Bunu istediğiniz zaman ayarlardan değiştirebilirsiniz';

  @override
  String get dontWorryVerify =>
      'Merak etme, bunu hızlı bir sohbetle doğrulayacağız!';

  @override
  String get startAssessment => 'DEĞERLENDİRMEYE BAŞLA';

  @override
  String get chatAssessment => 'SOHBET DEĞERLENDİRMESİ';

  @override
  String get typeYourAnswer => 'Cevabınızı yazın...';

  @override
  String get mojiIsTyping => 'Moji yazıyor...';

  @override
  String get send => 'GÖNDER';

  @override
  String get calibrationComplete => 'Kalibrasyon Tamamlandı!';

  @override
  String get basedOnYourAnswers =>
      'Cevaplarınıza göre, önerilen başlangıç seviyeniz:';

  @override
  String get proficiencyLevel => 'Yeterlilik Seviyesi';

  @override
  String get shopItemAppleName => 'Elma';

  @override
  String get shopItemAppleDescription => 'Sağlıklı bir atıştırmalık.';

  @override
  String get shopItemDonutName => 'Donut';

  @override
  String get shopItemDonutDescription => 'Tatlı ve yapış yapış.';

  @override
  String get shopItemPizzaName => 'Pizza Dilimi';

  @override
  String get shopItemPizzaDescription => 'Peynirli ve doyurucu.';

  @override
  String get shopItemSushiName => 'Sushi Seti';

  @override
  String get shopItemSushiDescription => 'Premium balık.';

  @override
  String get shopItemCoffeeName => 'Espresso';

  @override
  String get shopItemCoffeeDescription => 'Hızlı enerji artışı.';

  @override
  String get shopItemMedicineName => 'İlaç';

  @override
  String get shopItemMedicineDescription =>
      'Moji’yi tekrar sağlığına kavuşturur.';

  @override
  String get review => 'Tekrar';

  @override
  String reviewDueCount(int count) {
    return '$count bekliyor';
  }

  @override
  String reviewProgress(int current, int total) {
    return '$total içinden $current';
  }

  @override
  String get reviewShowAnswer => 'Cevabı göster';

  @override
  String get reviewGradeAgain => 'Tekrar';

  @override
  String get reviewGradeHard => 'Zor';

  @override
  String get reviewGradeGood => 'İyi';

  @override
  String get reviewGradeEasy => 'Kolay';

  @override
  String get reviewAllCaughtUp => 'Her şey tamam!';

  @override
  String get reviewNothingDue =>
      'Şu an tekrar edilecek bir şey yok. Sohbet et ya da bir test çöz, Moji zorlandığın yerleri hatırlasın.';

  @override
  String get reviewSessionComplete => 'Tekrar tamamlandı!';

  @override
  String reviewSessionSummary(int count) {
    return '$count tekrar edildi';
  }

  @override
  String get reviewDone => 'Bitti';

  @override
  String get reviewCorrectionPrompt => 'Doğrusu ne?';

  @override
  String get reviewVocabularyPrompt => 'Bu ne demek?';

  @override
  String get sceneryTitle => 'Manzara';

  @override
  String get shopItemBgMeadowName => 'Çayır';

  @override
  String get sceneInUse => 'Kullanımda';

  @override
  String get shopItemBgBlueName => 'Okyanus Mavisi';

  @override
  String get shopItemBgBlueDescription => 'Sakinleştirici mavi titreşimler.';

  @override
  String get shopItemBgForestName => 'Orman Yeşili';

  @override
  String get shopItemBgForestDescription => 'Doğal his.';

  @override
  String get shopItemBgSunsetName => 'Gündoğumu Turuncusu';

  @override
  String get shopItemBgSunsetDescription => 'Sıcak ve rahat.';

  @override
  String get shopItemBgGalaxyName => 'Galaksi Moru';

  @override
  String get shopItemBgGalaxyDescription => 'Bu dünyanın dışında.';

  @override
  String purchaseSuccessSingle(Object itemName) {
    return '$itemName satın alındı!';
  }

  @override
  String purchaseSuccessMultiple(Object itemName, Object quantity) {
    return '$itemName x$quantity satın alındı!';
  }

  @override
  String get mojiSleepNight =>
      'Şşş... Moji uyuyor. Uyandırmak için Moji\'ye dokun.';

  @override
  String get mojiWakeSuccess =>
      'Esneme... Moji şimdi uyanık! Hadi pratik yapalım!';

  @override
  String mojiAwakeFor(int minutes) {
    return '$minutes dk daha uyanık';
  }

  @override
  String get levelsScreenTitle => 'Seviyeler';

  @override
  String get levelStatusCurrent => 'Mevcut Seviye';

  @override
  String get levelStatusCompleted => 'Tamamlandı';

  @override
  String get levelRewardLabel => 'Ödül';

  @override
  String get quizPausedTitle => 'Duraklatıldı';

  @override
  String get quizPausedPrompt => 'Devam etmek mi yoksa çıkmak mı?';

  @override
  String get quizPlay => 'Oyna';

  @override
  String get quizPause => 'Duraklat';

  @override
  String get quizExit => 'Çık';

  @override
  String get weeklyProgressTitle => 'Haftalık İlerleme';

  @override
  String dayLabel(int dayNum) {
    return 'Gün $dayNum';
  }

  @override
  String get dailyRewardHint => 'Günlük ödül için yarın geri dön';

  @override
  String get resetAppButton => 'Sıfırla';

  @override
  String get resetAppTitle => 'Uygulamayı Sıfırla';

  @override
  String get resetAppWarning =>
      'Bu, tüm ilerlemenizi silecektir.\n\nEmin misiniz?';

  @override
  String get resetAction => 'Sıfırla';

  @override
  String get resetSuccessMessage => 'Uygulama başarıyla sıfırlandı';

  @override
  String get selectYourCharacter => 'Karakterinizi seçin';

  @override
  String get characterDog => 'Köpek';

  @override
  String get characterCat => 'Kedi';

  @override
  String get characterBird => 'Kuş';

  @override
  String get characterRabbit => 'Tavşan';

  @override
  String get characterHamster => 'Hamster';

  @override
  String get characterParrot => 'Papağan';

  @override
  String get characterFox => 'Tilki';

  @override
  String get characterRaccoon => 'Rakun';

  @override
  String get characterRedPanda => 'Kızıl Panda';

  @override
  String get characterSkunk => 'Kokarca';

  @override
  String get characterOtter => 'Su Samuru';

  @override
  String get characterBeaver => 'Kunduz';

  @override
  String get characterSquirrel => 'Sincap';

  @override
  String get characterChinchilla => 'Çinçilla';

  @override
  String get characterMouse => 'Fare';

  @override
  String get characterHedgehog => 'Kirpi';

  @override
  String get characterBat => 'Yarasa';

  @override
  String get characterFennec => 'Fennek';

  @override
  String get characterKoala => 'Koala';

  @override
  String get characterWombat => 'Vombat';

  @override
  String get characterPanda => 'Panda';

  @override
  String get characterSloth => 'Tembel Hayvan';

  @override
  String get characterCapybara => 'Kapibara';

  @override
  String get characterPiglet => 'Domuz Yavrusu';

  @override
  String get characterSeal => 'Fok';

  @override
  String get characterPenguin => 'Penguen';

  @override
  String get characterFrog => 'Kurbağa';

  @override
  String get characterAxolotl => 'Aksolotl';

  @override
  String get characterGecko => 'Geko';

  @override
  String get characterChameleon => 'Bukalemun';

  @override
  String get aiUnavailableMessage =>
      'Zzz... Dil bağlantısı yeniden kurulurken Moji kestiriyor. Az sonra tekrar dene.';

  @override
  String get wardrobeTitle => 'Gardırop';

  @override
  String get slotHat => 'Şapka';

  @override
  String get slotNeck => 'Boyun';

  @override
  String get slotFace => 'Yüz';

  @override
  String get bodyTailColor => 'Gövde ve kuyruk rengi';

  @override
  String get eyeColor => 'Göz rengi';

  @override
  String get beakColor => 'Gaga Rengi';

  @override
  String get eyeStyleSolid => 'Tek renk';

  @override
  String get eyeStyleOddEyed => 'Farklı gözler';

  @override
  String get leftEye => 'Sol göz';

  @override
  String get rightEye => 'Sağ göz';

  @override
  String get colorLabel => 'Renk';

  @override
  String get scenarioObjectives => 'Hedefler';

  @override
  String scenarioProgress(int done, int total) {
    return '$done/$total';
  }

  @override
  String get scenarioCleared => 'Tamamlandı';

  @override
  String get scenarioBonusLabel => 'Bonus';

  @override
  String get scenarioCompleteTitle => 'Senaryo tamamlandı!';

  @override
  String scenarioCompleteSummary(int done, int total) {
    return '$total hedeften $done tanesi';
  }

  @override
  String get scenarioFirstClear => 'İlk tamamlama!';

  @override
  String get scenarioReplayNote =>
      'Tekrar ödülü — ilk tamamlama daha çok kazandırır.';

  @override
  String get scenarioContinue => 'Devam';

  @override
  String get scenarioFinish => 'Bitir';

  @override
  String get scenarioFinishTitle => 'Sahne bitsin mi?';

  @override
  String get scenarioFinishBody =>
      'Hâlâ tamamlanmamış hedefler var. Şimdi bitirirsen ödülün yalnızca bir kısmını alırsın ve senaryo tamamlanmamış kalır, böylece sonra düzgünce bitirebilirsin.';

  @override
  String get scenarioFinishConfirm => 'Yine de bitir';

  @override
  String get scenarioFinishCancel => 'Konuşmaya devam et';

  @override
  String get scenarioPartialTitle => 'Sahne bitti';

  @override
  String get scenarioPartialNote =>
      'Kısmi ödül — tam ödül için tüm hedefleri tamamla.';

  @override
  String get objCoffeeOrder => 'Bir içecek sipariş et';

  @override
  String get objCoffeeCustomize => 'Siparişini özelleştir';

  @override
  String get objCoffeePrice => 'Fiyatını sor';

  @override
  String get objCoffeeSmallTalk => 'Barista ile biraz sohbet et';

  @override
  String get objInterviewGreet => 'Kendini tanıt';

  @override
  String get objInterviewExperience => 'Deneyimini anlat';

  @override
  String get objInterviewStrength => 'Neden uygun olduğunu açıkla';

  @override
  String get objInterviewAsk => 'Pozisyon hakkında bir soru sor';

  @override
  String get objDirectionsAsk => 'Bir yere nasıl gidileceğini sor';

  @override
  String get objDirectionsClarify =>
      'Tekrar etmelerini ya da yavaş konuşmalarını iste';

  @override
  String get objDirectionsDistance => 'Ne kadar uzak olduğunu öğren';

  @override
  String get objDirectionsThank => 'Onlara doğru şekilde teşekkür et';

  @override
  String get objDoctorSymptom => 'Şikâyetini anlat';

  @override
  String get objDoctorDuration => 'Ne zamandan beri böyle olduğunu söyle';

  @override
  String get objDoctorQuestion => 'Ne yapman gerektiğini sor';

  @override
  String get objDoctorAllergy => 'Bir alerjini ya da kullandığın ilacı söyle';

  @override
  String get objShoppingFind => 'Bir ürünün nerede olduğunu sor';

  @override
  String get objShoppingSize => 'Beden, renk ya da nasıl durduğunu sor';

  @override
  String get objShoppingPrice => 'Fiyatı sor';

  @override
  String get objShoppingPay => 'Ödemesini yap';

  @override
  String get objRestaurantTable => 'Bir masa iste';

  @override
  String get objRestaurantOrder => 'Yemek sipariş et';

  @override
  String get objRestaurantDrink => 'İçecek bir şey sipariş et';

  @override
  String get objRestaurantBill => 'Hesabı iste';

  @override
  String get notificationsTitle => 'Bildirimler';

  @override
  String get notificationsEnable => 'Bana Moji’yi hatırlat';

  @override
  String get notificationsDesc =>
      'Moji sana ihtiyacı olduğunda, tekrar zamanı geldiğinde ve günlük ödülün hazır olduğunda haber verir.';

  @override
  String get notificationsBlocked => 'Bildirimler cihaz ayarlarında kapalı.';

  @override
  String get notifPetChannelName => 'Moji sana ihtiyaç duyuyor';

  @override
  String get notifPetChannelDesc =>
      'Evcil hayvanın acıktığında ya da mutsuz olduğunda hatırlatmalar';

  @override
  String get notifReviewChannelName => 'Tekrar hatırlatmaları';

  @override
  String get notifReviewChannelDesc =>
      'Tekrar zamanı gelen kelimeler için hatırlatmalar';

  @override
  String get notifRewardChannelName => 'Günlük ödül';

  @override
  String get notifRewardChannelDesc =>
      'Günlük ödülün hazır olduğunda hatırlatmalar';

  @override
  String get notifPetHungryTitle => 'Moji acıktı';

  @override
  String get notifPetHungryBody =>
      'Evcil hayvanının şu an bir atıştırmalığa ihtiyacı var.';

  @override
  String get notifPetSadTitle => 'Moji seni özledi';

  @override
  String get notifPetSadBody =>
      'Sensiz burası sessiz kaldı. Uğrayıp merhaba der misin?';

  @override
  String get notifReviewTitle => 'Tekrar zamanı';

  @override
  String notifReviewBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count kelime seni bekliyor.',
      one: '1 kelime seni bekliyor.',
    );
    return '$_temp0';
  }

  @override
  String get notifRewardTitle => 'Günlük ödülün hazır';

  @override
  String get notifRewardBody => 'Moji’nin sana bir şeyi var. Gel de al!';

  @override
  String get careTitle => 'Moji nasıl?';

  @override
  String get careStatFullness => 'Tokluk';

  @override
  String get careStatHappiness => 'Mutluluk';

  @override
  String get careStatHealth => 'Sağlık';

  @override
  String get careAllWell => 'Moji gayet iyi.';

  @override
  String get careNeedHungry => 'Moji aç';

  @override
  String get careNeedLonely => 'Moji keyifsiz';

  @override
  String get careNeedSick => 'Moji hasta';

  @override
  String get careSickPenalty =>
      'Moji hastayken tüm XP ve altınlar yarıya iner.';

  @override
  String get careFeedTitle => 'Moji’yi besle';

  @override
  String get careNoFood => 'Yiyecek kalmadı. Mağazadan alabilirsin.';

  @override
  String get careGoToShop => 'Mağazaya git';

  @override
  String get carePlay => 'Moji’yi sev';

  @override
  String get carePlayCooldown => 'Moji şimdilik yeterince sevildi.';

  @override
  String get playCatch => 'Top yakalamaca oyna';

  @override
  String get playCatchAgain => 'Tekrar oyna';

  @override
  String get playToyChest => 'Oyuncak sandığı';

  @override
  String get playBubbleBath => 'Köpük banyosu';

  @override
  String get playPounce => 'Köstebek avı';

  @override
  String get playPondHop => 'Gölette zıpla';

  @override
  String get playFetchWords => 'Kelimeleri getir';

  @override
  String get playNeedsWords => 'Oynamak için birkaç kelime daha öğren';

  @override
  String get careClose => 'Kapat';

  @override
  String careFedItem(String item) {
    return 'Moji $item yedi.';
  }

  @override
  String careCurrentFullness(int value) {
    return 'Şu anki tokluk: %$value';
  }

  @override
  String get scenarioSickPenalty => 'Moji hasta — ödüller yarıya indi';

  @override
  String get careDragToFeed => 'Beslemek için Moji’nin üstüne sürükle';

  @override
  String get bondStageCurious => 'Meraklı';

  @override
  String get bondStageFriendly => 'Arkadaş canlısı';

  @override
  String get bondStageAttached => 'Bağlı';

  @override
  String get bondStageDevoted => 'Sadık';

  @override
  String get bondStageInseparable => 'Ayrılmaz';

  @override
  String get bondMissesYou => 'Moji seni özledi';

  @override
  String get bondLonely => 'Moji uzun zamandır seni bekliyor';

  @override
  String get aiLimitQuizTitle => 'Bugünkü yapay zekâ testleri bitti';

  @override
  String get aiLimitMessageTitle => 'Bugünkü yapay zekâ mesajları bitti';

  @override
  String aiLimitUsage(int used, int total) {
    return 'Bugün $total hakkın $used tanesi kullanıldı';
  }

  @override
  String get aiLimitResets => 'Hakkın yarın yenilenecek.';

  @override
  String get aiLimitReviewOpen =>
      'Tekrar için öğretmene gerek yok — kartların her zaman burada.';

  @override
  String get aiLimitQuizOpen =>
      'Kendi kelimelerinden kurulan testler hâlâ burada.';

  @override
  String get aiLimitWatchAd => 'Bir tane daha için reklam izle';

  @override
  String get aiLimitGoPlus => 'Mimikin Plus al';

  @override
  String get premiumColumnFree => 'Ücretsiz';

  @override
  String get premiumColumnPlus => 'Plus';

  @override
  String get premiumRowQuizzes => 'Günlük yapay zekâ testi';

  @override
  String get premiumRowMessages => 'Günlük yapay zekâ mesajı';

  @override
  String get premiumRowAds => 'Geçiş reklamları';

  @override
  String get premiumValueShown => 'Gösterilir';

  @override
  String get premiumValueNone => 'Yok';

  @override
  String get premiumRowRollover => 'Kullanılmayan testler';

  @override
  String get premiumValueExpire => 'Sona erer';

  @override
  String get premiumValueRollOver => 'Devreder';

  @override
  String get premiumRowPetStats => 'Dostunun durumu';

  @override
  String get premiumValueDecay => 'Azalır';

  @override
  String get premiumValueDecaySlower => 'Daha yavaş azalır';

  @override
  String get premiumComingSoon => 'Abonelikler henüz açık değil.';

  @override
  String get premiumActive => 'Mimikin Plus etkin.';

  @override
  String get premiumRestore => 'Bir satın alımı geri yükle';

  @override
  String get premiumRestoreDone => 'Bu hesapta geri yüklenecek bir şey yok.';

  @override
  String get premiumPurchasePending => 'Mağazada tamamlanıyor…';

  @override
  String get categoryStyle => 'Stil';

  @override
  String get accessoryDescription => 'Moji için ufak bir şey.';

  @override
  String accessoryUnlocksAt(String stage) {
    return '$stage aşamasında açılır';
  }

  @override
  String get accessoryEarnedNotSold => 'Kazanılır, satılmaz';

  @override
  String get accessoryCapName => 'Şapka';

  @override
  String get accessoryTopHatName => 'Silindir şapka';

  @override
  String get accessoryCowboyHatName => 'Kovboy şapkası';

  @override
  String get accessoryCrownName => 'Taç';

  @override
  String get accessoryPartyHatName => 'Parti şapkası';

  @override
  String get accessoryBowTieName => 'Papyon';

  @override
  String get accessoryNecklaceName => 'Kolye';

  @override
  String get accessoryMustacheName => 'Bıyık';

  @override
  String get accessoryBeanieName => 'Bere';

  @override
  String get accessoryMortarboardName => 'Mezuniyet Kepi';

  @override
  String get accessoryCollarName => 'Çıngıraklı Tasma';

  @override
  String get accessoryGlassesName => 'Gözlük';

  @override
  String get accessorySunglassesName => 'Güneş Gözlüğü';

  @override
  String get accessoryMaskName => 'Maskeli Balo Maskesi';

  @override
  String get accessoryMedalName => 'Madalya';

  @override
  String get accessoryScarfName => 'Atkı';

  @override
  String get accessoryHeadphonesName => 'Kulaklık';

  @override
  String get accessoryWizardHatName => 'Büyücü Şapkası';

  @override
  String get accessoryFlowerCrownName => 'Çiçek Tacı';

  @override
  String get onboardingLanguageQuestion => 'Hangi dili konuşuyorsun?';

  @override
  String get onboardingLanguageConfirm => 'Devam et';

  @override
  String get onboardingPetQuestion => 'Kimi eve götüreceksin?';

  @override
  String get onboardingPetConfirm => 'Seç';

  @override
  String get onboardingLoginTitle => 'Dostunu kaydet';

  @override
  String get onboardingLoginGoogle => 'Google ile devam et';

  @override
  String get onboardingLoginEmail => 'E-posta ile devam et';

  @override
  String get onboardingLoginSkip => 'Belki sonra';

  @override
  String get onboardingLoginSubtitle => 'Giriş yap ki onu asla kaybetme.';

  @override
  String get accountEmailLabel => 'E-posta';

  @override
  String get accountPasswordLabel => 'Şifre';

  @override
  String get accountContinueAction => 'Devam et';

  @override
  String get accountConflictTitle => 'İki dost';

  @override
  String accountConflictBody(String email) {
    return '$email hesabının bir dostu var, bu telefonun da. Yalnızca biri kalabilir.';
  }

  @override
  String get accountConflictKeepThisDevice => 'Bu telefondaki dostu tut';

  @override
  String get accountConflictUseSaved => 'Kayıtlı dostu kullan';

  @override
  String get accountErrorInvalidEmail => 'Bu geçerli bir e-posta adresi değil.';

  @override
  String get accountErrorWeakPassword => 'En az 6 karakter kullan.';

  @override
  String get accountErrorSignIn =>
      'Giriş yapılamadı. Bilgilerini kontrol edip tekrar dene.';

  @override
  String get adsFreeCoins => 'Bedava Altın';

  @override
  String adsWatchForCoins(int coins) {
    return 'Video izle, +$coins kazan';
  }

  @override
  String adsLeftToday(int remaining, int total) {
    return 'Bugün $total hakkın $remaining tanesi kaldı';
  }

  @override
  String get adsNoneLeftToday => 'Bugünlük bu kadar';

  @override
  String get adsNotReady => 'Şu anda video yok';

  @override
  String adsEarnedCoins(int coins) {
    return '+$coins altın!';
  }

  @override
  String get privacyRedactedNotice =>
      'Kişisel bilgiler gönderilmeden önce gizlendi.';

  @override
  String quizQuestionCounter(int current, int total) {
    return 'SORU $current/$total';
  }

  @override
  String get quizPreparing => 'HAZIRLANIYOR...';

  @override
  String get quizPickAnswer => 'Doğru cevabı seç';

  @override
  String get quizWellDone => 'Aferin!';

  @override
  String get quizEncouragement => 'Yaparsın sen!';

  @override
  String petTutorialWelcome(String name) {
    return 'Tanıştığımıza sevindim, $name! Hadi birlikte öğrenelim.';
  }

  @override
  String get tutorialOfferTitle => 'TURA NE DERSİN?';

  @override
  String get tutorialWatch => 'GÖSTER';

  @override
  String get tutorialSkip => 'GEÇ';

  @override
  String get tutorialNext => 'İLERİ';

  @override
  String get tutorialBack => 'GERİ';

  @override
  String get tutorialDone => 'BİTTİ';

  @override
  String get tutorialReplay => 'Tanıtımları tekrar oynat';

  @override
  String get tutorialOfferHome => 'Ana ekranında kısa bir tur ister misin?';

  @override
  String get tutorialOfferQuiz => 'İlk testin. Kısa bir tur ister misin?';

  @override
  String get tutorialOfferChat => 'İlk sohbetin. Kısa bir tur ister misin?';

  @override
  String get tutorialOfferShop =>
      'Dükkâna ilk gelişin. Kısa bir tur ister misin?';

  @override
  String get tutorialOfferProfile => 'Profilinde kısa bir tur ister misin?';

  @override
  String get tutorialOfferReview =>
      'İlk tekrar turun. Kısa bir tur ister misin?';

  @override
  String get tutorialHomePet =>
      'Bu Moji. Ona dokun ya da okşamak için parmağını kafasında gezdir.';

  @override
  String get tutorialHomeLevel =>
      'Seviyen ve XP\'in. Sonraki seviyelerin neyi açtığını görmek için dokun.';

  @override
  String get tutorialHomeFeed =>
      'Yiyeceklerin. Bir atıştırmalık seç ve Moji\'nin üstüne sürükle.';

  @override
  String get tutorialHomeCare =>
      'Moji\'nin bir şeye ihtiyacı olduğunda çıkar. Bakmak için dokun.';

  @override
  String get tutorialHomeReview =>
      'Çalışma: sırası gelen kelimeleri tekrar et ve hatalarına bir daha göz at.';

  @override
  String get tutorialHomeSettings =>
      'Ayarlar: piksel yazı, hatırlatmalar ve bu turları yeniden oynatma.';

  @override
  String get tutorialNavTown =>
      'Kasaba: konuşma pratiği yapmak için bir binaya gir ya da test için okula uğra.';

  @override
  String get tutorialNavChat =>
      'Sohbetler: daha uzun konuşmalar ve rol yapma senaryoları.';

  @override
  String get tutorialNavShop =>
      'Dükkân: altınlarını yiyeceğe, stillere ve yeni dünyalara harca.';

  @override
  String get tutorialNavProfile =>
      'Profil: istatistiklerin, dillerin ve hesabın.';

  @override
  String get tutorialQuizHeader =>
      'Seviyen ve durman gerekirse diye duraklat düğmesi.';

  @override
  String get tutorialQuizQuestion =>
      'Soru. Üstteki rozet neyin ölçüldüğünü söyler.';

  @override
  String get tutorialQuizOptions =>
      'Bir cevap seç. Yanlışlar kaydedilir, sonra tekrar edebilirsin.';

  @override
  String get tutorialQuizContinue => 'Cevapladıktan sonra devam et.';

  @override
  String get tutorialChatMenu =>
      'Önceki sohbetlerin ve rol yapma senaryoların bu düğmenin arkasında.';

  @override
  String get tutorialChatMessages =>
      'Konuşmanız. Hatalar yol boyunca nazikçe düzeltilir.';

  @override
  String get tutorialChatInput => 'Buraya yaz. Kusursuz olmasına takılma.';

  @override
  String get tutorialShopCoins =>
      'Altınların. Çalışarak ve Moji\'ye bakarak kazanırsın.';

  @override
  String get tutorialShopTabs =>
      'Aradığına göre filtrele: yiyecek, süs ya da stil.';

  @override
  String get tutorialShopGrid =>
      'Almak için herhangi birine dokun. Yiyecek tükenir, gerisi sende kalır.';

  @override
  String get tutorialShopFreeCoins =>
      'Altının mı bitti? Kısa bir video izleyip doldur.';

  @override
  String get tutorialProfileAvatar =>
      'Görünüşünü ve gardırobunu değiştirmek için Moji\'ye dokun.';

  @override
  String get tutorialProfileStats =>
      'Seviyen ve bir sonrakine ne kadar kaldığı.';

  @override
  String get tutorialProfileDaily =>
      'Her gün ödül için geri gel. Uzun seriler daha çok kazandırır.';

  @override
  String get tutorialProfileLanguages =>
      'Konuştuğun dil ve öğrendiğin dil. İkisini de istediğin zaman değiştir.';

  @override
  String get tutorialProfileAccount =>
      'Bir hesap bağla ki Moji yeni telefonda da yanında olsun.';

  @override
  String get tutorialReviewCard =>
      'Cevabı hatırlamaya çalış, sonra kontrol için karta dokun.';

  @override
  String get tutorialReviewGrades =>
      'Cevabı göster ve nasıl gittiğini söyle. Zorlandığın kartlar daha erken döner.';

  @override
  String get tutorialReviewCount => 'Bu turda kaç kart kaldığı.';

  @override
  String get seasonPassNotOnSale => 'Bu geçiş henüz satışta değil.';

  @override
  String seasonPassBuy(String price) {
    return '$price satın al';
  }

  @override
  String seasonPassClaim(int count) {
    return 'Al ($count)';
  }

  @override
  String get seasonPassClaiming => 'Alınıyor…';

  @override
  String seasonPassClaimedToast(int count) {
    return 'Alındı: $count';
  }

  @override
  String seasonPassTierOf(int tier, int total) {
    return 'Kademe $tier / $total';
  }

  @override
  String seasonPassTrackLength(int count, int xp) {
    return '$count parça · $xp XP';
  }

  @override
  String get seasonPassComplete => 'Yol tamamlandı.';

  @override
  String seasonPassXpToNext(int xp) {
    return 'Sonraki parçaya $xp XP';
  }

  @override
  String seasonPassTierCost(int xp) {
    return '$xp XP';
  }

  @override
  String get seasonPassReady => 'Hazır';

  @override
  String get seasonPassTierClaimed => 'Alındı';

  @override
  String get seasonPassTryOn => 'Üzerinde dene';

  @override
  String get sceneAirfieldName => 'Gidişler';

  @override
  String get sceneCozyRoomName => 'Sıcacık Oda';

  @override
  String get sceneEnchantedMeadowName => 'Büyülü Çayır';

  @override
  String get sceneMushroomGladeName => 'Mantar Açıklığı';

  @override
  String get scenePumpkinPatchName => 'Balkabağı Tarlası';

  @override
  String get seasonPassScenePreviewOwned =>
      'Senin. Dünyayı gardıropta istediğin zaman değiştir.';

  @override
  String get seasonPassPreviewOwned => 'Senin. Gardıropta giydirebilirsin.';

  @override
  String get seasonPassPreviewLocked =>
      'Henüz senin değil — bu yalnızca bir bakış.';

  @override
  String get seasonPassPromise =>
      'Kademeler, geçişi aldıktan sonra kazandığın XP’yi sayar; bu yüzden geç almak sana hiçbir şeye mal olmaz. Burada hiçbir şey sona ermez: ulaştığın kademe kalır, ulaşmadığın seni bekler.';

  @override
  String seasonPassWaitingToClaim(int count) {
    return 'Alınmayı bekliyor: $count';
  }

  @override
  String get seasonPassEarnedByStudying => 'Çalışarak kazanılır';

  @override
  String get accessoryBandanaName => 'Gündoğumu Bandanası';

  @override
  String get accessoryBandanaCloudName => 'Bulut Bandanası';

  @override
  String get accessoryScarfDuskName => 'Alacakaranlık Atkısı';

  @override
  String get accessoryGogglesName => 'Uçuş Gözlüğü';

  @override
  String get accessoryGogglesBrassName => 'Pirinç Gözlük';

  @override
  String get accessoryBeanieDuskName => 'Alacakaranlık Beresi';

  @override
  String get accessoryFlightCapName => 'Pilot Başlığı';

  @override
  String get accessoryFlightCapCloudName => 'Bulut Pilot Başlığı';

  @override
  String get accessoryCowboyHatCharcoalName => 'Kömür Grisi Kovboy Şapkası';

  @override
  String get accessoryFlightScarfName => 'Rüzgârda Uçuşan Atkı';

  @override
  String get accessoryPumpkinWitchName => 'Balkabaklı Cadı Şapkası';

  @override
  String get accessoryDevilBandName => 'Şeytan Boynuzlu Saç Bandı';

  @override
  String get accessoryGhostBandanaName => 'Hayalet Bandana';

  @override
  String get accessoryBatChokerName => 'Yarasa Gerdanlığı';

  @override
  String get shopSectionTopUp => 'Altın Yükle';

  @override
  String get shopSectionPlus => 'Plus';

  @override
  String get shopSectionPass => 'Sezon Bileti';

  @override
  String get shopSectionItems => 'Eşyalar';

  @override
  String get topUpTitle => 'Altın Yükle';

  @override
  String topUpCoins(int coins) {
    return '$coins altın';
  }

  @override
  String topUpBonus(int percent) {
    return '+%$percent altın';
  }

  @override
  String get topUpBestValue => 'En avantajlı';

  @override
  String get topUpNotOpen => 'Altın paketleri henüz açık değil.';

  @override
  String topUpThanks(int coins) {
    return '$coins altın eklendi.';
  }

  @override
  String get deleteAccountButton => 'Hesabı Sil';

  @override
  String get deleteAccountTitle => 'Hesap silinsin mi?';

  @override
  String get deleteAccountWarning =>
      'Bu işlem evcil hayvanını, ilerlemeni, sohbetlerini ve hesabını hem bu telefondan hem de buluttan kalıcı olarak siler. Geri alınamaz.';

  @override
  String get deleteAction => 'Sil';

  @override
  String get deleteAccountDone => 'Hesabın ve verilerin silindi.';

  @override
  String get deleteAccountFailed =>
      'Hesap silinemedi. Bağlantını kontrol edip tekrar dene.';

  @override
  String get privacyPolicyButton => 'Gizlilik Politikası';

  @override
  String get privacyPolicyOpenFailed => 'Bağlantı açılamadı.';

  @override
  String get reportReply => 'Bu yanıtı bildir';

  @override
  String get reportReplyFailed => 'E-posta uygulaması açılamadı.';
}
