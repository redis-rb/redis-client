ruby: `ruby 3.1.1p18 (2022-02-18 revision 53f5fc4236) [arm64-darwin21]`

redis-server: `Redis server v=6.2.6 sha=00000000:0 malloc=libc bits=64 build=c6f3693d1aced7d9`


### small string

```
            redis-rb:     1210.6 i/s
        redis-client:     2677.1 i/s - 2.21x  (± 0.00) faster

```

### large string

```
            redis-rb:      329.2 i/s
        redis-client:      310.3 i/s - same-ish: difference falls within error

```

### small list

```
            redis-rb:      496.4 i/s
        redis-client:     1091.8 i/s - 2.20x  (± 0.00) faster

```

### large list

```
            redis-rb:        2.5 i/s
        redis-client:       13.7 i/s - 5.39x  (± 0.00) faster

```

### small hash

```
            redis-rb:      365.3 i/s
        redis-client:     1028.1 i/s - 2.81x  (± 0.00) faster

```

### large hash

```
            redis-rb:        2.5 i/s
        redis-client:       12.7 i/s - 5.16x  (± 0.00) faster

```

