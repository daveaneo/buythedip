

def main():

    svg = '''<circle style="fill:#ffffff;stroke:#0045bb;stroke-width:1.38;stroke-linejoin:round;stroke-opacity:1;stroke-miterlimit:4;stroke-dasharray:none" id="path846" cx="85" cy="85" r="74.659912" />
    <circle style="fill:#ffffff;stroke:#000000;stroke-width:4;stroke-linejoin:round;stroke-miterlimit:4;stroke-dasharray:none;stroke-opacity:0.31999999" id="path846-5" cx="85" cy="85" r="59.727936" />  '''
    print(f'original: \n{svg}')
    svg = svg.replace('"', "'")
    svg = svg.replace('<', "%3C")
    svg = svg.replace('>', "%3E")
    svg = svg.replace('#', "%23")
    # easier to create a dictionary and replace it that way, but..

    print(f'Final: \n{svg}')

main()
