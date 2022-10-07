ruby: `ruby 3.2.0dev (2022-10-07T07:03:33Z master e76217a7f3) [arm64-darwin21]`

redis-server: `Redis server v=7.0.4 sha=00000000:0 malloc=libc bits=64 build=ef6295796237ef48`


### small string

```
            redis-rb:     1471.0 i/s
        redis-client:     4573.8 i/s - 3.11x  (± 0.00) faster

```

### large string

```
            redis-rb:      257.0 i/s
        redis-client:      364.7 i/s - 1.42x  (± 0.00) faster

```

### small list

```
            redis-rb:      627.5 i/s
        redis-client:     1744.3 i/s - 2.78x  (± 0.00) faster

```

### large list

```
            redis-rb:        2.7 i/s
        redis-client:       24.6 i/s - 9.16x  (± 0.00) faster

```

### small hash

```
            redis-rb:      450.3 i/s
        redis-client:     1713.8 i/s - 3.81x  (± 0.00) faster

```

### large hash

```
            redis-rb:        2.5 i/s
        redis-client:       23.8 i/s - 9.42x  (± 0.00) faster

```

