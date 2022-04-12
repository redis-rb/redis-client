ruby: `ruby 3.1.1p18 (2022-02-18 revision 53f5fc4236) [arm64-darwin21]`

redis-server: `Redis server v=6.2.6 sha=00000000:0 malloc=libc bits=64 build=c6f3693d1aced7d9`


### small string

```
            redis-rb:    36919.6 i/s
        redis-client:    35263.7 i/s - same-ish: difference falls within error

```

### large string

```
            redis-rb:    20329.0 i/s
        redis-client:    21680.9 i/s - same-ish: difference falls within error

```

### small list

```
            redis-rb:    26610.6 i/s
        redis-client:    29126.4 i/s - 1.09x  (± 0.00) faster

```

### large list

```
            redis-rb:      403.4 i/s
        redis-client:     1379.6 i/s - 3.42x  (± 0.00) faster

```

### small hash

```
            redis-rb:    22763.0 i/s
        redis-client:    28567.1 i/s - 1.25x  (± 0.00) faster

```

### large hash

```
            redis-rb:      344.1 i/s
        redis-client:     1322.6 i/s - 3.84x  (± 0.00) faster

```

