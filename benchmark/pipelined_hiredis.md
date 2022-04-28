ruby: `ruby 3.1.1p18 (2022-02-18 revision 53f5fc4236) [arm64-darwin21]`

redis-server: `Redis server v=6.2.6 sha=00000000:0 malloc=libc bits=64 build=c6f3693d1aced7d9`


### small string

```
            redis-rb:     5327.1 i/s
        redis-client:     7001.5 i/s - 1.31x  (± 0.00) faster

```

### large string

```
            redis-rb:      491.2 i/s
        redis-client:      354.7 i/s - 1.39x  (± 0.00) slower

```

### small list

```
            redis-rb:     2536.2 i/s
        redis-client:     3727.6 i/s - 1.47x  (± 0.00) faster

```

### large list

```
            redis-rb:       82.6 i/s
        redis-client:      114.2 i/s - 1.38x  (± 0.00) faster

```

### small hash

```
            redis-rb:     2389.1 i/s
        redis-client:     4246.3 i/s - 1.78x  (± 0.00) faster

```

### large hash

```
            redis-rb:       47.0 i/s
        redis-client:       80.1 i/s - 1.70x  (± 0.00) faster

```

