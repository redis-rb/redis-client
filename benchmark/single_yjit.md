ruby: `ruby 3.1.1p18 (2022-02-18 revision 53f5fc4236) [arm64-darwin21]`

redis-server: `Redis server v=7.0.0 sha=00000000:0 malloc=libc bits=64 build=fa9ffba7836907da`


### small string

```
            redis-rb:    30820.3 i/s
        redis-client:    31049.6 i/s - same-ish: difference falls within error

```

### large string

```
            redis-rb:    17820.8 i/s
        redis-client:    19549.8 i/s - 1.10x  (± 0.00) faster

```

### small list

```
            redis-rb:    24136.1 i/s
        redis-client:    27098.1 i/s - 1.12x  (± 0.00) faster

```

### large list

```
            redis-rb:      404.5 i/s
        redis-client:     1264.3 i/s - 3.13x  (± 0.00) faster

```

### small hash

```
            redis-rb:    21827.5 i/s
        redis-client:    26258.3 i/s - 1.20x  (± 0.00) faster

```

### large hash

```
            redis-rb:      381.1 i/s
        redis-client:     1202.0 i/s - 3.15x  (± 0.00) faster

```

