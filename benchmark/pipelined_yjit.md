ruby: `ruby 3.1.1p18 (2022-02-18 revision 53f5fc4236) [x86_64-darwin20]`

redis-server: `Redis server v=6.2.6 sha=00000000:0 malloc=libc bits=64 build=c6f3693d1aced7d9`


### small string

```
            redis-rb:      927.6 i/s
        redis-client:     2423.0 i/s - 2.61x  (± 0.00) faster

```

### large string

```
            redis-rb:      108.2 i/s
        redis-client:      109.8 i/s - same-ish: difference falls within error

```

### small list

```
            redis-rb:      338.1 i/s
        redis-client:     1087.1 i/s - 3.22x  (± 0.00) faster

```

### large list

```
            redis-rb:        1.5 i/s
        redis-client:       17.5 i/s - 11.49x  (± 0.00) faster

```

### small hash

```
            redis-rb:      231.9 i/s
        redis-client:     1094.0 i/s - 4.72x  (± 0.00) faster

```

### large hash

```
            redis-rb:        1.5 i/s
        redis-client:       16.3 i/s - 11.03x  (± 0.00) faster

```

