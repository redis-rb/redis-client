ruby: `ruby 3.1.1p18 (2022-02-18 revision 53f5fc4236) [arm64-darwin21]`

redis-server: `Redis server v=6.2.6 sha=00000000:0 malloc=libc bits=64 build=c6f3693d1aced7d9`


### small string

```
            redis-rb:    29842.7 i/s
        redis-client:    30586.1 i/s - same-ish: difference falls within error

```

### large string

```
            redis-rb:    16277.1 i/s
        redis-client:    17956.9 i/s - same-ish: difference falls within error

```

### small list

```
            redis-rb:    23191.8 i/s
        redis-client:    24970.9 i/s - same-ish: difference falls within error

```

### large list

```
            redis-rb:      321.6 i/s
        redis-client:     1217.2 i/s - 3.78x  (± 0.00) faster

```

### small hash

```
            redis-rb:    19601.9 i/s
        redis-client:    23897.2 i/s - 1.22x  (± 0.00) faster

```

### large hash

```
            redis-rb:      296.7 i/s
        redis-client:     1133.1 i/s - 3.82x  (± 0.00) faster

```

