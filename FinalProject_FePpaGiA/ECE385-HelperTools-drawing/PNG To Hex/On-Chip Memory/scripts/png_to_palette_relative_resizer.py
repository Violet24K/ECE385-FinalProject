from PIL import Image
from collections import Counter
from scipy.spatial import KDTree
import numpy as np
def hex_to_rgb(num):
    h = str(num)
    return int(h[0:4], 16), int(('0x' + h[4:6]), 16), int(('0x' + h[6:8]), 16)
def rgb_to_hex(num):
    h = str(num)
    return int(h[0:4], 16), int(('0x' + h[4:6]), 16), int(('0x' + h[6:8]), 16)
filename = input("What's the image name? ")
new_w, new_h = map(int, input("What's the new height x width? Like 28 28. ").split(' '))
#palette_hex = ['0xFF0000', '0xF83800', '0xF0D0B0', '0x503000', '0xFFE0A8', '0x0058F8', '0xFCFCFC', '0xBCBCBC', '0xA40000', '0xD82800', '0xFC7460', '0xFCBCB0', '0xF0BC3C', '0xAEACAE', '0x363301', '0x6C6C01', '0xBBBD00', '0x88D500', '0x398802', '0x65B0FF', '0x155ED8', '0x800080', '0x24188A']


# tree
#palette_hex = ['0x000000', '0x286F58','0x289260']

# mountain
#palette_hex = ['0x000000', '0x5D4A48', '0x6B6052', '0x756C59', '0x597960', '0x618463', '0x4F695A', '0x7BA4B7', '0x8AAFC0', '0xADD3E1', '0x667485', '0x8593A6']



# santa
#palette_hex = ['0x000000', '0x1A1813', '0x003119', '0xF3F0E8', '0xFFFCFC', '0x353333', '0x545353', '0x999696', '0x360000', '0xBF1919', '0x7C0202', '0x016740', '0xE1AE98', '0x0057CF', '0x1DD38F', '0xEF867F']

# cursor
#palette_hex = ['0x000000', '0xFFFFFF', '0xAAAAAA', '0xDCDCDC']

# cloud
#palette_hex = ['0x000000', '0xDAECF2', '0x97C5E7', '0xB0D4EF', '0xC6E0F4']

# bar0
palette_hex = ['0x000000', '0xF4F4F4', '0xFBFBFB', '0xFFFFFF' '0xDFDFDF', '0xD9D9D9', '0xDBDBDB']
palette_rgb = [hex_to_rgb(color) for color in palette_hex]

pixel_tree = KDTree(palette_rgb)
im = Image.open("../sprite_originals/" + filename+ ".png") #Can be many different formats.
im = im.convert("RGBA")
im = im.resize((new_w, new_h),Image.ANTIALIAS) # regular resize
pix = im.load()
pix_freqs = Counter([pix[x, y] for x in range(im.size[0]) for y in range(im.size[1])])
pix_freqs_sorted = sorted(pix_freqs.items(), key=lambda x: x[1])
pix_freqs_sorted.reverse()
print(pix)
outImg = Image.new('RGB', im.size, color='white')
outFile = open("../sprite_bytes/" + filename + '.txt', 'w')
i = 0
for y in range(im.size[1]):
    for x in range(im.size[0]):
        pixel = im.getpixel((x,y))
        print(pixel)
        if(pixel[3] < 200):
            outImg.putpixel((x,y), palette_rgb[0])
            outFile.write("%x\n" % (0))
            print(i)
        else:
            index = pixel_tree.query(pixel[:3])[1]
            outImg.putpixel((x,y), palette_rgb[index])
            outFile.write("%x\n" % (index))
        i += 1
outFile.close()
outImg.save("../sprite_converted/" + filename + ".png")
