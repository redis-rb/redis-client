ruby: `ruby 3.1.1p18 (2022-02-18 revision 53f5fc4236) [arm64-darwin21]`

redis-server: `Redis server v=7.0.0 sha=00000000:0 malloc=libc bits=64 build=fa9ffba7836907da`


### small string

```
            redis-rb:    41490.9 i/s
        redis-client:    42519.9 i/s - same-ish: difference falls within error

```

### large string

```
            redis-rb:    20882.7 i/s
        redis-client:    18877.0 i/s - 1.11x  (± 0.00) slower

```

### small list

```
            redis-rb:    38592.2 i/s
        redis-client:    38920.2 i/s - same-ish: difference falls within error

```

### large list

```
            redis-rb:     7562.3 i/s
        redis-client:     8834.8 i/s - 1.17x  (± 0.00) faster

```

### small hash

```
            redis-rb:    37152.5 i/s
        redis-client:    39277.5 i/s - 1.06x  (± 0.00) faster

```

### large hash

```
            redis-rb:     4762.2 i/s
        redis-client:     6379.1 i/s - 1.34x  (± 0.00) faster

```

