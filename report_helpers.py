import geopandas as gpd
from PIL import Image, ImageDraw, ImageFont


def highlight_text(text, header=None, color='blue'):
    image = Image.new('RGB', (1150, 400), color = (255, 255, 255))
    draw = ImageDraw.Draw(image)
    font = ImageFont.truetype("./fonts/OpenSans-Regular.ttf", 150)
    font_small = ImageFont.truetype("./fonts/OpenSans-Regular.ttf", 50)

    draw.text((50, 50), header, font=font_small, fill='gray')
    draw.text((50, 90), text, font=font, fill=color)

    display(image)

