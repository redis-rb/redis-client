ruby: `ruby 3.2.0dev (2022-10-07T07:03:33Z master e76217a7f3) [arm64-darwin21]`

redis-server: `Redis server v=7.0.4 sha=00000000:0 malloc=libc bits=64 build=ef6295796237ef48`


### small string

```
            redis-rb:    32121.5 i/s
        redis-client:    33216.2 i/s - 1.03x  (± 0.00) faster

```

### large string

```
            redis-rb:    16819.8 i/s
        redis-client:    18485.0 i/s - same-ish: difference falls within error

```

### small list

```
            redis-rb:    24153.5 i/s
        redis-client:    27357.3 i/s - 1.13x  (± 0.00) faster

```

### large list

```
            redis-rb:      321.8 i/s
        redis-client:     1157.0 i/s - 3.60x  (± 0.00) faster

```

### small hash

```
            redis-rb:    21626.5 i/s
        redis-client:    26927.8 i/s - 1.25x  (± 0.00) faster

```

### large hash

```
            redis-rb:      302.9 i/s
        redis-client:     1118.5 i/s - 3.69x  (± 0.00) faster

```

