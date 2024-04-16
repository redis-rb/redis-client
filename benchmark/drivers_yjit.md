ruby: `ruby 3.4.0dev (2024-03-26T11:54:54Z master 2b08406cd0) [arm64-darwin23]`

redis-server: `Redis server v=7.0.12 sha=00000000:0 malloc=libc bits=64 build=a11d0151eabf466c`


### small string x 100

```
ruby 3.4.0dev (2024-03-26T11:54:54Z master 2b08406cd0) +YJIT [arm64-darwin23]
             hiredis:     6374.1 i/s
                ruby:     5179.1 i/s - 1.23x  slower

```

### large string

```
ruby 3.4.0dev (2024-03-26T11:54:54Z master 2b08406cd0) +YJIT [arm64-darwin23]
             hiredis:     9048.4 i/s
                ruby:    16196.0 i/s - 1.79x  faster

```

### small list x 100

```
ruby 3.4.0dev (2024-03-26T11:54:54Z master 2b08406cd0) +YJIT [arm64-darwin23]
             hiredis:     3589.3 i/s
                ruby:     2314.0 i/s - 1.55x  slower

```

### large list

```
ruby 3.4.0dev (2024-03-26T11:54:54Z master 2b08406cd0) +YJIT [arm64-darwin23]
             hiredis:     6176.7 i/s
                ruby:     5471.0 i/s - same-ish: difference falls within error

```

### small hash x 100

```
ruby 3.4.0dev (2024-03-26T11:54:54Z master 2b08406cd0) +YJIT [arm64-darwin23]
             hiredis:     3692.9 i/s
                ruby:     3087.0 i/s - same-ish: difference falls within error

```

### large hash

```
ruby 3.4.0dev (2024-03-26T11:54:54Z master 2b08406cd0) +YJIT [arm64-darwin23]
             hiredis:     4640.6 i/s
                ruby:     4741.6 i/s - same-ish: difference falls within error

```

