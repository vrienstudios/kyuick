mkdir -p ./bin/linux/amd64
cd ./src
nim c -f --passL:"-lavcodec -lswresample -lavutil -lavformat -lavdevice -lavfilter" ./kyuick.nim
cp ./kyuick.out ../bin/linux/amd64/kyu
