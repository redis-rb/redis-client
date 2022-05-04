ruby: `ruby 3.1.1p18 (2022-02-18 revision 53f5fc4236) [arm64-darwin21]`

redis-server: `Redis server v=7.0.0 sha=00000000:0 malloc=libc bits=64 build=fa9ffba7836907da`


### small string

```
            redis-rb:     1237.2 i/s
        redis-client:     2709.8 i/s - 2.19x  (± 0.00) faster

```

### large string

```
            redis-rb:      276.2 i/s
        redis-client:      356.4 i/s - 1.29x  (± 0.00) faster

```

### small list

```
            redis-rb:      445.4 i/s
        redis-client:     1103.9 i/s - 2.48x  (± 0.00) faster

```

### large list

```
            redis-rb:        2.7 i/s
        redis-client:       14.2 i/s - 5.26x  (± 0.00) faster

```

### small hash

```
            redis-rb:      374.0 i/s
        redis-client:     1043.9 i/s - 2.79x  (± 0.00) faster

```

### large hash

```
            redis-rb:        2.7 i/s
        redis-client:       13.1 i/s - 4.76x  (± 0.00) faster

```

