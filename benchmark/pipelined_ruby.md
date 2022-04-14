ruby: `ruby 3.1.1p18 (2022-02-18 revision 53f5fc4236) [arm64-darwin21]`

redis-server: `Redis server v=6.2.6 sha=00000000:0 malloc=libc bits=64 build=c6f3693d1aced7d9`


### small string

```
            redis-rb:     1143.7 i/s
        redis-client:     2694.4 i/s - 2.36x  (± 0.00) faster

```

### large string

```
            redis-rb:      329.5 i/s
        redis-client:      311.4 i/s - same-ish: difference falls within error

```

### small list

```
            redis-rb:      476.9 i/s
        redis-client:     1091.1 i/s - 2.29x  (± 0.00) faster

```

### large list

```
            redis-rb:        2.2 i/s
        redis-client:       13.8 i/s - 6.15x  (± 0.00) faster

```

### small hash

```
            redis-rb:      369.2 i/s
        redis-client:     1018.5 i/s - 2.76x  (± 0.00) faster

```

### large hash

```
            redis-rb:        2.4 i/s
        redis-client:       12.7 i/s - 5.34x  (± 0.00) faster

```

