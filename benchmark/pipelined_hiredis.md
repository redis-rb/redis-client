ruby: `ruby 3.1.1p18 (2022-02-18 revision 53f5fc4236) [x86_64-darwin20]`

redis-server: `Redis server v=6.2.6 sha=00000000:0 malloc=libc bits=64 build=c6f3693d1aced7d9`


### small string

```
            redis-rb:     3248.2 i/s
        redis-client:     4277.4 i/s - 1.32x  (± 0.00) faster

```

### large string

```
            redis-rb:      162.1 i/s
        redis-client:      162.5 i/s - same-ish: difference falls within error

```

### small list

```
            redis-rb:     1800.2 i/s
        redis-client:     2341.2 i/s - 1.30x  (± 0.00) faster

```

### large list

```
            redis-rb:       43.7 i/s
        redis-client:       80.1 i/s - 1.83x  (± 0.00) faster

```

### small hash

```
            redis-rb:     1538.7 i/s
        redis-client:     2710.9 i/s - 1.76x  (± 0.00) faster

```

### large hash

```
            redis-rb:       25.8 i/s
        redis-client:       56.8 i/s - 2.20x  (± 0.00) faster

```

