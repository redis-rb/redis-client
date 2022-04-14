ruby: `ruby 3.1.1p18 (2022-02-18 revision 53f5fc4236) [arm64-darwin21]`

redis-server: `Redis server v=6.2.6 sha=00000000:0 malloc=libc bits=64 build=c6f3693d1aced7d9`


### small string

```
            redis-rb:    28090.5 i/s
        redis-client:    27851.6 i/s - same-ish: difference falls within error

```

### large string

```
            redis-rb:    15430.7 i/s
        redis-client:    17476.4 i/s - same-ish: difference falls within error

```

### small list

```
            redis-rb:    21903.3 i/s
        redis-client:    24688.9 i/s - 1.13x  (± 0.00) faster

```

### large list

```
            redis-rb:      328.2 i/s
        redis-client:     1188.4 i/s - 3.62x  (± 0.00) faster

```

### small hash

```
            redis-rb:    13756.3 i/s
        redis-client:    15909.9 i/s - 1.16x  (± 0.00) faster

```

### large hash

```
            redis-rb:      304.9 i/s
        redis-client:     1173.5 i/s - 3.85x  (± 0.00) faster

```

