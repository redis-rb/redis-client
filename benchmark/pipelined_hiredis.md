ruby: `ruby 3.1.1p18 (2022-02-18 revision 53f5fc4236) [arm64-darwin21]`

redis-server: `Redis server v=6.2.6 sha=00000000:0 malloc=libc bits=64 build=c6f3693d1aced7d9`


### small string

```
            redis-rb:     5335.6 i/s
        redis-client:     6823.6 i/s - 1.28x  (± 0.00) faster

```

### large string

```
            redis-rb:      479.0 i/s
        redis-client:      397.0 i/s - 1.21x  (± 0.00) slower

```

### small list

```
            redis-rb:     2815.6 i/s
        redis-client:     3766.3 i/s - 1.34x  (± 0.00) faster

```

### large list

```
            redis-rb:       79.6 i/s
        redis-client:      113.8 i/s - 1.43x  (± 0.00) faster

```

### small hash

```
            redis-rb:     2365.3 i/s
        redis-client:     4149.7 i/s - 1.75x  (± 0.00) faster

```

### large hash

```
            redis-rb:       45.8 i/s
        redis-client:       76.6 i/s - 1.67x  (± 0.00) faster

```

