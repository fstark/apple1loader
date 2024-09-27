import sys

def wozfromfile(file_path, adrs):
    try:
        with open(file_path, 'rb') as file:
            count = 0
            byte = file.read(1)
            while byte:
                if count==0 or adrs % 8 == 0:
                    print(f"{adrs:04X}: ", end='')
                    sep = ""
                sep = ","
                print( byte.hex(), end=" ")
                count += 1
                adrs += 1
                if adrs % 8 == 0:
                    print()
                byte = file.read(1)
        print()
    except FileNotFoundError:
        print("File not found.")

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print(f"Usage: python {sys.argv[0]} file_path hex_adrs")
    else:
        wozfromfile( sys.argv[1], int(sys.argv[2], 16)
 )
