ruby: `ruby 3.2.0dev (2022-10-07T07:03:33Z master e76217a7f3) [arm64-darwin21]`

redis-server: `Redis server v=7.0.4 sha=00000000:0 malloc=libc bits=64 build=ef6295796237ef48`


### small string

```
            redis-rb:     4850.3 i/s
        redis-client:     6132.4 i/s - 1.26x  (± 0.00) faster

```

### large string

```
            redis-rb:      369.3 i/s
        redis-client:      408.0 i/s - 1.10x  (± 0.00) faster

```

### small list

```
            redis-rb:     2743.1 i/s
        redis-client:     3545.1 i/s - 1.29x  (± 0.00) faster

```

### large list

```
            redis-rb:       73.2 i/s
        redis-client:      101.5 i/s - 1.39x  (± 0.00) faster

```

### small hash

```
            redis-rb:     2269.9 i/s
        redis-client:     3958.9 i/s - 1.74x  (± 0.00) faster

```

### large hash

```
            redis-rb:       44.2 i/s
        redis-client:       78.8 i/s - 1.78x  (± 0.00) faster

```

