ruby: `ruby 3.2.0dev (2022-10-07T07:03:33Z master e76217a7f3) [arm64-darwin21]`

redis-server: `Redis server v=7.0.4 sha=00000000:0 malloc=libc bits=64 build=ef6295796237ef48`


### small string

```
            redis-rb:     1459.1 i/s
        redis-client:     4586.2 i/s - 3.14x  (± 0.00) faster

```

### large string

```
            redis-rb:      255.9 i/s
        redis-client:      358.6 i/s - 1.40x  (± 0.00) faster

```

### small list

```
            redis-rb:      543.4 i/s
        redis-client:     1787.4 i/s - 3.29x  (± 0.00) faster

```

### large list

```
            redis-rb:        2.4 i/s
        redis-client:       24.5 i/s - 10.28x  (± 0.00) faster

```

### small hash

```
            redis-rb:      455.9 i/s
        redis-client:     1699.0 i/s - 3.73x  (± 0.00) faster

```

### large hash

```
            redis-rb:        2.6 i/s
        redis-client:       21.1 i/s - 8.03x  (± 0.00) faster

```

