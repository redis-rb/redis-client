ruby: `ruby 3.2.0dev (2022-10-07T07:03:33Z master e76217a7f3) [arm64-darwin21]`

redis-server: `Redis server v=7.0.4 sha=00000000:0 malloc=libc bits=64 build=ef6295796237ef48`


### small string

```
            redis-rb:     1204.3 i/s
        redis-client:     2823.3 i/s - 2.34x  (± 0.00) faster

```

### large string

```
            redis-rb:      248.3 i/s
        redis-client:      365.9 i/s - 1.47x  (± 0.00) faster

```

### small list

```
            redis-rb:      519.3 i/s
        redis-client:     1126.6 i/s - 2.17x  (± 0.00) faster

```

### large list

```
            redis-rb:        2.4 i/s
        redis-client:       12.8 i/s - 5.35x  (± 0.00) faster

```

### small hash

```
            redis-rb:      359.7 i/s
        redis-client:     1029.2 i/s - 2.86x  (± 0.00) faster

```

### large hash

```
            redis-rb:        2.3 i/s
        redis-client:       12.6 i/s - 5.42x  (± 0.00) faster

```

