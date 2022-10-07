ruby: `ruby 3.2.0dev (2022-10-07T07:03:33Z master e76217a7f3) [arm64-darwin21]`

redis-server: `Redis server v=7.0.4 sha=00000000:0 malloc=libc bits=64 build=ef6295796237ef48`


### small string

```
            redis-rb:     4841.5 i/s
        redis-client:     6160.7 i/s - 1.27x  (± 0.00) faster

```

### large string

```
            redis-rb:      368.4 i/s
        redis-client:      411.2 i/s - 1.12x  (± 0.00) faster

```

### small list

```
            redis-rb:     2733.6 i/s
        redis-client:     3493.2 i/s - 1.28x  (± 0.00) faster

```

### large list

```
            redis-rb:       73.2 i/s
        redis-client:      103.0 i/s - 1.41x  (± 0.00) faster

```

### small hash

```
            redis-rb:     2222.9 i/s
        redis-client:     4014.3 i/s - 1.81x  (± 0.00) faster

```

### large hash

```
            redis-rb:       44.4 i/s
        redis-client:       79.0 i/s - 1.78x  (± 0.00) faster

```

