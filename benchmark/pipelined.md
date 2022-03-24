ruby: `ruby 3.1.1p18 (2022-02-18 revision 53f5fc4236) [x86_64-darwin20]`

redis-server: `Redis server v=6.2.6 sha=00000000:0 malloc=libc bits=64 build=c6f3693d1aced7d9`


### small string

```
            redis-rb:      831.0 i/s
   (YJIT) hiredis-rb:     3412.4 i/s - 4.11x  (± 0.00) faster
          hiredis-rb:     3143.9 i/s - 3.78x  (± 0.00) faster
 (YJIT) redis-client:     2944.3 i/s - 3.54x  (± 0.00) faster
        redis-client:     2263.1 i/s - 2.72x  (± 0.00) faster
     (YJIT) redis-rb:      920.2 i/s - 1.11x  (± 0.00) faster

```

### large string

```
            redis-rb:      109.6 i/s
   (YJIT) hiredis-rb:      169.2 i/s - 1.54x  (± 0.00) faster
          hiredis-rb:      166.8 i/s - 1.52x  (± 0.00) faster
        redis-client:      114.6 i/s - same-ish: difference falls within error
 (YJIT) redis-client:      113.4 i/s - same-ish: difference falls within error
     (YJIT) redis-rb:      110.8 i/s - same-ish: difference falls within error

```

### small list

```
            redis-rb:      315.1 i/s
   (YJIT) hiredis-rb:     1790.3 i/s - 5.68x  (± 0.00) faster
          hiredis-rb:     1754.7 i/s - 5.57x  (± 0.00) faster
 (YJIT) redis-client:     1198.9 i/s - 3.80x  (± 0.00) faster
        redis-client:      907.6 i/s - 2.88x  (± 0.00) faster
     (YJIT) redis-rb:      339.3 i/s - 1.08x  (± 0.00) faster

```

### large list

```
            redis-rb:        1.6 i/s
   (YJIT) hiredis-rb:       48.8 i/s - 31.14x  (± 0.00) faster
          hiredis-rb:       47.7 i/s - 30.43x  (± 0.00) faster
 (YJIT) redis-client:       16.8 i/s - 10.72x  (± 0.00) faster
        redis-client:       11.6 i/s - 7.40x  (± 0.00) faster
     (YJIT) redis-rb:        1.5 i/s - 1.03x  (± 0.00) slower

```

### small hash

```
            redis-rb:      221.5 i/s
   (YJIT) hiredis-rb:     1648.4 i/s - 7.44x  (± 0.00) faster
          hiredis-rb:     1590.4 i/s - 7.18x  (± 0.00) faster
 (YJIT) redis-client:     1164.2 i/s - 5.26x  (± 0.00) faster
        redis-client:      844.4 i/s - 3.81x  (± 0.00) faster
     (YJIT) redis-rb:      240.2 i/s - same-ish: difference falls within error

```

### large hash

```
            redis-rb:        1.5 i/s
   (YJIT) hiredis-rb:       28.7 i/s - 19.22x  (± 0.00) faster
          hiredis-rb:       26.1 i/s - 17.47x  (± 0.00) faster
 (YJIT) redis-client:       15.5 i/s - 10.40x  (± 0.00) faster
        redis-client:       10.4 i/s - 6.97x  (± 0.00) faster
     (YJIT) redis-rb:        1.4 i/s - 1.07x  (± 0.00) slower

```

