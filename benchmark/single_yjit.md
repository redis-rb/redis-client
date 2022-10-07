ruby: `ruby 3.2.0dev (2022-10-07T07:03:33Z master e76217a7f3) [arm64-darwin21]`

redis-server: `Redis server v=7.0.4 sha=00000000:0 malloc=libc bits=64 build=ef6295796237ef48`


### small string

```
            redis-rb:    33850.0 i/s
        redis-client:    34157.9 i/s - same-ish: difference falls within error

```

### large string

```
            redis-rb:    17181.2 i/s
        redis-client:    19032.2 i/s - same-ish: difference falls within error

```

### small list

```
            redis-rb:    27435.4 i/s
        redis-client:    30408.5 i/s - 1.11x  (± 0.00) faster

```

### large list

```
            redis-rb:      386.6 i/s
        redis-client:     2061.7 i/s - 5.33x  (± 0.00) faster

```

### small hash

```
            redis-rb:    23657.3 i/s
        redis-client:    30254.9 i/s - 1.28x  (± 0.00) faster

```

### large hash

```
            redis-rb:      366.2 i/s
        redis-client:     1932.8 i/s - 5.28x  (± 0.00) faster

```

