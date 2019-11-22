; Specs
(local width env.width)
(local height env.height)
(local max-colors 16)

; Easier to type maths
(local min math.min)
(local random math.random)

(var x 20)
(var y 20)
(var vx 60)
(var vy 20)

(fn out-of-bounds? [x y]
  (values (min (- (- width 1) x) x)
          (min (- (- height 1) y) y)))

(fn pin-to-edge [v dv]
  (if (< v 0)
      (- v dv)
      (+ v dv)))

(fn bounce-if [dx dy]
  (if (< dx 0)
      ((lambda []
         (set vx (- vx))
         (set x (pin-to-edge x dx))))
      (< dy 0)
      ((lambda []
         (set vy (- vy))
         (set y (pin-to-edge y dy))))))

(fn put-pixel-around [x y color]
  (put-pixel (+ x (- (random 4) 2))
             (+ y (- (random 4) 2))
             color))

(fn .draw []
  (for [i 1 5]
    (put-pixel-around x y (random max-colors)))

  ; Erase a random part of the screen
  (for [i 1 200]
    (fill-rect (random width) (random height) 3 3 16)))

(fn .update [dt]
  (set x (+ x (* vx dt)))
  (set y (+ y (* vy dt)))

  (bounce-if (out-of-bounds? x y)))

; Set the globals
(global draw .draw)
(global update .update)
