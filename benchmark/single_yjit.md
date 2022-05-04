ruby: `ruby 3.1.1p18 (2022-02-18 revision 53f5fc4236) [arm64-darwin21]`

redis-server: `Redis server v=7.0.0 sha=00000000:0 malloc=libc bits=64 build=fa9ffba7836907da`


### small string

```
            redis-rb:    30872.2 i/s
        redis-client:    31760.5 i/s - 1.03x  (± 0.00) faster

```

### large string

```
            redis-rb:    17664.3 i/s
        redis-client:    19755.0 i/s - 1.12x  (± 0.00) faster

```

### small list

```
            redis-rb:    24246.2 i/s
        redis-client:    27175.6 i/s - 1.12x  (± 0.00) faster

```

### large list

```
            redis-rb:      402.8 i/s
        redis-client:     1263.5 i/s - 3.14x  (± 0.00) faster

```

### small hash

```
            redis-rb:    21940.3 i/s
        redis-client:    26352.3 i/s - 1.20x  (± 0.00) faster

```

### large hash

```
            redis-rb:      378.7 i/s
        redis-client:     1200.7 i/s - 3.17x  (± 0.00) faster

```

