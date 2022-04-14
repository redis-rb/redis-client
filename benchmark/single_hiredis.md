ruby: `ruby 3.1.1p18 (2022-02-18 revision 53f5fc4236) [arm64-darwin21]`

redis-server: `Redis server v=6.2.6 sha=00000000:0 malloc=libc bits=64 build=c6f3693d1aced7d9`


### small string

```
            redis-rb:    38990.4 i/s
        redis-client:    40400.2 i/s - same-ish: difference falls within error

```

### large string

```
            redis-rb:    18983.3 i/s
        redis-client:    16036.5 i/s - 1.18x  (± 0.00) slower

```

### small list

```
            redis-rb:    35982.5 i/s
        redis-client:    36957.4 i/s - same-ish: difference falls within error

```

### large list

```
            redis-rb:     7158.7 i/s
        redis-client:     8787.1 i/s - 1.23x  (± 0.00) faster

```

### small hash

```
            redis-rb:    35492.2 i/s
        redis-client:    39070.8 i/s - same-ish: difference falls within error

```

### large hash

```
            redis-rb:     4657.5 i/s
        redis-client:     6646.5 i/s - 1.43x  (± 0.00) faster

```

