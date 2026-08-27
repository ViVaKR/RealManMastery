# Score 


![alt text](image.png)
```bash
clang -c weighted_scores_neon.s -o weighted_scores_neon.o
clang test_weighted_scores.c weighted_scores_neon.o -o test_weighted_scores
./test_weighted_scores
```