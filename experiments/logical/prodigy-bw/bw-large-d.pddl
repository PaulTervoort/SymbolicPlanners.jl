;;; bw-large-d
;;;
;;; Initial:  1/12/13/   11/10/5/4/14/15/   9/8/7/6   19/18/17/16/3/2
;;; Goal:     17/18/19/14/1/5/10/   15/13/8/9/4/   12/2/3/16/11/7/6
;;; Length:   36

(define (problem bw-large-d)
  (:domain prodigy-bw)
  (:length (:parallel 36) (:serial 36))
  (:objects 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19)
  (:init (arm-empty)
	 (on 1 12)
	 (on 12 13)
	 (on-table 13)
	 (on 11 10)
	 (on 10 5)
	 (on 5 4)
	 (on 4 14)
	 (on 14 15)
	 (on-table 15)
	 (on 9 8)
	 (on 8 7)
	 (on 7 6)
	 (on-table 6)
	 (on 19 18)
	 (on 18 17)
	 (on 17 16)
	 (on 16 3)
	 (on 3 2)
	 (on-table 2)
	 (clear 1)
	 (clear 11)
	 (clear 9)
	 (clear 19))
  (:goal (and
	  (on 17 18)
	  (on 18 19)
	  (on 19 14)
	  (on 14 1)
	  (on 1 5)
	  (on 5 10)
	  (on-table 10)
	  (on 15 13)
	  (on 13 8)
	  (on 8 9)
	  (on 9 4)
	  (on-table 4)
	  (on 12 2)
	  (on 2 3)
	  (on 3 16)
	  (on 16 11)
	  (on 11 7)
	  (on 7 6)
	  (on-table 6)
	  (clear 17)
	  (clear 15)
	  (clear 12)
	  )))
