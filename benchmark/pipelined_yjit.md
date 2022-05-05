ruby: `ruby 3.1.1p18 (2022-02-18 revision 53f5fc4236) [arm64-darwin21]`

redis-server: `Redis server v=7.0.0 sha=00000000:0 malloc=libc bits=64 build=fa9ffba7836907da`


### small string

```
            redis-rb:     1269.1 i/s
        redis-client:     2735.9 i/s - 2.16x  (± 0.00) faster

```

### large string

```
            redis-rb:      280.1 i/s
        redis-client:      356.2 i/s - 1.27x  (± 0.00) faster

```

### small list

```
            redis-rb:      446.3 i/s
        redis-client:     1109.2 i/s - 2.49x  (± 0.00) faster

```

### large list

```
            redis-rb:        2.8 i/s
        redis-client:       14.3 i/s - 5.14x  (± 0.00) faster

```

### small hash

```
            redis-rb:      375.5 i/s
        redis-client:     1042.1 i/s - 2.77x  (± 0.00) faster

```

### large hash

```
            redis-rb:        2.6 i/s
        redis-client:       13.1 i/s - 4.99x  (± 0.00) faster

```

