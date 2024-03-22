ruby: `ruby 3.3.0 (2023-12-25 revision 5124f9ac75) [arm64-darwin23]`

redis-server: `Redis server v=7.0.12 sha=00000000:0 malloc=libc bits=64 build=a11d0151eabf466c`


### small string x 100

```
ruby 3.3.0 (2023-12-25 revision 5124f9ac75) [arm64-darwin23]
             hiredis:     5416.0 i/s
                ruby:     2923.7 i/s - 1.85x  slower

```

### large string x 100

```
ruby 3.3.0 (2023-12-25 revision 5124f9ac75) [arm64-darwin23]
             hiredis:      286.7 i/s
                ruby:      302.3 i/s - same-ish: difference falls within error

```

### small list x 100

```
ruby 3.3.0 (2023-12-25 revision 5124f9ac75) [arm64-darwin23]
             hiredis:     2596.0 i/s
                ruby:     1155.6 i/s - 2.25x  slower

```

### large list

```
ruby 3.3.0 (2023-12-25 revision 5124f9ac75) [arm64-darwin23]
             hiredis:     6797.0 i/s
                ruby:     1388.9 i/s - 4.89x  slower

```

### small hash x 100

```
ruby 3.3.0 (2023-12-25 revision 5124f9ac75) [arm64-darwin23]
             hiredis:     3459.8 i/s
                ruby:     1170.4 i/s - 2.96x  slower

```

### large hash

```
ruby 3.3.0 (2023-12-25 revision 5124f9ac75) [arm64-darwin23]
             hiredis:     1345.9 i/s
                ruby:     1329.5 i/s - same-ish: difference falls within error

```

