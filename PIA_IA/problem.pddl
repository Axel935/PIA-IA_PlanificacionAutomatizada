;;; Problema: entregar un medicamento esteril al paciente en
;;; aislamiento (piso 2) y regresar limpio a la farmacia (piso 1).
(define (problem entrega-aislamiento)
  (:domain hospital-robot)

  (:objects
    farmacia esterilizacion seguridad lobby1
    lobby2 pasillo aislamiento descontaminacion - location
    med1 - medicine
    tarjeta1 - key
    paciente1 - patient)

  (:init
    ;; Estado inicial del robot
    (robot-at lobby1)
    (hand-free)
    (clean)

    ;; Piso 1 (lobby1 es el centro)
    (connected lobby1 farmacia)        (connected farmacia lobby1)
    (connected lobby1 esterilizacion)  (connected esterilizacion lobby1)
    (connected lobby1 seguridad)       (connected seguridad lobby1)

    ;; Piso 2
    (connected lobby2 pasillo)         (connected pasillo lobby2)
    (connected pasillo descontaminacion)
    (connected descontaminacion pasillo)
    (connected aislamiento descontaminacion)  ; solo salida

    ;; Elevador y puerta con tarjeta
    (elevator-link lobby1 lobby2)      (elevator-link lobby2 lobby1)
    (door-link pasillo aislamiento)

    ;; Cuartos especiales
    (isolation aislamiento)
    (sterilizer-room esterilizacion)
    (decon-station descontaminacion)

    ;; Objetos y paciente
    (med-at med1 farmacia)
    (key-at tarjeta1 seguridad)
    (opens tarjeta1 aislamiento)
    (patient-at paciente1 aislamiento))

  (:goal (and (delivered med1 paciente1)
              (clean)
              (robot-at farmacia)))
)
