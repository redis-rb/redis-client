ruby: `ruby 3.1.1p18 (2022-02-18 revision 53f5fc4236) [arm64-darwin21]`

redis-server: `Redis server v=7.0.0 sha=00000000:0 malloc=libc bits=64 build=fa9ffba7836907da`


### small string

```
            redis-rb:     5216.4 i/s
        redis-client:     6947.1 i/s - 1.33x  (± 0.00) faster

```

### large string

```
            redis-rb:      364.3 i/s
        redis-client:      409.8 i/s - 1.12x  (± 0.00) faster

```

### small list

```
            redis-rb:     2571.4 i/s
        redis-client:     3797.1 i/s - 1.48x  (± 0.00) faster

```

### large list

```
            redis-rb:       83.0 i/s
        redis-client:      121.3 i/s - 1.46x  (± 0.00) faster

```

### small hash

```
            redis-rb:     2407.0 i/s
        redis-client:     4375.8 i/s - 1.82x  (± 0.00) faster

```

### large hash

```
            redis-rb:       48.6 i/s
        redis-client:       80.6 i/s - 1.66x  (± 0.00) faster

```

