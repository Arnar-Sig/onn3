/* 
 * csim.c - A cache simulator that can replay traces from Valgrind
 *     and output statistics such as number of hits, misses, and
 *     evictions.  The replacement policy is LRU.
 *
 * Implementation and assumptions:
 *  1. Each load/store can cause at most one cache miss. (I examined the trace,
 *     the largest request I saw was for 8 bytes).
 *  2. Instruction loads (I) are ignored, since we are only interested in evaluating
 *     data cache performance.
 *  3. Data modify (M) is treated as a load followed by a store to the same
 *     address. Hence, an M operation can result in two cache hits, or a miss and a
 *     hit plus an possible eviction.
 *
 */
#include <getopt.h>
#include <stdlib.h>
#include <unistd.h>
#include <stdio.h>
#include <assert.h>
#include <math.h>
#include <limits.h>
#include <string.h>
#include <errno.h>

/* Type: Memory address */
typedef unsigned long long int mem_addr_t;


/* Hér fyrir neðan eru ýmsar víðværar breytur skilgreindar.  Þið munuð nota þessar
   en þurfið líka að bæta við nokkrum í viðbót (t.d. skilgreiningu á línu og
   skilgreiningu á skyndiminninu sjálfu)
 */
 
/* Globals set by command line args */
int s = 0; /* set index bits */
int b = 0; /* block offset bits */
int E = 0; /* associativity */
char* trace_file = NULL;

/* Derived from command line args */
int S; /* number of sets */
int B; /* block size (bytes) */

/* Counters used to record cache statistics */
int miss_count = 0;
int hit_count = 0;
int eviction_count = 0;
unsigned long long int lru_counter = 1;

/* Hluturinn sem táknar eina línu */
struct Cache {
    int valid;
    int tag;
    long lru;
};

struct Cache** skyndiminni;


/* Býr til gagnagrind sem hermir eftir skyndiminni. Býr til fylki af bendum af stærð S sem tákna mengin og svo inni í hverju hólfi
er svo bendir á fylki af Cache hlutum af stærð E sem tákna línurnar */
void initCache()
{
    skyndiminni = malloc(S * sizeof(struct Cache*));
    for(int i =0; i<S; i++){
        skyndiminni[i] = malloc(E * sizeof(struct Cache));
        for(int l = 0; l<E; l++){
            skyndiminni[i][l].lru = 0;
            skyndiminni[i][l].tag = l;
            skyndiminni[i][l].valid = 0;
        }
    }
}


/* 
 * freeCache - free allocated memory
 */
void freeCache()
{
    for(int i=0; i<E; i++){
        free(*(skyndiminni + i));
    }
    free(skyndiminni);
    skyndiminni = NULL;
}


/* 
 * accessData - Access data at memory address addr.
 *   If it is already in cache, increast hit_count
 *   If it is not in cache, bring it in cache, increase miss count.
 *   Also increase eviction_count if a line is evicted.
 */
void accessData(mem_addr_t addr)
{
    mem_addr_t bbits = (((1 << b)-1)& (addr >> (1-1))); //blokkarhliðrun
    mem_addr_t sbits = (((1 << s)-1)& (addr >> b));     //mengi
    mem_addr_t tbits = addr >> (b+s);                   //tag
    int success = 0;

    /* Athuga hvort tag í einhverri línu sé eins og tag inntaks og er valid. Ef svo er, staðfesta smell og hætta í lykkju */
    for(int i = 0; i<E; i++){
        if(skyndiminni[sbits][i].tag == tbits && skyndiminni[sbits][i].valid == 1){
            success = 1;
            skyndiminni[sbits][i].lru = lru_counter;
            lru_counter++;
            hit_count++;
            break;
        }
    }
    /* Athuga hvort einhver lína hafi valid=0 og ef svo er, uppfæra þá línu með núverandi inntaki, staðfesta skell og hætta í lykkju.
       Ef engin lína er laus er núverandi inntak sett í þá línu sem er lengst síðan var breytt, eða með minnsta lru. Svo er staðfest
       eviction og skellur. */
    if(success==0){

        unsigned long long int teljari = lru_counter;
        int lina = 0;
        for(int i=0; i<E; i++){
            if(skyndiminni[sbits][i].lru < teljari){
                lina = i;
                teljari = skyndiminni[sbits][i].lru;
            }
        }

        for(int i=0; i<E; i++){
            if(skyndiminni[sbits][i].lru == teljari){
                if(skyndiminni[sbits][i].valid == 1){
                    eviction_count++;
                }
                skyndiminni[sbits][lina].valid = 1;
                skyndiminni[sbits][lina].tag = tbits;
                skyndiminni[sbits][lina].lru = lru_counter;
                miss_count++;
                lru_counter++;
            }
        }

    }

}


/*
 * replayTrace - replays the given trace file against the cache 
 */
void replayTrace(char* trace_fn)
{
    char buf[1000];
    mem_addr_t addr=0;
    unsigned int len=0;
    FILE* trace_fp = fopen(trace_fn, "r");

    if(!trace_fp){
        fprintf(stderr, "%s: %s\n", trace_fn, strerror(errno));
        exit(1);
    }

    while( fgets(buf, 1000, trace_fp) != NULL) {
        if(buf[1]=='S' || buf[1]=='L' || buf[1]=='M') {
            sscanf(buf+3, "%llx,%u", &addr, &len);
      
            accessData(addr);

            /* If the instruction is R/W then access again */
            if(buf[1]=='M')
                accessData(addr);
        }
    }

    fclose(trace_fp);
}

/* 
 * printSummary - Summarize the cache simulation statistics
 */
void printSummary(int hits, int misses, int evictions)
{
    printf("hits: %d  misses: %d  evictions: %d\n", hits, misses, evictions);
    printf("miss ratio: %.2f%%\n", 100.0*misses/(hits+misses));
}

/*
 * printUsage - Print usage infostruct Node {
    int line;
    int legal;
    struct Node* next;
}

 */
void printUsage(char* argv[])
{
    printf("Usage: %s [-h] -s <num> -E <num> -b <num> -t <file>\n", argv[0]);
    printf("Options:\n");
    printf("  -h         Print this help message.\n");
    printf("  -s <num>   Number of set index bits.\n");
    printf("  -E <num>   Number of lines per set.\n");
    printf("  -b <num>   Number of block offset bits.\n");
    printf("  -t <file>  Trace file.\n");
    printf("\nExamples:\n");
    printf("  linux>  %s -s 4 -E 1 -b 4 -t traces/yi.trace\n", argv[0]);
    printf("  linux>  %s -s 8 -E 2 -b 4 -t traces/yi.trace\n", argv[0]);
    exit(0);
}

/*
 * main - Main routine 
 */
int main(int argc, char* argv[])
{
    char c;

    while( (c=getopt(argc,argv,"s:E:b:t:h")) != -1){
        switch(c){
        case 's':
            s = atoi(optarg);
            break;
        case 'E':
            E = atoi(optarg);
            break;
        case 'b':
            b = atoi(optarg);
            break;
        case 't':
            trace_file = optarg;
            break;
        case 'h':
            printUsage(argv);
            exit(0);
        default:
            printUsage(argv);
            exit(1);
        }
    }

    /* Make sure that all required command line args were specified */
    if (s == 0 || E == 0 || b == 0 || trace_file == NULL) {
        printf("%s: Missing required command line argument\n", argv[0]);
        printUsage(argv);
        exit(1);
    }

    /* Compute S, E and B from command line args */
    S = (unsigned int) (1 << s);
    B = (unsigned int) (1 << b);
 
    /* Initialize cache */
    initCache();

    /* Run the simulation */
    replayTrace(trace_file);

    /* Free allocated memory */
    //freeCache();

    /* Output the hit and miss statistics */
    printSummary(hit_count, miss_count, eviction_count);
    return 0;
}
