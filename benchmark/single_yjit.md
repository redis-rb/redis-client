ruby: `ruby 3.1.1p18 (2022-02-18 revision 53f5fc4236) [arm64-darwin21]`

redis-server: `Redis server v=6.2.6 sha=00000000:0 malloc=libc bits=64 build=c6f3693d1aced7d9`


### small string

```
            redis-rb:    33600.9 i/s
        redis-client:    35287.5 i/s - same-ish: difference falls within error

```

### large string

```
            redis-rb:    20387.3 i/s
        redis-client:    21443.0 i/s - same-ish: difference falls within error

```

### small list

```
            redis-rb:    26678.9 i/s
        redis-client:    29502.8 i/s - 1.11x  (± 0.00) faster

```

### large list

```
            redis-rb:      397.4 i/s
        redis-client:     1386.2 i/s - 3.49x  (± 0.00) faster

```

### small hash

```
            redis-rb:    22669.8 i/s
        redis-client:    28649.1 i/s - 1.26x  (± 0.00) faster

```

### large hash

```
            redis-rb:      339.3 i/s
        redis-client:     1319.9 i/s - 3.89x  (± 0.00) faster

```

