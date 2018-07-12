#lang racket

(require 2htdp/image)
(require 2htdp/universe)

;;; Some Global Constants
(define SCREEN-SIZE 600)
(define NUM-LINES-PER-PANE 50)
(define LINE-SEPARATION 10)
(define LINE-LENGTH 500)
(define Δ-ROTATION 5)
(define DEFAULT-LINE-COLOR "white")
(define BACKGROUND-COLOR "black")

;; we can store old stages!
(define STORE '())

; for thick/thin lines
(define LINE (λ (color b) (if b color (make-pen color 2 "solid" "round" "round"))))


#|
 A World is a (World (Either Boolean Nat) (Listof Pane) Nat)
 The world holds all the information about the current state
 The accept? field tells if the following command will be for a specific pane
 The panes field hold all the information about the panes
 the x and y fields hold the current fix point of the whole world
 the i field holds which element of the store we're looking at

 Each Pane is a quadruple that holds the
 information for a given set of parallels.
 The 1st elem is the current x-shift of that pane
 The 2nd elem is the current y-shift of that pane
 The 3rd elem is the current rotation of that pane
 The 4th elem is the current color
|#

(struct World [accept? panes x y i] #:transparent)
(struct Pane [x-shift y-shift rotation color thin?] #:transparent)

(define (init-world n thin?)
  (let ([w (World #f (build-list n (λ (x) (Pane 0 0 0 DEFAULT-LINE-COLOR thin?)))
                  (/ SCREEN-SIZE 2) (/ SCREEN-SIZE 2) 0)])
    (begin (set! STORE (list w)) w)))

(define (do-one input s i)
  (match s
    [(Pane x-shift y-shift rot color thin?)
     (match input       
       ;; shifting a single pane
       ["w" (Pane x-shift (sub1 y-shift) rot color thin?)]
       ["s" (Pane x-shift (add1 y-shift) rot color thin?)]
       ["a" (Pane (sub1 x-shift) y-shift rot color thin?)]
       ["d" (Pane (add1 x-shift) y-shift rot color thin?)]
       ;; changing color of a single pane
       ["r" (Pane x-shift y-shift rot "red" thin?)]
       ["o" (Pane x-shift y-shift rot "orange" thin?)]
       ["y" (Pane x-shift y-shift rot "yellow" thin?)]
       ["g" (Pane x-shift y-shift rot "green" thin?)]
       ["b" (Pane x-shift y-shift rot "blue" thin?)]
       ["p" (Pane x-shift y-shift rot "purple" thin?)]
       ["." (Pane x-shift y-shift rot "white" thin?)]
       ;; rotation left/right of a single pane
       ["`" (Pane x-shift y-shift (+ rot Δ-ROTATION) color thin?)]
       ["," (Pane x-shift y-shift (- rot Δ-ROTATION) color thin?)]
       ;; change the thickness of a pane's lines
       ["z" (Pane x-shift y-shift rot color (not thin?))]
       [_ s])]))

(define (interp-num i input panes)
  (if (equal? input "f")
      (begin (set! STORE (cons (init-world i #f) STORE)) panes)
      (match* (panes i)
        [('() n) '()]
        [(`(,pane . ,res) 0) (cons (do-one input pane i) res)]
        [(`(,a . ,d) _) (cons a (interp-num (sub1 i) input d))])))

(define pane-up
  (λ (pane)
    (match pane
      [(Pane x-shift y-shift rot color thin?)
       (Pane x-shift (sub1 y-shift) rot color thin?)])))

(define pane-down
  (λ (pane)
    (match pane
      [(Pane x-shift y-shift rot color thin?)
       (Pane x-shift (add1 y-shift) rot color thin?)])))

(define pane-left
  (λ (pane)
    (match pane
      [(Pane x-shift y-shift rot color thin?)
       (Pane (sub1 x-shift) y-shift rot color thin?)])))

(define pane-right
  (λ (pane)
    (match pane
      [(Pane x-shift y-shift rot color thin?)
       (Pane (add1 x-shift) y-shift rot color thin?)])))

(define key-handler
  (λ (world input)
    (match world
      [(World num panes x y i)
       (cond
         [(number? num)
          (World #f (interp-num num input panes) x y i)]
         [else (match input
                 ;; choose a pane for the next command to effect
                 [(? (λ (in) (string->number in)))
                  (World (string->number input) panes x y i)]
                 ;; zoom in/out
                 ["[" (begin (set! LINE-SEPARATION (+ 5 LINE-SEPARATION))  world)]
                 ["]" (begin (set! LINE-SEPARATION (- LINE-SEPARATION 5)) world)]
                 ;; change # of lines per pane
                 ["m" (begin (set! NUM-LINES-PER-PANE (+ 5 NUM-LINES-PER-PANE)) world)]
                 ["l" (begin (set! NUM-LINES-PER-PANE (- NUM-LINES-PER-PANE 5)) world)]
                 ["up" (World num (map pane-up panes) x y i)]
                 ["down" (World num (map pane-down panes) x y i)]
                 ["left" (World num (map pane-left panes) x y i)]
                 ["right" (World num (map pane-right panes) x y i)]
                 ;; saving states to the store
                 ["=" (begin (set! STORE (cons world STORE)) world)]
                 ["-" (if (> 2 (length STORE))
                          world
                          (let ([new-world (list-ref STORE i)])
                            (match new-world [(World num panes x y i)
                                              (begin
                                                (set! STORE (remove new-world STORE))
                                                (set! STORE (cons world STORE))
                                                (World num panes x y (remainder (add1 i) (length STORE))))])))]
                 ;; clear store to only hold the current world
                 ["q" (begin (set! STORE (list world))
                             (World num panes x y 0))]
                 ;; print the store
                 ["p" (begin (displayln (length STORE)) world)]
                 ;; reset the global values to initial values
                 ["r" (begin (set! NUM-LINES-PER-PANE 50)
                             (set! LINE-SEPARATION 10)
                             world)]
                 [else world])])]))) 

(define (draw-pane color b)
  (let loop ([ans (square LINE-LENGTH "solid" (make-color 0 0 0 0))]
             [n NUM-LINES-PER-PANE]
             [x 0])
    (cond
      [(zero? n) ans]
      [else (loop (add-line ans x 0 x LINE-LENGTH (LINE color b))
                  (sub1 n)
                  (+ LINE-SEPARATION x))])))

(define draw-panes
  (λ (s)
    (let ([to-rotate (/ 180 (length s))])
      (let loop ([shifts s] [i 0])
        (match shifts
          ['() (square SCREEN-SIZE "solid" BACKGROUND-COLOR)]
          [(cons (Pane x-shift y-shift rotation color b) res)
           (place-image (rotate (* i to-rotate)
                                (rotate rotation (draw-pane color b)))
                        (+ x-shift (/ SCREEN-SIZE 2))
                        (+ y-shift (/ SCREEN-SIZE 2))
                        (loop res (add1 i)))])))))

(define (draw-world w)
  (match w
    [(World accept? panes x y i)
     (draw-panes panes)]))


; to start with a fresh world
(define (main n)
  (begin
    (set! STORE '())
    (set! LINE-SEPARATION 10)
    (big-bang (init-world n #f)
              [on-key key-handler]
              [to-draw draw-world])))

;; to start from an existing world, with an existing store
(define (start-from world store)
  (begin
    (set! STORE (if store store (list world)))
    (set! LINE-SEPARATION 10)
    (set! NUM-LINES-PER-PANE 50)
    (big-bang world
              [on-key key-handler]
              [to-draw draw-world])))

(define tessa-1
  (World
   #f
   (list
    (Pane 7 1 35 "yellow" #t)
    (Pane 7 -12 15 "blue" #t)
    (Pane 7 1 -15 "red" #t)
    (Pane 7 1 -40 "yellow" #t)
    (Pane 7 1 170 "blue" #t)
    (Pane 7 1 5 "yellow" #t)
    (Pane 7 1 -20 "red" #t))
   300
   300
   0))

(define ben-1
  (World
   #f
   (list
    (Pane -23 25 385 "blue" #t)
    (Pane -23 42 185 "blue" #f)
    (Pane -23 41 175 "yellow" #f)
    (Pane -23 61 165 "red" #t)
    (Pane -54 242 150 "yellow" #f)
    (Pane -23 23 -45 "blue" #f)
    (Pane -23 23 -60 "yellow" #t)
    (Pane -23 23 290 "red" #f)
    (Pane -23 23 95 "blue" #t)
    (Pane -23 23 110 "red" #t)
    (Pane -23 23 0 "white" #t)
    (Pane -23 23 0 "white" #t)
    (Pane -23 23 0 "white" #t))
   300
   300
   0))
(define joshua-1
  (World
   #f
   (list
    (Pane 12 -6 0 "red" #f)
    (Pane 12 -19 -205 "red" #f)
    (Pane 12 -56 -250 "red" #f)
    (Pane 12 -14 -245 "red" #f)
    (Pane 12 -1 -255 "yellow" #f)
    (Pane 2 -6 -290 "red" #f)
    (Pane -8 -152 -10 "blue" #f)
    (Pane 9 210 -310 "blue" #f)
    (Pane 12 -6 40 "yellow" #f)
    (Pane 12 -6 -160 "blue" #f)
    (Pane 12 -6 0 "white" #f))
   300
   300
   0))

(define universe1
  (World
   #f
   (list
    (Pane 0 0 0 "red" #f)
    (Pane 0 0 0 "orange" #f)
    (Pane 0 0 0 "yellow" #f)
    (Pane 0 0 0 "green" #f)
    (Pane 0 0 0 "blue" #f)
    (Pane 0 0 0 "purple" #f)
    (Pane 0 0 0 "red" #f)
    (Pane 0 0 0 "orange" #f)
    (Pane 0 0 0 "yellow" #f)
    (Pane 0 0 0 "green" #f)
    (Pane 0 0 0 "blue" #f)
    (Pane 0 0 0 "green" #f)
     (Pane 0 0 0 "red" #f)
    (Pane 0 0 0 "orange" #f)
    (Pane 0 0 0 "yellow" #f)
    (Pane 0 0 0 "green" #f)
    (Pane 0 0 0 "blue" #f)
    (Pane 0 0 0 "purple" #f)
    (Pane 0 0 0 "red" #f)
    (Pane 0 0 0 "orange" #f)
    (Pane 0 0 0 "yellow" #f)
    (Pane 0 0 0 "green" #f)
    (Pane 0 0 0 "blue" #f)
    (Pane 0 0 0 "green" #f)
    (Pane 0 0 0 "red" #f)
    (Pane 0 0 0 "orange" #f)
    (Pane 0 0 0 "yellow" #f)
    (Pane 0 0 0 "green" #f)
    (Pane 0 0 0 "blue" #f)
    (Pane 0 0 0 "purple" #f)
    (Pane 0 0 0 "red" #f)
    (Pane 0 0 0 "orange" #f)
    (Pane 0 0 0 "yellow" #f)
    (Pane 0 0 0 "green" #f)
    (Pane 0 0 0 "blue" #f)
    (Pane 0 0 0 "green" #f)
    (Pane 0 0 0 "red" #f)
    (Pane 0 0 0 "orange" #f)
    (Pane 0 0 0 "yellow" #f)
    (Pane 0 0 0 "green" #f)
    (Pane 0 0 0 "blue" #f)
    (Pane 0 0 0 "purple" #f)
    (Pane 0 0 0 "red" #f)
    (Pane 0 0 0 "orange" #f)
    (Pane 0 0 0 "yellow" #f)
    (Pane 0 0 0 "green" #f)
    (Pane 0 0 0 "blue" #f)
    (Pane 0 0 0 "green" #f)
    (Pane 0 0 0 "red" #f)
    (Pane 0 0 0 "orange" #f)
    (Pane 0 0 0 "yellow" #f)
    (Pane 0 0 0 "green" #f)
    (Pane 0 0 0 "blue" #f)
    (Pane 0 0 0 "purple" #f)
    (Pane 0 0 0 "red" #f)
    (Pane 0 0 0 "orange" #f)
    (Pane 0 0 0 "yellow" #f)
    (Pane 0 0 0 "green" #f)
    (Pane 0 0 0 "blue" #f)
    (Pane 0 0 0 "green" #f)
    (Pane 0 0 0 "red" #f)
    (Pane 0 0 0 "orange" #f)
    (Pane 0 0 0 "yellow" #f)
    (Pane 0 0 0 "green" #f)
    (Pane 0 0 0 "blue" #f)
    (Pane 0 0 0 "purple" #f)
    (Pane 0 0 0 "red" #f)
    (Pane 0 0 0 "orange" #f)
    (Pane 0 0 0 "yellow" #f)
    (Pane 0 0 0 "green" #f)
    (Pane 0 0 0 "blue" #f)
    (Pane 0 0 0 "green" #f)
    (Pane 0 0 0 "red" #f)
    (Pane 0 0 0 "orange" #f)
    (Pane 0 0 0 "yellow" #f)
    (Pane 0 0 0 "green" #f)
    (Pane 0 0 0 "blue" #f)
    (Pane 0 0 0 "purple" #f)
    (Pane 0 0 0 "red" #f)
    (Pane 0 0 0 "orange" #f)
    (Pane 0 0 0 "yellow" #f)
    (Pane 0 0 0 "green" #f)
    (Pane 0 0 0 "blue" #f)
    (Pane 0 0 0 "green" #f))
   300
   300
   0))