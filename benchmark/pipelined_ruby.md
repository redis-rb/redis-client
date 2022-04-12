ruby: `ruby 3.1.1p18 (2022-02-18 revision 53f5fc4236) [arm64-darwin21]`

redis-server: `Redis server v=6.2.6 sha=00000000:0 malloc=libc bits=64 build=c6f3693d1aced7d9`


### small string

```
            redis-rb:     1269.9 i/s
        redis-client:     2877.1 i/s - 2.27x  (± 0.00) faster

```

### large string

```
            redis-rb:      333.7 i/s
        redis-client:      352.4 i/s - same-ish: difference falls within error

```

### small list

```
            redis-rb:      533.0 i/s
        redis-client:     1174.7 i/s - 2.20x  (± 0.00) faster

```

### large list

```
            redis-rb:        2.7 i/s
        redis-client:       15.4 i/s - 5.81x  (± 0.00) faster

```

### small hash

```
            redis-rb:      399.1 i/s
        redis-client:     1116.9 i/s - 2.80x  (± 0.00) faster

```

### large hash

```
            redis-rb:        2.5 i/s
        redis-client:       14.2 i/s - 5.67x  (± 0.00) faster

```

