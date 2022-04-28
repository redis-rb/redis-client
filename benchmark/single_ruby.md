ruby: `ruby 3.1.1p18 (2022-02-18 revision 53f5fc4236) [arm64-darwin21]`

redis-server: `Redis server v=6.2.6 sha=00000000:0 malloc=libc bits=64 build=c6f3693d1aced7d9`


### small string

```
            redis-rb:    30852.3 i/s
        redis-client:    31883.3 i/s - same-ish: difference falls within error

```

### large string

```
            redis-rb:    18538.1 i/s
        redis-client:    19720.6 i/s - 1.06x  (± 0.00) faster

```

### small list

```
            redis-rb:    24329.6 i/s
        redis-client:    26447.2 i/s - 1.09x  (± 0.00) faster

```

### large list

```
            redis-rb:      392.3 i/s
        redis-client:     1266.6 i/s - 3.23x  (± 0.00) faster

```

### small hash

```
            redis-rb:    21367.2 i/s
        redis-client:    26040.0 i/s - 1.22x  (± 0.00) faster

```

### large hash

```
            redis-rb:      368.0 i/s
        redis-client:     1209.8 i/s - 3.29x  (± 0.00) faster

```

