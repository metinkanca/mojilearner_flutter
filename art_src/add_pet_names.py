# -*- coding: utf-8 -*-
"""Add the 24 roster pets' names to every ARB, after `characterParrot`.

Names only -- an ARB entry per pet per language. They go in next to the six
that are already there so the block stays readable as one list.

Idempotent: a language that already has a key keeps whatever is in it, so
re-running after a human corrects a translation will not undo the correction.

These are machine-supplied and want a native read, the same caveat the
rabbit/hamster/parrot names carry. The ones most worth checking are where a
language shares one word between two animals (Indonesian and Vietnamese both
lean on "berang-berang" / "rai ca" for otter *and* beaver) and where the animal
has no native name at all and takes a loanword (axolotl, wombat, capybara).
"""
import io
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
L10N = os.path.join(HERE, '..', 'lib', 'l10n')

# Key order, which is also the order they appear in kPetTypes.
PETS = ['Fox', 'Raccoon', 'RedPanda', 'Skunk', 'Otter', 'Beaver', 'Squirrel',
        'Chinchilla', 'Mouse', 'Hedgehog', 'Bat', 'Fennec', 'Koala', 'Wombat',
        'Panda', 'Sloth', 'Capybara', 'Piglet', 'Seal', 'Penguin', 'Frog',
        'Axolotl', 'Gecko', 'Chameleon']

NAMES = {
'en': ['Fox', 'Raccoon', 'Red Panda', 'Skunk', 'Otter', 'Beaver', 'Squirrel', 'Chinchilla', 'Mouse', 'Hedgehog', 'Bat', 'Fennec', 'Koala', 'Wombat', 'Panda', 'Sloth', 'Capybara', 'Piglet', 'Seal', 'Penguin', 'Frog', 'Axolotl', 'Gecko', 'Chameleon'],
'es': ['Zorro', 'Mapache', 'Panda rojo', 'Mofeta', 'Nutria', 'Castor', 'Ardilla', 'Chinchilla', 'Ratón', 'Erizo', 'Murciélago', 'Fénec', 'Koala', 'Wómbat', 'Panda', 'Perezoso', 'Capibara', 'Cerdito', 'Foca', 'Pingüino', 'Rana', 'Ajolote', 'Gecko', 'Camaleón'],
'fr': ['Renard', 'Raton laveur', 'Panda roux', 'Mouffette', 'Loutre', 'Castor', 'Écureuil', 'Chinchilla', 'Souris', 'Hérisson', 'Chauve-souris', 'Fennec', 'Koala', 'Wombat', 'Panda', 'Paresseux', 'Capybara', 'Porcelet', 'Phoque', 'Manchot', 'Grenouille', 'Axolotl', 'Gecko', 'Caméléon'],
'de': ['Fuchs', 'Waschbär', 'Roter Panda', 'Stinktier', 'Otter', 'Biber', 'Eichhörnchen', 'Chinchilla', 'Maus', 'Igel', 'Fledermaus', 'Fennek', 'Koala', 'Wombat', 'Panda', 'Faultier', 'Wasserschwein', 'Ferkel', 'Robbe', 'Pinguin', 'Frosch', 'Axolotl', 'Gecko', 'Chamäleon'],
'it': ['Volpe', 'Procione', 'Panda rosso', 'Puzzola', 'Lontra', 'Castoro', 'Scoiattolo', 'Cincillà', 'Topo', 'Riccio', 'Pipistrello', 'Fennec', 'Koala', 'Vombato', 'Panda', 'Bradipo', 'Capibara', 'Maialino', 'Foca', 'Pinguino', 'Rana', 'Axolotl', 'Geco', 'Camaleonte'],
'pt': ['Raposa', 'Guaxinim', 'Panda-vermelho', 'Gambá', 'Lontra', 'Castor', 'Esquilo', 'Chinchila', 'Rato', 'Ouriço', 'Morcego', 'Fennec', 'Coala', 'Wombat', 'Panda', 'Preguiça', 'Capivara', 'Leitão', 'Foca', 'Pinguim', 'Sapo', 'Axolote', 'Lagartixa', 'Camaleão'],
'nl': ['Vos', 'Wasbeer', 'Rode panda', 'Stinkdier', 'Otter', 'Bever', 'Eekhoorn', 'Chinchilla', 'Muis', 'Egel', 'Vleermuis', 'Fennek', 'Koala', 'Wombat', 'Panda', 'Luiaard', 'Capibara', 'Big', 'Zeehond', 'Pinguïn', 'Kikker', 'Axolotl', 'Gekko', 'Kameleon'],
'pl': ['Lis', 'Szop', 'Panda czerwona', 'Skunks', 'Wydra', 'Bóbr', 'Wiewiórka', 'Szynszyla', 'Mysz', 'Jeż', 'Nietoperz', 'Fenek', 'Koala', 'Wombat', 'Panda', 'Leniwiec', 'Kapibara', 'Prosiaczek', 'Foka', 'Pingwin', 'Żaba', 'Aksolotl', 'Gekon', 'Kameleon'],
'ru': ['Лиса', 'Енот', 'Красная панда', 'Скунс', 'Выдра', 'Бобр', 'Белка', 'Шиншилла', 'Мышь', 'Ёж', 'Летучая мышь', 'Фенек', 'Коала', 'Вомбат', 'Панда', 'Ленивец', 'Капибара', 'Поросёнок', 'Тюлень', 'Пингвин', 'Лягушка', 'Аксолотль', 'Геккон', 'Хамелеон'],
'uk': ['Лисиця', 'Єнот', 'Червона панда', 'Скунс', 'Видра', 'Бобер', 'Білка', 'Шиншила', 'Миша', 'Їжак', 'Кажан', 'Фенек', 'Коала', 'Вомбат', 'Панда', 'Лінивець', 'Капібара', 'Порося', 'Тюлень', 'Пінгвін', 'Жаба', 'Аксолотль', 'Гекон', 'Хамелеон'],
'ja': ['キツネ', 'アライグマ', 'レッサーパンダ', 'スカンク', 'カワウソ', 'ビーバー', 'リス', 'チンチラ', 'ネズミ', 'ハリネズミ', 'コウモリ', 'フェネック', 'コアラ', 'ウォンバット', 'パンダ', 'ナマケモノ', 'カピバラ', 'コブタ', 'アザラシ', 'ペンギン', 'カエル', 'ウーパールーパー', 'ヤモリ', 'カメレオン'],
'ko': ['여우', '너구리', '레서판다', '스컹크', '수달', '비버', '다람쥐', '친칠라', '쥐', '고슴도치', '박쥐', '페넥여우', '코알라', '웜뱃', '판다', '나무늘보', '카피바라', '아기돼지', '물범', '펭귄', '개구리', '아홀로틀', '도마뱀붙이', '카멜레온'],
'zh': ['狐狸', '浣熊', '小熊猫', '臭鼬', '水獭', '海狸', '松鼠', '龙猫', '老鼠', '刺猬', '蝙蝠', '耳廓狐', '考拉', '袋熊', '熊猫', '树懒', '水豚', '小猪', '海豹', '企鹅', '青蛙', '六角恐龙', '壁虎', '变色龙'],
'ar': ['ثعلب', 'راكون', 'باندا حمراء', 'ظربان', 'قضاعة', 'قندس', 'سنجاب', 'شينشيلا', 'فأر', 'قنفذ', 'خفاش', 'فنك', 'كوالا', 'ومبت', 'باندا', 'كسلان', 'كابيبارا', 'خنزير صغير', 'فقمة', 'بطريق', 'ضفدع', 'أكسولوتل', 'أبو بريص', 'حرباء'],
'hi': ['लोमड़ी', 'रैकून', 'लाल पांडा', 'स्कंक', 'ऊदबिलाव', 'बीवर', 'गिलहरी', 'चिनचिला', 'चूहा', 'साही', 'चमगादड़', 'फेनेक', 'कोआला', 'वॉम्बैट', 'पांडा', 'स्लॉथ', 'कैपिबारा', 'सुअर का बच्चा', 'सील', 'पेंगुइन', 'मेंढक', 'एक्सोलोटल', 'छिपकली', 'गिरगिट'],
'tr': ['Tilki', 'Rakun', 'Kızıl Panda', 'Kokarca', 'Su Samuru', 'Kunduz', 'Sincap', 'Çinçilla', 'Fare', 'Kirpi', 'Yarasa', 'Fennek', 'Koala', 'Vombat', 'Panda', 'Tembel Hayvan', 'Kapibara', 'Domuz Yavrusu', 'Fok', 'Penguen', 'Kurbağa', 'Aksolotl', 'Geko', 'Bukalemun'],
'sv': ['Räv', 'Tvättbjörn', 'Röd panda', 'Skunk', 'Utter', 'Bäver', 'Ekorre', 'Chinchilla', 'Mus', 'Igelkott', 'Fladdermus', 'Ökenräv', 'Koala', 'Vombat', 'Panda', 'Sengångare', 'Kapybara', 'Smågris', 'Säl', 'Pingvin', 'Groda', 'Axolotl', 'Gecko', 'Kameleont'],
'no': ['Rev', 'Vaskebjørn', 'Rød panda', 'Stinkdyr', 'Oter', 'Bever', 'Ekorn', 'Chinchilla', 'Mus', 'Pinnsvin', 'Flaggermus', 'Ørkenrev', 'Koala', 'Vombat', 'Panda', 'Dovendyr', 'Kapybara', 'Smågris', 'Sel', 'Pingvin', 'Frosk', 'Axolotl', 'Gekko', 'Kameleon'],
'da': ['Ræv', 'Vaskebjørn', 'Rød panda', 'Stinkdyr', 'Odder', 'Bæver', 'Egern', 'Chinchilla', 'Mus', 'Pindsvin', 'Flagermus', 'Ørkenræv', 'Koala', 'Vombat', 'Panda', 'Dovendyr', 'Kapybara', 'Pattegris', 'Sæl', 'Pingvin', 'Frø', 'Axolotl', 'Gekko', 'Kamæleon'],
'fi': ['Kettu', 'Pesukarhu', 'Punapanda', 'Haisunäätä', 'Saukko', 'Majava', 'Orava', 'Chinchilla', 'Hiiri', 'Siili', 'Lepakko', 'Aavikkokettu', 'Koala', 'Vompatti', 'Panda', 'Laiskiainen', 'Kapybara', 'Porsas', 'Hylje', 'Pingviini', 'Sammakko', 'Aksolotli', 'Gekko', 'Kameleontti'],
'cs': ['Liška', 'Mýval', 'Panda červená', 'Skunk', 'Vydra', 'Bobr', 'Veverka', 'Činčila', 'Myš', 'Ježek', 'Netopýr', 'Fenek', 'Koala', 'Vombat', 'Panda', 'Lenochod', 'Kapybara', 'Sele', 'Tuleň', 'Tučňák', 'Žába', 'Axolotl', 'Gekon', 'Chameleon'],
'hu': ['Róka', 'Mosómedve', 'Vörös panda', 'Bűzös borz', 'Vidra', 'Hód', 'Mókus', 'Csincsilla', 'Egér', 'Sün', 'Denevér', 'Fenek', 'Koala', 'Vombat', 'Panda', 'Lajhár', 'Kapibara', 'Malac', 'Fóka', 'Pingvin', 'Béka', 'Axolotl', 'Gekkó', 'Kaméleon'],
'ro': ['Vulpe', 'Raton', 'Panda roșu', 'Sconcs', 'Vidră', 'Castor', 'Veveriță', 'Cincilă', 'Șoarece', 'Arici', 'Liliac', 'Fenec', 'Koala', 'Vombat', 'Panda', 'Leneș', 'Capibara', 'Purceluș', 'Focă', 'Pinguin', 'Broască', 'Axolotl', 'Gecko', 'Cameleon'],
'el': ['Αλεπού', 'Ρακούν', 'Κόκκινο πάντα', 'Μεφίτις', 'Βίδρα', 'Κάστορας', 'Σκίουρος', 'Τσιντσιλά', 'Ποντίκι', 'Σκαντζόχοιρος', 'Νυχτερίδα', 'Φενέκ', 'Κοάλα', 'Γουόμπατ', 'Πάντα', 'Βραδύπους', 'Καπιμπάρα', 'Γουρουνάκι', 'Φώκια', 'Πιγκουίνος', 'Βάτραχος', 'Αξολότλ', 'Γκέκο', 'Χαμαιλέοντας'],
'id': ['Rubah', 'Rakun', 'Panda Merah', 'Sigung', 'Berang-berang', 'Berang-berang Kanada', 'Tupai', 'Chinchilla', 'Tikus', 'Landak', 'Kelelawar', 'Fennec', 'Koala', 'Wombat', 'Panda', 'Kungkang', 'Kapibara', 'Anak Babi', 'Anjing Laut', 'Penguin', 'Katak', 'Axolotl', 'Tokek', 'Bunglon'],
'vi': ['Cáo', 'Gấu mèo', 'Gấu trúc đỏ', 'Chồn hôi', 'Rái cá', 'Hải ly', 'Sóc', 'Sóc chinchilla', 'Chuột', 'Nhím', 'Dơi', 'Cáo Fennec', 'Gấu koala', 'Wombat', 'Gấu trúc', 'Lười', 'Chuột lang nước', 'Heo con', 'Hải cẩu', 'Chim cánh cụt', 'Ếch', 'Kỳ giông', 'Tắc kè', 'Tắc kè hoa'],
'th': ['จิ้งจอก', 'แรคคูน', 'แพนด้าแดง', 'สกั๊งค์', 'นาก', 'บีเวอร์', 'กระรอก', 'ชินชิลล่า', 'หนู', 'เม่นแคระ', 'ค้างคาว', 'จิ้งจอกเฟนเนก', 'โคอาล่า', 'วอมแบต', 'แพนด้า', 'สลอธ', 'คาปิบารา', 'ลูกหมู', 'แมวน้ำ', 'เพนกวิน', 'กบ', 'แอกโซลอเติล', 'ตุ๊กแก', 'กิ้งก่าคาเมเลียน'],
}

ANCHOR = '"characterParrot"'


def main():
    missing = [p for p in NAMES if len(NAMES[p]) != len(PETS)]
    if missing:
        raise SystemExit('wrong name count for %s' % missing)

    files = sorted(f for f in os.listdir(L10N) if f.endswith('.arb'))
    for fn in files:
        lang = fn[len('app_'):-len('.arb')]
        if lang not in NAMES:
            raise SystemExit('no names for locale %r' % lang)
        path = os.path.join(L10N, fn)
        with io.open(path, encoding='utf-8') as fh:
            text = fh.read()

        added = []
        for key, value in zip(PETS, NAMES[lang]):
            full = 'character%s' % key
            if '"%s"' % full in text:
                continue
            added.append((full, value))
        if not added:
            print('%-12s already complete' % fn)
            continue

        # Insert after the anchor line, keeping the block's indentation.
        m = re.search(r'^([ \t]*)%s.*$' % re.escape(ANCHOR), text, re.M)
        if not m:
            raise SystemExit('%s: no %s line to insert after' % (fn, ANCHOR))
        indent = m.group(1)
        block = ''.join('\n%s"%s": %s,' % (indent, k, json.dumps(v, ensure_ascii=False))
                        for k, v in added)
        text = text[:m.end()] + block + text[m.end():]

        with io.open(path, 'w', encoding='utf-8', newline='') as fh:
            fh.write(text)
        # Prove it is still valid JSON and still decodes as UTF-8.
        with io.open(path, encoding='utf-8') as fh:
            json.load(fh)
        print('%-12s +%d' % (fn, len(added)))


if __name__ == '__main__':
    sys.exit(main())
