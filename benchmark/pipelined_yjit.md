ruby: `ruby 3.1.1p18 (2022-02-18 revision 53f5fc4236) [arm64-darwin21]`

redis-server: `Redis server v=6.2.6 sha=00000000:0 malloc=libc bits=64 build=c6f3693d1aced7d9`


### small string

```
            redis-rb:     1178.3 i/s
        redis-client:     2728.4 i/s - 2.32x  (± 0.00) faster

```

### large string

```
            redis-rb:      316.9 i/s
        redis-client:      318.2 i/s - same-ish: difference falls within error

```

### small list

```
            redis-rb:      466.8 i/s
        redis-client:     1112.7 i/s - 2.38x  (± 0.00) faster

```

### large list

```
            redis-rb:        2.6 i/s
        redis-client:       14.2 i/s - 5.46x  (± 0.00) faster

```

### small hash

```
            redis-rb:      365.9 i/s
        redis-client:     1041.7 i/s - 2.85x  (± 0.00) faster

```

### large hash

```
            redis-rb:        2.5 i/s
        redis-client:       12.9 i/s - 5.20x  (± 0.00) faster

```

