globals [
  infection-chance  ;; The chance out of 100 that an infected person will pass on
                    ;;   infection during one week of couplehood.
  symptoms-show     ;; How long a person will be infected before symptoms occur
                    ;;   which may cause the person to get tested.
  slider-check-1    ;; Temporary variables for slider values, so that if sliders
  slider-check-2    ;;   are changed on the fly, the model will notice and
  slider-check-3    ;;   change people's tendencies appropriately.
  slider-check-4
]

turtles-own [
  infected?          ;; If true, the person is infected.  It may be known or unknown.
  known?             ;; If true, the infection is known (and infected? must also be true).
  infection-length   ;; How long the person has been infected.
  coupled?           ;; If true, the person is in a sexually active couple.
  couple-length      ;; How long the person has been in a couple.
  ;; the next four values are controlled by sliders
  commitment         ;; How long the person will stay in a couple-relationship.
  coupling-tendency  ;; How likely the person is to join a couple.
  condom-use         ;; The percent chance a person uses protection.
  test-frequency     ;; Number of times a person will get tested per year.
  partner            ;; The person that is our current partner in a couple.
]

;;;
;;; SETUP PROCEDURES
;;;

to setup
  clear-all
  setup-globals
  setup-people
  reset-ticks
end

to setup-globals
  set infection-chance 50    ;; if you have unprotected sex with an infected partner,
                             ;; you have a 50% chance of being infected
  set symptoms-show 200.0    ;; symptoms show up 200 weeks after infection
  set slider-check-1 average-commitment
  set slider-check-2 average-coupling-tendency
  set slider-check-3 average-condom-use
  set slider-check-4 average-test-frequency
end

;; Create carrying-capacity number of people half are righty and half are lefty
;;   and some are sick.  Also assigns colors to people with the ASSIGN-COLORS routine.

to setup-people
  create-turtles initial-people
    [ setxy random-xcor random-ycor
      set known? false
      set coupled? false
      set partner nobody
      ifelse random 2 = 0
        [ set shape "person righty" ]
        [ set shape "person lefty" ]
      ;; 2.5% of the people start out infected, but they don't know it
      set infected? (who < initial-people * 0.025)
      if infected?
        [ set infection-length random-float symptoms-show ]
      assign-commitment
      assign-coupling-tendency
      assign-condom-use
      assign-test-frequency
      assign-color ]
end

;; Different people are displayed in 3 different colors depending on health
;; green is not infected
;; blue is infected but doesn't know it
;; red is infected and knows it

to assign-color  ;; turtle procedure
  ifelse not infected?
    [ set color green ]
    [ ifelse known?
      [ set color red ]
      [ set color blue ] ]
end

;; The following four procedures assign core turtle variables.  They use
;; the helper procedure RANDOM-NEAR so that the turtle variables have an
;; approximately "normal" distribution around the average values set by
;; the sliders.

to assign-commitment  ;; turtle procedure
  set commitment random-near average-commitment
end

to assign-coupling-tendency  ;; turtle procedure
  set coupling-tendency random-near average-coupling-tendency
end

to assign-condom-use  ;; turtle procedure
  set condom-use random-near average-condom-use
end

to assign-test-frequency  ;; turtle procedure
  set test-frequency random-near average-test-frequency
end

to-report random-near [center]  ;; turtle procedure
  let result 0
  repeat 40
    [ set result (result + random-float center) ]
  report result / 20
end

;;;
;;; GO PROCEDURES
;;;

to go
  if all? turtles [known?]
    [ stop ]
  check-sliders
  ask turtles
    [ if infected?
        [ set infection-length infection-length + 1 ]
      if coupled?
        [ set couple-length couple-length + 1 ] ]
  ask turtles
    [ if not coupled?
        [ move ] ]
  ;; Righties are always the ones to initiate mating.  This is purely
  ;; arbitrary choice which makes the coding easier.
  ask turtles
    [ if not coupled? and shape = "person righty" and (random-float 10.0 < coupling-tendency)
        [ couple ] ]
  ask turtles [ uncouple ]
  ask turtles [ infect ]
  ask turtles [ test ]
  ask turtles [ assign-color ]
  tick
end

;; Each tick a check is made to see if sliders have been changed.
;; If one has been, the corresponding turtle variable is adjusted

to check-sliders
  if (slider-check-1 != average-commitment)
    [ ask turtles [ assign-commitment ]
      set slider-check-1 average-commitment ]
  if (slider-check-2 != average-coupling-tendency)
    [ ask turtles [ assign-coupling-tendency ]
      set slider-check-2 average-coupling-tendency ]
  if (slider-check-3 != average-condom-use)
    [ ask turtles [ assign-condom-use ]
      set slider-check-3 average-condom-use ]
  if (slider-check-4 != average-test-frequency )
    [ ask turtles [ assign-test-frequency ]
      set slider-check-4 average-test-frequency ]
end

;; People move about at random.

to move  ;; turtle procedure
  rt random-float 360
  fd 1
end

;; People have a chance to couple depending on their tendency to have sex and
;; if they meet.  To better show that coupling has occurred, the patches below
;; the couple turn gray.

to couple  ;; turtle procedure -- righties only!
  let potential-partner one-of (turtles-at -1 0)
                          with [not coupled? and shape = "person lefty"]
  if potential-partner != nobody
    [ if random-float 10.0 < [coupling-tendency] of potential-partner
      [ set partner potential-partner
        set coupled? true
        ask partner [ set coupled? true ]
        ask partner [ set partner myself ]
        move-to patch-here ;; move to center of patch
        ask potential-partner [move-to patch-here] ;; partner moves to center of patch
        set pcolor gray - 3
        ask (patch-at -1 0) [ set pcolor gray - 3 ] ] ]
end

;; If two peoples are together for longer than either person's commitment variable
;; allows, the couple breaks up.

to uncouple  ;; turtle procedure
  if coupled? and (shape = "person righty")
    [ if (couple-length > commitment) or
         ([couple-length] of partner) > ([commitment] of partner)
        [ set coupled? false
          set couple-length 0
          ask partner [ set couple-length 0 ]
          set pcolor black
          ask (patch-at -1 0) [ set pcolor black ]
          ask partner [ set partner nobody ]
          ask partner [ set coupled? false ]
          set partner nobody ] ]
end

;; Infection can occur if either person is infected, but the infection is unknown.
;; This model assumes that people with known infections will continue to couple,
;; but will automatically practice safe sex, regardless of their condom-use tendency.
;; Note also that for condom use to occur, both people must want to use one.  If
;; either person chooses not to use a condom, infection is possible.  Changing the
;; primitive to AND in the third line will make it such that if either person
;; wants to use a condom, infection will not occur.

to infect  ;; turtle procedure
  if coupled? and infected? and not known?
    [ if random-float 10 > condom-use or
         random-float 10 > ([condom-use] of partner)
        [ if random-float 100 < infection-chance
            [ ask partner [ set infected? true ] ] ] ]
end

;; People have a tendency to check out their health status based on a slider value.
;; This tendency is checked against a random number in this procedure. However, after being infected for
;; some amount of time called SYMPTOMS-SHOW, there is a 5% chance that the person will
;; become ill and go to a doctor and be tested even without the tendency to check.

to test  ;; turtle procedure
  if random-float 52 < test-frequency
    [ if infected?
        [ set known? true ] ]
  if infection-length > symptoms-show
    [ if random-float 100 < 5
        [ set known? true ] ]
end

;;;
;;; MONITOR PROCEDURES
;;;

to-report %infected
  ifelse any? turtles
    [ report (count turtles with [infected?] / count turtles) * 100 ]
    [ report 0 ]
end


; Copyright 1997 Uri Wilensky.
; See Info tab for full copyright and license.
