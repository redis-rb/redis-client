ruby: `ruby 3.2.0dev (2022-10-07T07:03:33Z master e76217a7f3) [arm64-darwin21]`

redis-server: `Redis server v=7.0.4 sha=00000000:0 malloc=libc bits=64 build=ef6295796237ef48`


### small string

```
            redis-rb:    43966.6 i/s
        redis-client:    41358.8 i/s - 1.06x  (± 0.00) slower

```

### large string

```
            redis-rb:    21595.5 i/s
        redis-client:    19616.2 i/s - 1.10x  (± 0.00) slower

```

### small list

```
            redis-rb:    41283.0 i/s
        redis-client:    38379.8 i/s - 1.08x  (± 0.00) slower

```

### large list

```
            redis-rb:     7091.0 i/s
        redis-client:     8536.4 i/s - 1.20x  (± 0.00) faster

```

### small hash

```
            redis-rb:    38448.8 i/s
        redis-client:    38752.6 i/s - same-ish: difference falls within error

```

### large hash

```
            redis-rb:     4698.2 i/s
        redis-client:     6802.4 i/s - 1.45x  (± 0.00) faster

```

