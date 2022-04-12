ruby: `ruby 3.1.1p18 (2022-02-18 revision 53f5fc4236) [arm64-darwin21]`

redis-server: `Redis server v=6.2.6 sha=00000000:0 malloc=libc bits=64 build=c6f3693d1aced7d9`


### small string

```
            redis-rb:     1271.1 i/s
        redis-client:     2835.4 i/s - 2.23x  (± 0.00) faster

```

### large string

```
            redis-rb:      351.4 i/s
        redis-client:      358.1 i/s - same-ish: difference falls within error

```

### small list

```
            redis-rb:      535.1 i/s
        redis-client:     1167.9 i/s - 2.18x  (± 0.00) faster

```

### large list

```
            redis-rb:        2.7 i/s
        redis-client:       15.6 i/s - 5.86x  (± 0.00) faster

```

### small hash

```
            redis-rb:      403.2 i/s
        redis-client:     1112.5 i/s - 2.76x  (± 0.00) faster

```

### large hash

```
            redis-rb:        2.5 i/s
        redis-client:       14.3 i/s - 5.66x  (± 0.00) faster

```

