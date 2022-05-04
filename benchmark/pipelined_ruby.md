ruby: `ruby 3.1.1p18 (2022-02-18 revision 53f5fc4236) [arm64-darwin21]`

redis-server: `Redis server v=7.0.0 sha=00000000:0 malloc=libc bits=64 build=fa9ffba7836907da`


### small string

```
            redis-rb:     1019.3 i/s
        redis-client:     2605.2 i/s - 2.56x  (± 0.00) faster

```

### large string

```
            redis-rb:      262.7 i/s
        redis-client:      335.7 i/s - 1.28x  (± 0.00) faster

```

### small list

```
            redis-rb:      442.6 i/s
        redis-client:     1114.1 i/s - 2.52x  (± 0.00) faster

```

### large list

```
            redis-rb:        2.8 i/s
        redis-client:       14.4 i/s - 5.24x  (± 0.00) faster

```

### small hash

```
            redis-rb:      377.3 i/s
        redis-client:     1033.6 i/s - 2.74x  (± 0.00) faster

```

### large hash

```
            redis-rb:        2.6 i/s
        redis-client:       13.1 i/s - 4.98x  (± 0.00) faster

```

