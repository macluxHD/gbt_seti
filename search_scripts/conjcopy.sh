nohup rsync -v --size-only -e ssh gpu@10.17.0.11:/data/gpu/partial/gpu1/*raw /data3/guppi/gpu1 2>> ./out.txt &
nohup rsync -v --size-only -e ssh gpu@10.17.0.12:/data/gpu/partial/gpu2/*raw /data3/guppi/gpu2 2>> ./out.txt &
nohup rsync -v --size-only -e ssh gpu@10.17.0.13:/data/gpu/partial/gpu3/*raw /data3/guppi/gpu3 2>> ./out.txt & 
nohup rsync -v --size-only -e ssh gpu@10.17.0.14:/data/gpu/partial/gpu4/*raw /data3/guppi/gpu4 2>> ./out.txt &
nohup rsync -v --size-only -e ssh gpu@10.17.0.15:/data/gpu/partial/gpu5/*raw /data3/guppi/gpu5 2>> ./out.txt &
nohup rsync -v --size-only -e ssh gpu@10.17.0.16:/data/gpu/partial/gpu6/*raw /data3/guppi/gpu6 2>> ./out.txt &
nohup rsync -v --size-only -e ssh gpu@10.17.0.17:/data/gpu/partial/gpu7/*raw /data3/guppi/gpu7 2>> ./out.txt &
nohup rsync -v --size-only -e ssh gpu@10.17.0.18:/data/gpu/partial/gpu8/*raw /data3/guppi/gpu8 2>> ./out.txt &
nohup rsync -v --size-only -e ssh gpu@10.17.0.19:/data/gpu/partial/gpu9/*raw /data3/guppi/gpu9 2>> ./out.txt &
