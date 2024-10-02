import sys

def wozfromfile(file_path, adrs):
    try:
        with open(file_path, 'rb') as file:
            byte = file.read(1)
            line = ""
            sep = ""
            while byte:
                if len(line)+3 > 127:
                    print(line)
                    line = ""
                if line=="":
                    line = f"{adrs:X}:"
                    sep = ""
                line += f"{sep}{ord(byte):X}"
                sep = " "
                adrs += 1
                byte = file.read(1)
        print(line)
    except FileNotFoundError:
        print("File not found.")

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print(f"Usage: python {sys.argv[0]} file_path hex_adrs")
    else:
        wozfromfile( sys.argv[1], int(sys.argv[2], 16)
 )
