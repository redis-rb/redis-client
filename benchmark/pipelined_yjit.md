ruby: `ruby 3.1.1p18 (2022-02-18 revision 53f5fc4236) [arm64-darwin21]`

redis-server: `Redis server v=7.0.0 sha=00000000:0 malloc=libc bits=64 build=fa9ffba7836907da`


### small string

```
            redis-rb:     1249.9 i/s
        redis-client:     2726.2 i/s - 2.18x  (± 0.00) faster

```

### large string

```
            redis-rb:      270.0 i/s
        redis-client:      346.1 i/s - 1.28x  (± 0.00) faster

```

### small list

```
            redis-rb:      448.1 i/s
        redis-client:     1119.5 i/s - 2.50x  (± 0.00) faster

```

### large list

```
            redis-rb:        2.7 i/s
        redis-client:       14.2 i/s - 5.25x  (± 0.00) faster

```

### small hash

```
            redis-rb:      375.4 i/s
        redis-client:     1043.9 i/s - 2.78x  (± 0.00) faster

```

### large hash

```
            redis-rb:        2.6 i/s
        redis-client:       13.1 i/s - 5.01x  (± 0.00) faster

```

