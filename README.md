Build the container

```shell
docker compose up
```

Put the .raw file we want to convert into the input folder

See [container-toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html) to be able to use GPU inside of container

Then open a shell inside of the container
```shell
docker run --runtime=nvidia --gpus all -it -v ./input:/input -v ./output:/output gbt_seti /bin/bash 
``` 

Run the conversion process. Afterwards it should be available in the output folder on the host system

```shell
time /usr/local/listen/bin/gpuspec -i ./input/blc3_guppi_57386_VOYAGER1_0004.0000.raw -B 2 -f 1032192 -t 15 -V -o ./output/VOYAGER_filterbank
```