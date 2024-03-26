ruby: `ruby 3.4.0dev (2024-03-19T14:18:56Z master 5c2937733c) [arm64-darwin23]`

redis-server: `Redis server v=7.0.12 sha=00000000:0 malloc=libc bits=64 build=a11d0151eabf466c`


### small string x 100

```
ruby 3.4.0dev (2024-03-19T14:18:56Z master 5c2937733c) +YJIT [arm64-darwin23]
             hiredis:     7148.9 i/s
                ruby:     5758.6 i/s - 1.24x  slower

```

### large string

```
ruby 3.4.0dev (2024-03-19T14:18:56Z master 5c2937733c) +YJIT [arm64-darwin23]
             hiredis:    13023.5 i/s
                ruby:    20246.4 i/s - 1.55x  faster

```

### small list x 100

```
ruby 3.4.0dev (2024-03-19T14:18:56Z master 5c2937733c) +YJIT [arm64-darwin23]
             hiredis:     3973.6 i/s
                ruby:     2668.7 i/s - 1.49x  slower

```

### large list

```
ruby 3.4.0dev (2024-03-19T14:18:56Z master 5c2937733c) +YJIT [arm64-darwin23]
             hiredis:     6706.8 i/s
                ruby:     6529.3 i/s - same-ish: difference falls within error

```

### small hash x 100

```
ruby 3.4.0dev (2024-03-19T14:18:56Z master 5c2937733c) +YJIT [arm64-darwin23]
             hiredis:     4001.6 i/s
                ruby:     3482.9 i/s - 1.15x  slower

```

### large hash

```
ruby 3.4.0dev (2024-03-19T14:18:56Z master 5c2937733c) +YJIT [arm64-darwin23]
             hiredis:     5511.9 i/s
                ruby:     5555.7 i/s - same-ish: difference falls within error

```

