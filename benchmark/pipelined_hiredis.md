ruby: `ruby 3.1.1p18 (2022-02-18 revision 53f5fc4236) [arm64-darwin21]`

redis-server: `Redis server v=7.0.0 sha=00000000:0 malloc=libc bits=64 build=fa9ffba7836907da`


### small string

```
            redis-rb:     5470.5 i/s
        redis-client:     6913.0 i/s - 1.26x  (± 0.00) faster

```

### large string

```
            redis-rb:      382.6 i/s
        redis-client:      437.7 i/s - 1.14x  (± 0.00) faster

```

### small list

```
            redis-rb:     2599.9 i/s
        redis-client:     3430.7 i/s - 1.32x  (± 0.00) faster

```

### large list

```
            redis-rb:       80.2 i/s
        redis-client:      108.6 i/s - 1.36x  (± 0.00) faster

```

### small hash

```
            redis-rb:     2412.7 i/s
        redis-client:     4143.8 i/s - 1.72x  (± 0.00) faster

```

### large hash

```
            redis-rb:       48.0 i/s
        redis-client:       79.4 i/s - 1.65x  (± 0.00) faster

```

