ruby: `ruby 3.1.1p18 (2022-02-18 revision 53f5fc4236) [x86_64-darwin20]`

redis-server: `Redis server v=6.2.6 sha=00000000:0 malloc=libc bits=64 build=c6f3693d1aced7d9`


### small string

```
            redis-rb:    34925.9 i/s
        redis-client:    36527.8 i/s - same-ish: difference falls within error

```

### large string

```
            redis-rb:    11886.0 i/s
        redis-client:    12142.0 i/s - same-ish: difference falls within error

```

### small list

```
            redis-rb:    31773.8 i/s
        redis-client:    33617.2 i/s - 1.06x  (± 0.00) faster

```

### large list

```
            redis-rb:     4762.2 i/s
        redis-client:     7272.6 i/s - 1.53x  (± 0.00) faster

```

### small hash

```
            redis-rb:    28513.5 i/s
        redis-client:    34178.0 i/s - 1.20x  (± 0.00) faster

```

### large hash

```
            redis-rb:     2911.2 i/s
        redis-client:     5200.1 i/s - 1.79x  (± 0.00) faster

```

