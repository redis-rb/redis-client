ruby: `ruby 3.1.1p18 (2022-02-18 revision 53f5fc4236) [arm64-darwin21]`

redis-server: `Redis server v=7.0.0 sha=00000000:0 malloc=libc bits=64 build=fa9ffba7836907da`


### small string

```
            redis-rb:    30613.5 i/s
        redis-client:    31272.9 i/s - same-ish: difference falls within error

```

### large string

```
            redis-rb:    17719.1 i/s
        redis-client:    19680.8 i/s - 1.11x  (± 0.00) faster

```

### small list

```
            redis-rb:    24238.9 i/s
        redis-client:    26521.1 i/s - 1.09x  (± 0.00) faster

```

### large list

```
            redis-rb:      403.1 i/s
        redis-client:     1251.7 i/s - 3.11x  (± 0.00) faster

```

### small hash

```
            redis-rb:    21916.6 i/s
        redis-client:    26036.2 i/s - 1.19x  (± 0.00) faster

```

### large hash

```
            redis-rb:      384.3 i/s
        redis-client:     1197.3 i/s - 3.12x  (± 0.00) faster

```

