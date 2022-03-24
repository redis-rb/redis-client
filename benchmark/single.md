ruby: `ruby 3.1.1p18 (2022-02-18 revision 53f5fc4236) [x86_64-darwin20]`

redis-server: `Redis server v=6.2.6 sha=00000000:0 malloc=libc bits=64 build=c6f3693d1aced7d9`


### small string

```
            redis-rb:    22424.0 i/s
   (YJIT) hiredis-rb:    36643.7 i/s - 1.63x  (± 0.00) faster
          hiredis-rb:    34896.9 i/s - 1.56x  (± 0.00) faster
 (YJIT) redis-client:    25684.1 i/s - 1.15x  (± 0.00) faster
        redis-client:    24994.1 i/s - 1.11x  (± 0.00) faster
     (YJIT) redis-rb:    24301.0 i/s - 1.08x  (± 0.00) faster

```

### large string

```
            redis-rb:     8278.0 i/s
   (YJIT) hiredis-rb:    12417.7 i/s - 1.50x  (± 0.00) faster
          hiredis-rb:    12193.8 i/s - 1.47x  (± 0.00) faster
 (YJIT) redis-client:    11877.1 i/s - 1.43x  (± 0.00) faster
        redis-client:    10792.3 i/s - 1.30x  (± 0.00) faster
     (YJIT) redis-rb:     8516.7 i/s - 1.03x  (± 0.00) faster

```

### small list

```
            redis-rb:    17097.1 i/s
   (YJIT) hiredis-rb:    32542.8 i/s - 1.90x  (± 0.00) faster
          hiredis-rb:    31524.1 i/s - 1.84x  (± 0.00) faster
 (YJIT) redis-client:    23016.8 i/s - 1.35x  (± 0.00) faster
        redis-client:    20855.9 i/s - 1.22x  (± 0.00) faster
     (YJIT) redis-rb:    19304.9 i/s - 1.13x  (± 0.00) faster

```

### large list

```
            redis-rb:      195.1 i/s
          hiredis-rb:     4844.5 i/s - 24.83x  (± 0.00) faster
   (YJIT) hiredis-rb:     4745.4 i/s - 24.32x  (± 0.00) faster
 (YJIT) redis-client:     1665.2 i/s - 8.53x  (± 0.00) faster
        redis-client:     1090.9 i/s - 5.59x  (± 0.00) faster
     (YJIT) redis-rb:      223.4 i/s - 1.15x  (± 0.00) faster

```

### small hash

```
            redis-rb:    13585.4 i/s
   (YJIT) hiredis-rb:    29766.1 i/s - 2.19x  (± 0.00) faster
          hiredis-rb:    28211.7 i/s - 2.08x  (± 0.00) faster
 (YJIT) redis-client:    22708.9 i/s - 1.67x  (± 0.00) faster
        redis-client:    20415.2 i/s - 1.50x  (± 0.00) faster
     (YJIT) redis-rb:    15641.5 i/s - 1.15x  (± 0.00) faster

```

### large hash

```
            redis-rb:      185.1 i/s
          hiredis-rb:     3023.6 i/s - 16.34x  (± 0.00) faster
   (YJIT) hiredis-rb:     2938.3 i/s - 15.87x  (± 0.00) faster
 (YJIT) redis-client:     1535.2 i/s - 8.29x  (± 0.00) faster
        redis-client:     1037.3 i/s - 5.60x  (± 0.00) faster
     (YJIT) redis-rb:      219.5 i/s - 1.19x  (± 0.00) faster

```

