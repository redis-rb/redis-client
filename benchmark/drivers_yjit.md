ruby: `ruby 3.4.0dev (2024-03-19T14:18:56Z master 5c2937733c) [arm64-darwin23]`

redis-server: `Redis server v=7.0.12 sha=00000000:0 malloc=libc bits=64 build=a11d0151eabf466c`


### small string x 100

```
ruby 3.4.0dev (2024-03-19T14:18:56Z master 5c2937733c) +YJIT [arm64-darwin23]
             hiredis:     6407.8 i/s
                ruby:     5852.0 i/s - same-ish: difference falls within error

```

### large string x 100

```
ruby 3.4.0dev (2024-03-19T14:18:56Z master 5c2937733c) +YJIT [arm64-darwin23]
             hiredis:      302.8 i/s
                ruby:      337.3 i/s - same-ish: difference falls within error

```

### small list x 100

```
ruby 3.4.0dev (2024-03-19T14:18:56Z master 5c2937733c) +YJIT [arm64-darwin23]
             hiredis:     4067.7 i/s
                ruby:     2721.5 i/s - 1.49x  slower

```

### large list

```
ruby 3.4.0dev (2024-03-19T14:18:56Z master 5c2937733c) +YJIT [arm64-darwin23]
             hiredis:     7138.7 i/s
                ruby:     6605.4 i/s - same-ish: difference falls within error

```

### small hash x 100

```
ruby 3.4.0dev (2024-03-19T14:18:56Z master 5c2937733c) +YJIT [arm64-darwin23]
             hiredis:     4219.8 i/s
                ruby:     3586.4 i/s - 1.18x  slower

```

### large hash

```
ruby 3.4.0dev (2024-03-19T14:18:56Z master 5c2937733c) +YJIT [arm64-darwin23]
             hiredis:     5240.9 i/s
                ruby:     5312.5 i/s - same-ish: difference falls within error

```

