ruby: `ruby 3.2.0dev (2022-10-07T07:03:33Z master e76217a7f3) [arm64-darwin21]`

redis-server: `Redis server v=7.0.4 sha=00000000:0 malloc=libc bits=64 build=ef6295796237ef48`


### small string

```
            redis-rb:    32608.1 i/s
        redis-client:    33285.7 i/s - same-ish: difference falls within error

```

### large string

```
            redis-rb:    16925.9 i/s
        redis-client:    18477.8 i/s - same-ish: difference falls within error

```

### small list

```
            redis-rb:    24143.5 i/s
        redis-client:    27307.6 i/s - 1.13x  (± 0.00) faster

```

### large list

```
            redis-rb:      327.6 i/s
        redis-client:     1155.4 i/s - 3.53x  (± 0.00) faster

```

### small hash

```
            redis-rb:    21663.2 i/s
        redis-client:    26989.6 i/s - 1.25x  (± 0.00) faster

```

### large hash

```
            redis-rb:      306.1 i/s
        redis-client:     1129.7 i/s - 3.69x  (± 0.00) faster

```

