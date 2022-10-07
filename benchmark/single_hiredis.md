ruby: `ruby 3.2.0dev (2022-10-07T07:03:33Z master e76217a7f3) [arm64-darwin21]`

redis-server: `Redis server v=7.0.4 sha=00000000:0 malloc=libc bits=64 build=ef6295796237ef48`


### small string

```
            redis-rb:    45216.1 i/s
        redis-client:    41666.2 i/s - same-ish: difference falls within error

```

### large string

```
            redis-rb:    22411.3 i/s
        redis-client:    19881.4 i/s - 1.13x  (± 0.00) slower

```

### small list

```
            redis-rb:    41304.2 i/s
        redis-client:    38191.0 i/s - 1.08x  (± 0.00) slower

```

### large list

```
            redis-rb:     7090.1 i/s
        redis-client:     8554.6 i/s - 1.21x  (± 0.00) faster

```

### small hash

```
            redis-rb:    38593.2 i/s
        redis-client:    38710.8 i/s - same-ish: difference falls within error

```

### large hash

```
            redis-rb:     4685.1 i/s
        redis-client:     6823.3 i/s - 1.46x  (± 0.00) faster

```

