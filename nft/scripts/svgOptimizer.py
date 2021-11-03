

def main():

    svg = ''' <polygon points="200,110 140,298 290,178 110,178 260,298"
              style="fill:gold;stroke:purple;stroke-width:5;fill-rule:nonzero;" />
              <text x="55" y="325" fill="brown">Congratulations! You bought the dip. </text>  '''
    print(f'original: \n{svg}')
    svg = svg.replace('"', "'")
    svg = svg.replace('<', "%3C")
    svg = svg.replace('>', "%3E")

    print(f'Final: \n{svg}')

main()
