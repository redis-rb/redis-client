ruby: `ruby 3.1.1p18 (2022-02-18 revision 53f5fc4236) [arm64-darwin21]`

redis-server: `Redis server v=6.2.6 sha=00000000:0 malloc=libc bits=64 build=c6f3693d1aced7d9`


### small string

```
            redis-rb:    30938.4 i/s
        redis-client:    31980.4 i/s - same-ish: difference falls within error

```

### large string

```
            redis-rb:    18576.1 i/s
        redis-client:    19697.3 i/s - 1.06x  (± 0.00) faster

```

### small list

```
            redis-rb:    24214.9 i/s
        redis-client:    26757.0 i/s - 1.10x  (± 0.00) faster

```

### large list

```
            redis-rb:      387.6 i/s
        redis-client:     1269.2 i/s - 3.27x  (± 0.00) faster

```

### small hash

```
            redis-rb:    21089.9 i/s
        redis-client:    26062.7 i/s - 1.24x  (± 0.00) faster

```

### large hash

```
            redis-rb:      367.1 i/s
        redis-client:     1203.3 i/s - 3.28x  (± 0.00) faster

```

