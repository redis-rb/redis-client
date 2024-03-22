ruby: `ruby 3.3.0 (2023-12-25 revision 5124f9ac75) [arm64-darwin23]`

redis-server: `Redis server v=7.0.12 sha=00000000:0 malloc=libc bits=64 build=a11d0151eabf466c`


### small string x 100

```
ruby 3.3.0 (2023-12-25 revision 5124f9ac75) +YJIT [arm64-darwin23]
             hiredis:     6810.9 i/s
                ruby:     5613.1 i/s - 1.21x  slower

```

### large string x 100

```
ruby 3.3.0 (2023-12-25 revision 5124f9ac75) +YJIT [arm64-darwin23]
             hiredis:      312.1 i/s
                ruby:      316.3 i/s - same-ish: difference falls within error

```

### small list x 100

```
ruby 3.3.0 (2023-12-25 revision 5124f9ac75) +YJIT [arm64-darwin23]
             hiredis:     3644.1 i/s
                ruby:     2474.0 i/s - 1.47x  slower

```

### large list

```
ruby 3.3.0 (2023-12-25 revision 5124f9ac75) +YJIT [arm64-darwin23]
             hiredis:     6884.4 i/s
                ruby:     5473.2 i/s - 1.26x  slower

```

### small hash x 100

```
ruby 3.3.0 (2023-12-25 revision 5124f9ac75) +YJIT [arm64-darwin23]
             hiredis:     4033.9 i/s
                ruby:     3236.3 i/s - 1.25x  slower

```

### large hash

```
ruby 3.3.0 (2023-12-25 revision 5124f9ac75) +YJIT [arm64-darwin23]
             hiredis:     4753.7 i/s
                ruby:     4637.7 i/s - same-ish: difference falls within error

```

