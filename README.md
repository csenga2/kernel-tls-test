# kernel-tls-test

This is an experiment for the TLS capability of the linux kernel motivated by:

https://www.nginx.com/blog/improving-nginx-performance-with-kernel-tls/

### 1. checking the tls kernel module

On the host system to test whether the tls module is loaded or not:
`sudo lsmod | grep tls`  
if it's not loaded, load it with:
`sudo modprobe tls`  
Note: it seems like Ubuntu 22.04 LTS has it activated by default  

### 2. docker image  

I tried the official nginx image, but it still ships with openssl 1.1, so I ended up with building my own image.
The image contains the most recent baseline version of nginx on top of the latest Ubuntu LTS. I also created multiple
files(10M/1M/512kb/10kb) which can be used for testing nginx with and without utilizing kernel TLS.

### 3. nginx.conf  

It's a basic TLS configuration, the interesting part is:
`ssl_conf_command Options KTLS;`  
This is the line that makes the kernel TLS enabled.

### 4. testing
1. run the compose file:  
`docker-compose -f docker-compose.yaml --compatibility up --build`  
please note, `--compatibility` is for applying limits in this case
2. get the ip of current machine:  
   `ip a`
3. run tests with and without kTLS:  
```
docker run --rm -i peterevans/vegeta sh -c \
"echo 'GET https://${LOCAL_IP}/{TEST_SIZE}.html' | vegeta attack -rate=0 -max-workers=500 -max-body=10kb -duration=30s -insecure | tee results.bin | vegeta report"
```

### Results

I tested kTLS in two scenarios:
1. From another computer on my local network
2. From localhost (result_localhost)

On my home network I measured no significant difference(+0-2%) with kTLS, even if I introduced artificial limits on
CPU/MEM/bandwidth the situation remained the same, but on localhost, kTLS did it's magic:

#### kTLS disabled
```
user@tp1:~/own/gitrepos/kernel-tls-test$ docker run --rm -i peterevans/vegeta sh -c    "echo 'GET https://${LOCAL_IP}/10M.html' | vegeta attack -rate=0 -max-workers=500 -duration=30s -max-body=10kb -insecure | tee results.bin | vegeta report"
Requests      [total, rate, throughput]         2940, 97.84, 81.05
Duration      [total, attack, wait]             36.273s, 30.049s, 6.224s
Latencies     [min, mean, 50, 90, 95, 99, max]  358.17ms, 5.582s, 5.031s, 7.901s, 10.474s, 15.06s, 25.589s
Bytes In      [total, mean]                     30105600, 10240.00
Bytes Out     [total, mean]                     0, 0.00
Success       [ratio]                           100.00%
Status Codes  [code:count]                      200:2940
user@tp1:~/own/gitrepos/kernel-tls-test$ docker run --rm -i peterevans/vegeta sh -c    "echo 'GET https://${LOCAL_IP}/1M.html' | vegeta attack -rate=0 -max-workers=500 -duration=30s -max-body=10kb -insecure | tee results.bin | vegeta report"
Requests      [total, rate, throughput]         25391, 846.36, 824.66
Duration      [total, attack, wait]             30.79s, 30s, 789.545ms
Latencies     [min, mean, 50, 90, 95, 99, max]  13.384ms, 593.004ms, 578.049ms, 764.918ms, 957.224ms, 1.315s, 2.102s
Bytes In      [total, mean]                     260003840, 10240.00
Bytes Out     [total, mean]                     0, 0.00
Success       [ratio]                           100.00%
Status Codes  [code:count]                      200:25391
Error Set:
user@tp1:~/own/gitrepos/kernel-tls-test$ docker run --rm -i peterevans/vegeta sh -c    "echo 'GET https://${LOCAL_IP}/512kb.html' | vegeta attack -rate=0 -max-workers=1500 -duration=30s -max-body=10kb -insecure | tee results.bin | vegeta report"
Requests      [total, rate, throughput]         45696, 1521.85, 1483.79
Duration      [total, attack, wait]             30.797s, 30.027s, 770.081ms
Latencies     [min, mean, 50, 90, 95, 99, max]  107.431ms, 729.974ms, 690.166ms, 1.046s, 1.097s, 1.359s, 2.885s
Bytes In      [total, mean]                     467927040, 10240.00
Bytes Out     [total, mean]                     0, 0.00
Success       [ratio]                           100.00%
Status Codes  [code:count]                      200:45696  
Error Set:
```

#### kTLS enabled
```
Error Set:
user@tp1:~/own/gitrepos/kernel-tls-test$ docker run --rm -i peterevans/vegeta sh -c    "echo 'GET https://${LOCAL_IP}/10M.html' | vegeta attack -rate=0 -max-workers=500 -duration=30s -max-body=10kb -insecure | tee results.bin | vegeta report"
Requests      [total, rate, throughput]         3600, 119.99, 109.46
Duration      [total, attack, wait]             32.888s, 30.002s, 2.885s
Latencies     [min, mean, 50, 90, 95, 99, max]  181.622ms, 4.36s, 4.258s, 5.76s, 6.829s, 8.286s, 11.018s
Bytes In      [total, mean]                     36864000, 10240.00
Bytes Out     [total, mean]                     0, 0.00
Success       [ratio]                           100.00%
Status Codes  [code:count]                      200:3600
Error Set:
user@tp1:~/own/gitrepos/kernel-tls-test$ docker run --rm -i peterevans/vegeta sh -c    "echo 'GET https://${LOCAL_IP}/1M.html' | vegeta attack -rate=0 -max-workers=500 -duration=30s -max-body=10kb -insecure | tee results.bin | vegeta report"
Requests      [total, rate, throughput]         41360, 1378.13, 1350.67
Duration      [total, attack, wait]             30.622s, 30.012s, 610.16ms
Latencies     [min, mean, 50, 90, 95, 99, max]  11.176ms, 343.459ms, 332.989ms, 462.754ms, 497.367ms, 770.919ms, 1.393s
Bytes In      [total, mean]                     423526400, 10240.00
Bytes Out     [total, mean]                     0, 0.00
Success       [ratio]                           100.00%
Status Codes  [code:count]                      200:41360
Error Set:
user@tp1:~/own/gitrepos/kernel-tls-test$ docker run --rm -i peterevans/vegeta sh -c    "echo 'GET https://${LOCAL_IP}/512kb.html' | vegeta attack -rate=0 -max-workers=1500 -duration=30s -max-body=10kb -insecure | tee results.bin | vegeta report"
Requests      [total, rate, throughput]         68331, 2276.24, 2228.18
Duration      [total, attack, wait]             30.667s, 30.019s, 647.376ms
Latencies     [min, mean, 50, 90, 95, 99, max]  31.287ms, 497.316ms, 488.355ms, 688.063ms, 758.475ms, 954.362ms, 2.285s
Bytes In      [total, mean]                     699709440, 10240.00
Bytes Out     [total, mean]                     0, 0.00
Success       [ratio]                           100.00%
Status Codes  [code:count]                      200:68331  
Error Set:
```

Based on these  
**the throughput increased with: ~35/63/50%**  (10M/1M/512kb)  
**the mean latency decreased with: ~22/42/32%** (10M/1M/512kb)

#### Test machine spec  
i7-8750H  
Ubuntu 22.04LTS  
Docker 20.10.22  