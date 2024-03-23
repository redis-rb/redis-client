ruby: `ruby 3.4.0dev (2024-03-19T14:18:56Z master 5c2937733c) [arm64-darwin23]`

redis-server: `Redis server v=7.0.12 sha=00000000:0 malloc=libc bits=64 build=a11d0151eabf466c`


### small string x 100

```
ruby 3.4.0dev (2024-03-19T14:18:56Z master 5c2937733c) [arm64-darwin23]
             hiredis:     4825.5 i/s
                ruby:     2863.4 i/s - 1.69x  slower

```

### large string x 100

```
ruby 3.4.0dev (2024-03-19T14:18:56Z master 5c2937733c) [arm64-darwin23]
             hiredis:      266.6 i/s
                ruby:      198.1 i/s - 1.35x  slower

```

### small list x 100

```
ruby 3.4.0dev (2024-03-19T14:18:56Z master 5c2937733c) [arm64-darwin23]
             hiredis:     2416.9 i/s
                ruby:     1223.3 i/s - 1.98x  slower

```

### large list

```
ruby 3.4.0dev (2024-03-19T14:18:56Z master 5c2937733c) [arm64-darwin23]
             hiredis:     5351.6 i/s
                ruby:     1718.0 i/s - 3.11x  slower

```

### small hash x 100

```
ruby 3.4.0dev (2024-03-19T14:18:56Z master 5c2937733c) [arm64-darwin23]
             hiredis:     2854.3 i/s
                ruby:     1294.4 i/s - 2.21x  slower

```

### large hash

```
ruby 3.4.0dev (2024-03-19T14:18:56Z master 5c2937733c) [arm64-darwin23]
             hiredis:     1580.6 i/s
                ruby:     1634.7 i/s - same-ish: difference falls within error

```

