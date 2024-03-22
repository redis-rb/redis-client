ruby: `ruby 3.3.0 (2023-12-25 revision 5124f9ac75) [arm64-darwin23]`

redis-server: `Redis server v=7.0.12 sha=00000000:0 malloc=libc bits=64 build=a11d0151eabf466c`


### small string x 100

```
ruby 3.3.0 (2023-12-25 revision 5124f9ac75) +YJIT [arm64-darwin23]
             hiredis:     6723.1 i/s
                ruby:     5507.5 i/s - 1.22x  slower

```

### large string x 100

```
ruby 3.3.0 (2023-12-25 revision 5124f9ac75) +YJIT [arm64-darwin23]
             hiredis:      290.8 i/s
                ruby:      335.2 i/s - same-ish: difference falls within error

```

### small list x 100

```
ruby 3.3.0 (2023-12-25 revision 5124f9ac75) +YJIT [arm64-darwin23]
             hiredis:     3686.7 i/s
                ruby:     2437.1 i/s - 1.51x  slower

```

### large list

```
ruby 3.3.0 (2023-12-25 revision 5124f9ac75) +YJIT [arm64-darwin23]
             hiredis:     6725.9 i/s
                ruby:     4990.0 i/s - 1.35x  slower

```

### small hash x 100

```
ruby 3.3.0 (2023-12-25 revision 5124f9ac75) +YJIT [arm64-darwin23]
             hiredis:     3893.0 i/s
                ruby:     2994.7 i/s - 1.30x  slower

```

### large hash

```
ruby 3.3.0 (2023-12-25 revision 5124f9ac75) +YJIT [arm64-darwin23]
             hiredis:     4303.3 i/s
                ruby:     4244.6 i/s - same-ish: difference falls within error

```

