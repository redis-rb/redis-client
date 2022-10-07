ruby: `ruby 3.2.0dev (2022-10-07T07:03:33Z master e76217a7f3) [arm64-darwin21]`

redis-server: `Redis server v=7.0.4 sha=00000000:0 malloc=libc bits=64 build=ef6295796237ef48`


### small string

```
            redis-rb:     1214.3 i/s
        redis-client:     2782.4 i/s - 2.29x  (± 0.00) faster

```

### large string

```
            redis-rb:      247.6 i/s
        redis-client:      341.8 i/s - 1.38x  (± 0.00) faster

```

### small list

```
            redis-rb:      523.3 i/s
        redis-client:     1120.3 i/s - 2.14x  (± 0.00) faster

```

### large list

```
            redis-rb:        2.5 i/s
        redis-client:       12.7 i/s - 5.17x  (± 0.00) faster

```

### small hash

```
            redis-rb:      365.0 i/s
        redis-client:     1024.4 i/s - 2.81x  (± 0.00) faster

```

### large hash

```
            redis-rb:        2.3 i/s
        redis-client:       12.5 i/s - 5.40x  (± 0.00) faster

```

