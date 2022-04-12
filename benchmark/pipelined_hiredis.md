ruby: `ruby 3.1.1p18 (2022-02-18 revision 53f5fc4236) [arm64-darwin21]`

redis-server: `Redis server v=6.2.6 sha=00000000:0 malloc=libc bits=64 build=c6f3693d1aced7d9`


### small string

```
            redis-rb:     5572.2 i/s
        redis-client:     7342.2 i/s - 1.32x  (± 0.00) faster

```

### large string

```
            redis-rb:      481.0 i/s
        redis-client:      440.5 i/s - same-ish: difference falls within error

```

### small list

```
            redis-rb:     2931.6 i/s
        redis-client:     4031.9 i/s - 1.38x  (± 0.00) faster

```

### large list

```
            redis-rb:       82.0 i/s
        redis-client:      134.0 i/s - 1.63x  (± 0.00) faster

```

### small hash

```
            redis-rb:     2353.8 i/s
        redis-client:     4662.5 i/s - 1.98x  (± 0.00) faster

```

### large hash

```
            redis-rb:       46.3 i/s
        redis-client:       96.5 i/s - 2.08x  (± 0.00) faster

```

