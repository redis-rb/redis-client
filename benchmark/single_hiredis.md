ruby: `ruby 3.1.1p18 (2022-02-18 revision 53f5fc4236) [arm64-darwin21]`

redis-server: `Redis server v=6.2.6 sha=00000000:0 malloc=libc bits=64 build=c6f3693d1aced7d9`


### small string

```
            redis-rb:    41808.9 i/s
        redis-client:    42309.8 i/s - same-ish: difference falls within error

```

### large string

```
            redis-rb:    20757.8 i/s
        redis-client:    18400.2 i/s - 1.13x  (± 0.00) slower

```

### small list

```
            redis-rb:    38956.0 i/s
        redis-client:    39307.3 i/s - same-ish: difference falls within error

```

### large list

```
            redis-rb:     7423.4 i/s
        redis-client:     9262.4 i/s - 1.25x  (± 0.00) faster

```

### small hash

```
            redis-rb:    36903.0 i/s
        redis-client:    39756.6 i/s - 1.08x  (± 0.00) faster

```

### large hash

```
            redis-rb:     4642.4 i/s
        redis-client:     6592.5 i/s - 1.42x  (± 0.00) faster

```

