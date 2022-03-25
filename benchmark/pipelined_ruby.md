ruby: `ruby 3.1.1p18 (2022-02-18 revision 53f5fc4236) [x86_64-darwin20]`

redis-server: `Redis server v=6.2.6 sha=00000000:0 malloc=libc bits=64 build=c6f3693d1aced7d9`


### small string

```
            redis-rb:      837.8 i/s
        redis-client:     1921.1 i/s - 2.29x  (± 0.00) faster

```

### large string

```
            redis-rb:      106.2 i/s
        redis-client:      107.2 i/s - same-ish: difference falls within error

```

### small list

```
            redis-rb:      302.6 i/s
        redis-client:      823.8 i/s - 2.72x  (± 0.00) faster

```

### large list

```
            redis-rb:        1.4 i/s
        redis-client:       11.5 i/s - 8.15x  (± 0.00) faster

```

### small hash

```
            redis-rb:      210.2 i/s
        redis-client:      805.6 i/s - 3.83x  (± 0.00) faster

```

### large hash

```
            redis-rb:        1.3 i/s
        redis-client:       11.0 i/s - 8.32x  (± 0.00) faster

```

