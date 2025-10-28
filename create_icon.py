from PIL import Image, ImageDraw, ImageFont
import os

# Icon boyutları
sizes = [192, 512]

# Her boyut için icon oluştur
for size in sizes:
    # Yeni bir resim oluştur (kahverengi arka plan)
    img = Image.new('RGB', (size, size), color='#8B4513')
    draw = ImageDraw.Draw(img)
    
    # Kahve fincanı çiz (basit)
    margin = size // 8
    cup_width = size - 2 * margin
    cup_height = int(cup_width * 0.8)
    
    # Fincan gövdesi
    cup_x = margin
    cup_y = margin + size // 10
    draw.rectangle([cup_x, cup_y, cup_x + cup_width, cup_y + cup_height], 
                   fill='white', outline='#D2691E', width=3)
    
    # Fincan kulpu
    handle_x = cup_x + cup_width
    handle_y = cup_y + cup_height // 4
    handle_size = cup_width // 4
    draw.arc([handle_x - 10, handle_y, handle_x + handle_size, handle_y + handle_size], 
             start=270, end=90, fill='#D2691E', width=5)
    
    # Kahve buharı (3 çizgi)
    steam_x = cup_x + cup_width // 2
    steam_y = cup_y - margin // 2
    for i in range(3):
        x = steam_x + (i - 1) * 15
        draw.line([(x, steam_y), (x, steam_y - 20)], fill='white', width=3)
    
    # Dosyayı kaydet
    icon_path = f'c:\\Users\\deneme\\Desktop\\reevpoints.tr\\static\\icons\\icon-{size}.png'
    img.save(icon_path)
    print(f"Icon oluşturuldu: {icon_path}")

print("Tüm iconlar başarıyla oluşturuldu!")
