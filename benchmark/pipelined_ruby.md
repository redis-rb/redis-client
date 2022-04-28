ruby: `ruby 3.1.1p18 (2022-02-18 revision 53f5fc4236) [arm64-darwin21]`

redis-server: `Redis server v=6.2.6 sha=00000000:0 malloc=libc bits=64 build=c6f3693d1aced7d9`


### small string

```
            redis-rb:     1186.0 i/s
        redis-client:     2729.7 i/s - 2.30x  (± 0.00) faster

```

### large string

```
            redis-rb:      310.4 i/s
        redis-client:      315.1 i/s - same-ish: difference falls within error

```

### small list

```
            redis-rb:      470.5 i/s
        redis-client:     1111.3 i/s - 2.36x  (± 0.00) faster

```

### large list

```
            redis-rb:        2.4 i/s
        redis-client:       14.2 i/s - 5.80x  (± 0.00) faster

```

### small hash

```
            redis-rb:      367.1 i/s
        redis-client:     1045.8 i/s - 2.85x  (± 0.00) faster

```

### large hash

```
            redis-rb:        2.5 i/s
        redis-client:       12.8 i/s - 5.18x  (± 0.00) faster

```

