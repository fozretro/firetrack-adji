# Compile ./dist/gundroid.ssd
beebasm -v -i ./src/firetrack-adji.asm -do ./dist/firetrack-adji.ssd -title FTADJI -opt 3
# Expand it back out into the Beebs development workspace the OBJECT file for local running and to update .inf file for OBJECT
rm -rf ./dev/firetrack-adji-dist
perl ./bin/mmbutils/beeb getfile ./dist/firetrack-adji.ssd ./dev/firetrack-adji-dist
cp ./dev/firetrack-adji-dist/!FTADJI* ./dev/firetrack-adji