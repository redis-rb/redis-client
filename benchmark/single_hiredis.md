ruby: `ruby 3.1.1p18 (2022-02-18 revision 53f5fc4236) [arm64-darwin21]`

redis-server: `Redis server v=6.2.6 sha=00000000:0 malloc=libc bits=64 build=c6f3693d1aced7d9`


### small string

```
            redis-rb:    47140.0 i/s
        redis-client:    48035.2 i/s - same-ish: difference falls within error

```

### large string

```
            redis-rb:    24362.7 i/s
        redis-client:    20751.8 i/s - 1.17x  (± 0.00) slower

```

### small list

```
            redis-rb:    44536.2 i/s
        redis-client:    45117.7 i/s - same-ish: difference falls within error

```

### large list

```
            redis-rb:     7649.0 i/s
        redis-client:    11286.0 i/s - 1.48x  (± 0.00) faster

```

### small hash

```
            redis-rb:    41412.3 i/s
        redis-client:    43766.1 i/s - same-ish: difference falls within error

```

### large hash

```
            redis-rb:     4696.1 i/s
        redis-client:     8216.4 i/s - 1.75x  (± 0.00) faster

```

