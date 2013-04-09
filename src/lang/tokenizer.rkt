#lang racket

;; NOTE(joe): This has been ripped from Danny's test cases for
;; autogrammar
(provide
 get-syntax
 get-stmt-syntax)
(require
  rackunit
  racket/match
  racket/generator
  parser-tools/lex
  ragg/support
  "../../lib/pyret-tokenizer/main.rkt"
  "grammar.rkt")

(define (adapt-pyret-tokenizer ip)
  (define tokens (sequence->generator (generate-tokens ip)))
  (lambda ()
    (let loop ()
      (define next-token (tokens))
      (match next-token
        [(list type text (list start-line start-col) (list end-line end-col) rest-string (list offset span))
         ;; FIXME: improve the Python tokenizer to hold offsets too.
         (define start-pos (position offset start-line start-col))
         (define end-pos (position (+ offset span) end-line end-col))
         (define (pt token) (position-token token start-pos end-pos))
         (case type
             [(NAME) 
              (cond [(set-member? all-token-types (string->symbol text))
                     (pt (token (string->symbol text) text))]
                    [else
                     (pt (token 'NAME text))])]
             [(OP) (pt (token (string->symbol text) text))]
             [(NUMBER) 
              (pt (token 'NUMBER text))]
             [(STRING) 
              (pt (token 'STRING text))]
             [(BACKSLASH)
              (pt (token 'BACKSLASH "\\"))]
             [(COMMENT) (loop)]
             [(NL) (loop)]
             [(NEWLINE) (loop)]
             [(DEDENT) (loop)]
             [(INDENT) (loop)]
             [(ERRORTOKEN)
              (error 'uh-oh)]
             [(ENDMARKER) 
              (token 'ENDMARKER text)])]
        [(? void)
         (token 'EOF eof)]))))

(define (get-syntax name input-port)
  (parse name (adapt-pyret-tokenizer input-port)))

(define (get-stmt-syntax name input-port)
  (define parse-stmt (make-rule-parser stmt))
  (parse-stmt (adapt-pyret-tokenizer input-port)))

(define (get-string-syntax str)
  (get-syntax str (open-input-string str)))

