ruby: `ruby 3.1.1p18 (2022-02-18 revision 53f5fc4236) [x86_64-darwin20]`

redis-server: `Redis server v=6.2.6 sha=00000000:0 malloc=libc bits=64 build=c6f3693d1aced7d9`


### small string

```
            redis-rb:    24210.5 i/s
        redis-client:    25064.9 i/s - same-ish: difference falls within error

```

### large string

```
            redis-rb:     8217.8 i/s
        redis-client:    11276.2 i/s - 1.37x  (± 0.00) faster

```

### small list

```
            redis-rb:    18883.7 i/s
        redis-client:    22465.2 i/s - 1.19x  (± 0.00) faster

```

### large list

```
            redis-rb:      219.9 i/s
        redis-client:     1683.9 i/s - 7.66x  (± 0.00) faster

```

### small hash

```
            redis-rb:    15132.7 i/s
        redis-client:    22077.6 i/s - 1.46x  (± 0.00) faster

```

### large hash

```
            redis-rb:      219.4 i/s
        redis-client:     1542.3 i/s - 7.03x  (± 0.00) faster

```

