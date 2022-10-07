ruby: `ruby 3.2.0dev (2022-10-07T07:03:33Z master e76217a7f3) [arm64-darwin21]`

redis-server: `Redis server v=7.0.4 sha=00000000:0 malloc=libc bits=64 build=ef6295796237ef48`


### small string

```
            redis-rb:    33879.7 i/s
        redis-client:    34618.9 i/s - same-ish: difference falls within error

```

### large string

```
            redis-rb:    17491.1 i/s
        redis-client:    19211.4 i/s - same-ish: difference falls within error

```

### small list

```
            redis-rb:    27242.1 i/s
        redis-client:    30271.4 i/s - 1.11x  (± 0.00) faster

```

### large list

```
            redis-rb:      384.3 i/s
        redis-client:     2050.7 i/s - 5.34x  (± 0.00) faster

```

### small hash

```
            redis-rb:    23513.7 i/s
        redis-client:    30172.6 i/s - 1.28x  (± 0.00) faster

```

### large hash

```
            redis-rb:      358.6 i/s
        redis-client:     1916.3 i/s - 5.34x  (± 0.00) faster

```

