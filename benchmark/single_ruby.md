ruby: `ruby 3.1.1p18 (2022-02-18 revision 53f5fc4236) [arm64-darwin21]`

redis-server: `Redis server v=7.0.0 sha=00000000:0 malloc=libc bits=64 build=fa9ffba7836907da`


### small string

```
            redis-rb:    30673.8 i/s
        redis-client:    31609.3 i/s - same-ish: difference falls within error

```

### large string

```
            redis-rb:    17829.2 i/s
        redis-client:    19749.7 i/s - 1.11x  (± 0.00) faster

```

### small list

```
            redis-rb:    24225.5 i/s
        redis-client:    27195.9 i/s - 1.12x  (± 0.00) faster

```

### large list

```
            redis-rb:      408.8 i/s
        redis-client:     1261.0 i/s - 3.08x  (± 0.00) faster

```

### small hash

```
            redis-rb:    21874.1 i/s
        redis-client:    26334.4 i/s - 1.20x  (± 0.00) faster

```

### large hash

```
            redis-rb:      384.0 i/s
        redis-client:     1198.4 i/s - 3.12x  (± 0.00) faster

```

