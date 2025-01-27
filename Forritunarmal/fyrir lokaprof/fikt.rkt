;; Aðgerðir á óendanlega strauma og taylor raðir

;; Höfundur: Snorri Agnarsson

;; Fyrir PC-Scheme verðum við að gefa stream-car og stream-cdr gildi
;; (sleppum næstu tveimur línum í MIT-Scheme og DrScheme):
;(define stream-car head)
;(define stream-cdr tail)

;; Fyrir DrScheme:
(define (-1+ n) (- n 1))
(define (1+ n) (+ n 1))
(define-syntax cons-stream
  (syntax-rules ()
    ((cons-stream head tail)
     (cons head (delay tail))
    )
  )
)
(define stream-car car)
(define (stream-cdr s) (force (cdr s)))
;; Lok kafla fyrir DrScheme

;; Notkun: einn
;; Gildi:  straumurinn [1 1 ...]
(define einn
    (letrec ((temp (cons-stream 1 temp)))
        temp
    )
)


;; Notkun: heil
;; Gildi:  óendanlegi straumurinn [1 2 3 ...]
(define heil
    (letrec ((temp (cons-stream 1 (stream-map 1+ temp))))
        temp
    )
)

;; Notkun: (stream-list x n)
;; Fyrir:  x=[x1 x2 ...] er straumur af lengd a.m.k. n, n er heiltala >=0
;; Gildi:  listinn (x1 x2 ... xn)
(define (stream-list x n)
	(if (= n 0)
		'()
		(cons (stream-car x) (stream-list (stream-cdr x) (-1+ n)))
	)
)

;; Notkun: fibo
;; Gildi:  óendanlegur straumur Fibonacci talna: [1 1 2 3 5 8 ...]
(define fibo
	(cons-stream 1
	    (cons-stream 1
            (stream-binop + fibo (stream-cdr fibo))
        )
    )
)

;; Notkun: fact
;; Gildi:  óendanlegur straumur hrópmerktra talna: [0! 1! 2! ...]
(define fact
    (cons-stream 1 (stream-binop * fact heil))
)

;; Eftirfarandi kafli útfærir óendanlegar Taylor raðir.
;; Taylor röðin a_0+a_1*x+a_2*x^2+... er táknuð með straumnum
;; [a_0 a_1 ...]

;; Notkun: taylor-zero
;; Gildi:  Taylor röðin fyrir núll fallið: 0+0x+0x^2+...
(define taylor-zero
    (letrec ((temp (cons-stream 0 temp))) temp)
)

;; Nú viljum við fá fall sem heildar Taylor raðir, með eftirfarandi
;; lýsingu:

;; Notkun: (taylor-integrate c s)
;; Fyrir:  c er tala, s er Taylor röð
;; Gildi:  Taylor röðin fyrir c + heildið af s frá 0 til x

;; Eftirfarandi er e.t.v. fyrsta útfærslan á slíku falli, sem okkur
;; dettur í hug, en þessi útfærsla hefur þann galla að ekki er hægt
;; að heilda fall fyrr en búið er að skilgreina það (eða a.m.k. fyrsta
;; liðinn í því.
;(define (taylor-integrate c s)
;    (cons-stream c (stream-binop / s heil))
;)
;; Það sem við viljum er útfærsla þ.a. segðin (taylor-integrate c s)
;; sé jafngilt segðinni (cons-stream c (stream-binop / s heil)),
;; fyrir hvaða Taylor segð s og tölu s sem er.
;; Vandamálið er að þetta er þá ekki hægt að útfæra sem venjulegt
;; fall, því venjulegt fall myndi gilda segðina s áður en kallað
;; er á taylor-integrate.
;; Við getum leyst málið með því að skilgreina fjölva:

;; Notkun: (taylor-integrate x s)
;; Fyrir:  c er tala, s er segð, sem skilar Taylor röð
;; Gildi:  Taylor röðin fyrir c + heildið af s frá 0 til x
;; Aths.:  s þarf ekki að skila gildi fyrr en reiknaður
;;         er halinn á útkomunni


;; Þessi útgáfa er fyrir DrScheme:
(define-syntax taylor-integrate
  (syntax-rules ()
    ((taylor-integrate c s)
     (cons-stream c (stream-binop / s heil))
    )
   )
)

;; Þessi útgáfa er fyrir MIT-Scheme:
;(define-syntax taylor-integrate 
;    (lambda (c s)
;        `(cons-stream ,c (stream-binop / ,s heil))
;    )
;)

;; Þessi útgáfa er fyrir PC-Scheme:
;(macro taylor-integrate
;    (lambda (form)
;        (let ((c (cadr form)) (s (caddr form)))
;            `(cons-stream ,c (stream-binop / ,s heil))
;        )
;    )
;)

;; Við skilgreinum nú nokkrar Taylor raðir með gagnkvæmri heildun.
;; Fyrstu fjórar eru með brotastuðlum í þeim afbrigðum af Scheme,
;; sem bjóða upp á það (t.d. MIT-Scheme), en með fleytitölustuðlum
;; í öðrum (t.d. PC-Scheme).

;; Notkun: taylor-sin
;; Gildi:  Taylor röðin fyrir sin
(define taylor-sin (taylor-integrate 0 taylor-cos))

;; Notkun: taylor-cos
;; Gildi:  Taylor röðin fyrir cos
(define taylor-cos (taylor-integrate 1 taylor-msin))

;; Notkun: taylor-msin
;; Gildi:  Taylor röðin fyrir -sin
(define taylor-msin (taylor-integrate 0 taylor-mcos))

;; Notkun: taylor-mcos
;; Gildi:  Taylor röðin fyrir -cos
(define taylor-mcos (taylor-integrate -1 taylor-sin))

;; Næstu fjórar eru svipaðar, en stuðlarnir eru alltaf fleytitölur

(define taylor-sinf (taylor-integrate 0.0 taylor-cosf))
(define taylor-cosf (taylor-integrate 1.0 taylor-msinf))
(define taylor-msinf (taylor-integrate 0.0 taylor-mcosf))
(define taylor-mcosf (taylor-integrate -1.0 taylor-sinf))

;; Notkun: (taylor-diff s)
;; Fyrir:  s er Taylor röð
;; Gildi:  Taylor röðin fyrir diffurkvóta s
(define (taylor-diff s)
    (stream-binop * (stream-cdr s) heil)
)

;; Notkun: (taylor+ a b)
;; Fyrir:  a og b eru Taylor raðir eða tölur
;; Gildi:  Taylor röðin fyrir a+b, eða talan a+b ef báðar eru tölur
(define (taylor+ x y) 
    (if (number? x)
        (if (number? y)
            (+ x y)
            (cons-stream (+ x (stream-car y)) (stream-cdr y))
        )
        (if (number? y)
            (cons-stream (+ (stream-car x) y) (stream-cdr x))
            (stream-binop + x y)
        )
    )
)

;; Notkun: (taylor- a b)
;; Fyrir:  a og b eru Taylor raðir eða tölur
;; Gildi:  Taylor röðin fyrir a-b, eða talan a-b ef báðar eru tölur
(define (taylor- x y)
    (if (number? x)
        (if (number? y)
            (- x y)
            (taylor- (cons-stream x taylor-zero) y)
        )
        (if (number? y)
            (cons-stream (- (stream-car x) y) (stream-cdr x))
            (stream-binop - x y)
        )
    )
)

;; Notkun: (taylor* a b)
;; Fyrir:  a og b eru Taylor raðir eða tölur
;; Gildi:  Taylor röðin fyrir a*b, eða talan a*b ef báðar eru tölur
(define (taylor* x y)
    ;; Notkun: (taylor* a b)
    ;; Fyrir:  a og b eru Taylor raðir
    ;; Gildi:  Taylor röðin fyrir a*b
    (define (help x y)
        (taylor+
            (taylor* (stream-car x) y)
            (cons-stream 0 (taylor* (stream-cdr x) y))
        )
    )
    (if (number? x)
        (if (number? y)
            (* x y)
            (stream-map (lambda (y) (* x y)) y)
        )
        (if (number? y)
            (stream-map (lambda (x) (* x y)) x)
            (help x y)
        )
    )
)

;; Notkun: (taylor/ a b)
;; Fyrir:  a og b eru Taylor raðir eða tölur
;;         b má ekki vera núll, og a verður að hafa a.m.k. jafn
;;         marga núll liði fremst og b
;; Gildi:  Taylor röðin fyrir a/b, eða talan a/b ef báðar eru tölur
(define (taylor/ x y)
    ;; Notkun: (help a b)
    ;; Fyrir:  a og b eru Taylor raðir
    ;;         a verður að hafa a.m.k. jafn marga núll liði fremst og b
    ;; Gildi:  Taylor röðin fyrir a/b
    (define (help x y)
        (if (= (stream-car y) 0)
            (if (= (stream-car x) 0)
                (help (stream-cdr y) (stream-cdr x))
                (/ 0 (stream-car x))
            )
            (let
                (
                    (z0 (/ (stream-car x) (stream-car y)))
                )
                (cons-stream
                    z0
                    (help (taylor- (stream-cdr x) (taylor* z0 (stream-cdr y))) y)
                )
            )
        )
    )
    (if (number? y)
        (if (number? x)
            (/ x y)
            (stream-map (lambda (x) (/ x y)) x)
        )
        (if (number? x)
            (help (cons-stream x taylor-zero) y)
            (help x y)
        )
    )
)

;; Notkun: (taylor-eval f x n)
;; Fyrir:  f er Taylor röð, x er tala, n er heiltala >=0
;; Gildi:  Summa fyrstu n liða Taylor raðarinnar með gefnu gildi x
(define (taylor-eval f x n)
    (if (= n 0)
        0
        (+ (stream-car f) (* x (taylor-eval (stream-cdr f) x (-1+ n))))
    )
)

;; Notkun: taylor-x
;; Gildi:  Taylor röðin fyrir fallið f(x)=x
(define taylor-x
    (cons-stream 0 (cons-stream 1 taylor-zero))
)

;; Notkun: taylor-ln_1+x
;; Gildi:  Taylor röðin fyrir fallið f(x)=ln(1+x)
(define taylor-ln_1+x
    (taylor-integrate 0 (taylor/ 1 (taylor+ 1 taylor-x)))
)

;; Notkun: taylor-exp
;; Gildi:  Taylor röðin fyrir fallið exp
(define taylor-exp (taylor-integrate 1 taylor-exp))

;; Notkun: taylor-tan
;; Gildi:  Taylor röðin fyrir fallið tan (brotastuðlar ef Scheme
;;         ræður við það)
(define taylor-tan (taylor/ taylor-sin taylor-cos))

;; Notkun: taylor-tanf
;; Gildi:  Taylor röðin fyrir fallið tan (fleytitölustuðlar)
(define taylor-tanf (taylor/ taylor-sinf taylor-cosf))

;; Notkun: (taylor-compose f g)
;; Fyrir:  f og g eru Taylor raðir, g(0)=0
;; Gildi:  Taylor röðin fyrir fallið f o g
(define (taylor-compose f g)
    (if (= (stream-car g) 0)
        (cons-stream
            (stream-car f)
            (taylor* (stream-cdr g) (taylor-compose (stream-cdr f) g))
        )
        (/ 1 0)
    )
)

;; Notkun: (taylor-general-inverse f g)
;; Fyrir:  f og g eru Taylor raðir, g(0)=0
;; Gildi:  Taylor röð fyrir fall h þ.a. h o g = f
(define (taylor-general-inverse f g)
    (if (= (stream-car g) 0)
        (cons-stream
            (stream-car f)
            (taylor-general-inverse
                (taylor/ (stream-cdr f) (stream-cdr g))
                g
            )
        )
        (/ 1 0)
    )
)

;; Notkun: (taylor-inverse f)
;; Fyrir:  f er Taylor röð, f(0)=0
;; Gildi:  Taylor röð fyrir andhverfa fallið við f,
;;         þ.e.fall h þ.a. h o f = x = f o h
(define (taylor-inverse f)
    (taylor-general-inverse taylor-x f)
)

;; Notkun: taylor-asin
;; Gildi:  Taylor röðin fyrir andhverfa fallið við sin
;;         með brotastuðlum ef Scheme ræður við það,
;;         annars fleytitölustuðlum
(define taylor-asin (taylor-inverse taylor-sin))

;; Notkun: taylor-asinf
;; Gildi:  Taylor röðin fyrir andhverfa fallið við sin
;;         með fleytitölustuðlum
(define taylor-asinf (taylor-inverse taylor-sinf))

;; Notkun: taylor-atan
;; Gildi:  Taylor röðin fyrir andhverfa fallið við tan
;;         með brotastuðlum ef Scheme ræður við það,
;;         annars fleytitölustuðlum
(define taylor-atan (taylor-inverse taylor-tan))

;; Notkun: taylor-atanf
;; Gildi:  Taylor röðin fyrir andhverfa fallið við tan
;;         með fleytitölustuðlum
(define taylor-atanf (taylor-inverse taylor-tanf))

;; Notkun: (stream-map f s)
;; Fyrir:  f er einundaraðgerð, s=[s1 s2 ...] er óendanlegur
;;         straumur viðfanga í f
;; Gildi:  óendanlegi straumurinn [(f s1) (f s2) ...]
(define (stream-map f s)
    (cons-stream (f (stream-car s)) (stream-map f (stream-cdr s)))
)

;; Notkun: (stream-binop f x y)
;; Fyrir:  f er tvíundaraðgerð, x=[x1 x2 ...] og y=[y1 y2 ...]
;;         eru óendanlegir straumar fyrri og seinni viðfanga í f
;; Gildi:  óendanlegi straumurinn [(f x1 y1) (f x2 y2) ...]
(define (stream-binop f x y)
    (cons-stream 
        (f (stream-car x) (stream-car y))
        (stream-binop f (stream-cdr x) (stream-cdr y))
    )
)

(define (powerlist n)
  (define (hjalp i)
    (if(> i n)
       '(())
       (append (hjalp (+ i 1)) (map (lambda (z)(cons i z)) (hjalp (+ i 1))))
    )
  )
  (hjalp 1)
)


(define (cross a b)
  (cons-stream (stream-map (lambda(z)(cons (stream-car a) z)) b) (cross (stream-cdr a) b)))



(define (mulstreams x y)
   (cons-stream (stream-map (lambda(z) (* (stream-car y) z)) x) (mulstreams x (stream-cdr y))))


(define (byltastraumi2 s)
(cons-stream
(stream-map stream-car s)
(byltastraumi2 (stream-map stream-cdr s))
)
)

(define (powlist n)
  (define (hjalp i)
    (if(> i n)
       '(())
       (append (hjalp (+ i 1)) (map (lambda (z) (cons i z)) (hjalp (+ i 1))))
    )
  )
  (hjalp 1)
)



(define (reverze x)
  (define (hjalp x y)
    (if(null? x)
       y
       (hjalp (cdr x) (cons (car x) y))
    )
  )
  (hjalp x '())
)

;Notkun:  (basic n)
;Fyrir:   n er heiltala >= 0
;Eftir:   Listi talna (1, 2,..., n)
(define (basic n)
  ;Notkun: (hjalp i n x)
  ;Fyrir:  i = talan 1
  ;        n = heiltala >= 0
  ;        x = listi af tölum sem hafa
  ;        þegar verið afgreiddar   
  ;Eftir:  Ef i <= n er x = (i, i-1,..., 1)
  ;        Ef i > n er x = (1, 2,..., n)
  (define (hjalp i n x)
    (if(> i n)
       (reverse x)
       (hjalp (+ i 1) n (cons i x))
    )
  )
  (hjalp 1 n '())
)


;Notkun:  (basic2 n)
;Fyrir:   n er heiltala >= 0
;Eftir:   listinn (n, n-1,..., 1)
(define (basic2 n)
  ;Notkun:  (hjalp i n x)
  ;Fyrir:   i er tala 1 <= i <= n+1
  ;         n er heiltala >= 0
  ;         x er listinn (i-1, i-2,..., 2, 1)
  ;Eftir:   listinn (n, n-1,..., 2, 1)
  (define (hjalp i n x)
    (if(> i n)
       x
       (hjalp (+ i 1) n (cons i x))
    )
  )
  (hjalp 1 n '())
)

;Notkun:  (posstream)
;Fyrir:   ekkert
;Eftir:   straumur af oddatölum, [1, 3, 5,...]
(define (posstream)
  ;Notkun: (hjalp n)
  ;Fyrir:  n er tala >= 1
  ;Eftir:  straumur af oddatölum, [1, 3, 5,...]
  (define (hjalp n)
    (cons-stream n (hjalp (+ n 2)))
  )
  (hjalp 1)
)



;RANGT
;Notkun:  (float x)
;Fyrir:   x er listi af listum af fleytitölum milli
;         0 og 1. x = ((a1,a2,...,am), (b1, b2,...,bn),....,(z1, z2,...,zl))
;Eftir:   Lægsta tala sem kemur út þegar búið er að bera saman
;         hæstu töluna úr hverjum innri lista.
(define (float x)
  (define (hjalp x max min)
    (if(null? x)
       min
       (if(null? (car x))
          (if(< max min)
             (hjalp (cdr x) 0 max)
             (hjalp (cdr x) 0 min)
          )
          (if(> (car (car x)) max)
             (hjalp (cdr(car x)) (car(car x)) min)
             (hjalp (cdr(car x)) max min)
          )
       )
    )
  )
  (hjalp x 0 1)
)

;RANGT
(define (float2 x)
  (define (hjalp x y max min)
    (if(null? x)
       min
       (if(null? y)
          (if(null? (cdr x))        
             (if(null? (cdr y))
                (if(< max min)
                   max
                   min
                )
                (if(< (car y) max)
                   (hjalp x (cdr y) (car y) min)
                   (hjalp x (cdr y) max min)
                )
             )
             (if(< max min)
                (hjalp (cdr x) (car(cdr x)) 0 max)
                (hjalp (cdr x) (car(cdr x)) 0 min)
             )
          )
          (if(> (car y) max)
             (hjalp x (cdr y) (car y) min)
             (hjalp x (cdr y) max min)
          )
       )
    )
  )
  (hjalp x (car x) 0 1)
)


;RANGT
(define (float3 x)
  (define (hjalp x min max)
    (if(null? x)
       min
       (if(null? (cdr(car x)))
          (if(null? (cdr x))
             min
             (if(< max min)
                (hjalp (cdr x) max 0)
                (hjalp (cdr x) min 0)
             )
          )
          (if(> (car(car x)) max)
             (hjalp (cdr(car x)) min (car(car x)))
             (hjalp (cdr(car x)) min max)
          )
       )
    )
  )
  (hjalp x 1 0)
)


(define (powlizt n)
  (define (hjalp i)
    (if(> i n)
       '(())
       (append (hjalp (+ i 1)) (map (lambda(z) (cons i z)) (hjalp (+ i 1))))
    )
  )
  (hjalp 1)
)

