ruby: `ruby 3.1.1p18 (2022-02-18 revision 53f5fc4236) [arm64-darwin21]`

redis-server: `Redis server v=7.0.0 sha=00000000:0 malloc=libc bits=64 build=fa9ffba7836907da`


### small string

```
            redis-rb:    41844.9 i/s
        redis-client:    42348.2 i/s - same-ish: difference falls within error

```

### large string

```
            redis-rb:    20775.2 i/s
        redis-client:    18482.8 i/s - 1.12x  (± 0.00) slower

```

### small list

```
            redis-rb:    39427.9 i/s
        redis-client:    39829.7 i/s - same-ish: difference falls within error

```

### large list

```
            redis-rb:     7525.2 i/s
        redis-client:     9523.5 i/s - 1.27x  (± 0.00) faster

```

### small hash

```
            redis-rb:    37035.3 i/s
        redis-client:    40639.2 i/s - 1.10x  (± 0.00) faster

```

### large hash

```
            redis-rb:     4270.2 i/s
        redis-client:     6005.2 i/s - 1.41x  (± 0.00) faster

```

