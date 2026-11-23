;;; ============================================================
;;; Dominio: robot repartidor de medicamentos en un hospital
;;; Mecanicas propias: contaminacion, elevador, puerta con
;;; tarjeta, esterilizacion y capacidad de una sola carga.
;;; ============================================================
(define (domain hospital-robot)
  (:requirements :strips :typing)

  (:types
    location
    medicine
    key
    patient)

  (:predicates
    ;; --- Estructura del hospital ---
    (connected ?a ?b - location)        ; pasillo normal (dirigido)
    (door-link ?a ?b - location)        ; puerta con acceso restringido
    (elevator-link ?a ?b - location)    ; vestibulos de distintos pisos
    (isolation ?l - location)           ; cuarto de aislamiento
    (sterilizer-room ?l - location)     ; tiene esterilizador
    (decon-station ?l - location)       ; estacion de descontaminacion
    (opens ?k - key ?l - location)      ; que tarjeta abre que cuarto

    ;; --- Estado del robot ---
    (robot-at ?l - location)
    (hand-free)                         ; mano libre (carga unica)
    (carrying ?m - medicine)
    (has-key ?k - key)                  ; permiso: no ocupa la mano
    (clean)                             ; robot descontaminado

    ;; --- Estado del mundo ---
    (med-at ?m - medicine ?l - location)
    (key-at ?k - key ?l - location)
    (patient-at ?p - patient ?l - location)
    (sterile ?m - medicine)
    (delivered ?m - medicine ?p - patient))

  ;; Movimiento normal por pasillos
  (:action move
    :parameters (?from ?to - location)
    :precondition (and (robot-at ?from) (connected ?from ?to))
    :effect (and (not (robot-at ?from)) (robot-at ?to)))

  ;; Recoger un medicamento (requiere mano libre)
  (:action pick-up
    :parameters (?m - medicine ?l - location)
    :precondition (and (robot-at ?l) (med-at ?m ?l) (hand-free))
    :effect (and (not (med-at ?m ?l)) (not (hand-free)) (carrying ?m)))

  ;; Soltar un medicamento
  (:action drop
    :parameters (?m - medicine ?l - location)
    :precondition (and (robot-at ?l) (carrying ?m))
    :effect (and (not (carrying ?m)) (hand-free) (med-at ?m ?l)))

  ;; Tomar la tarjeta de acceso
  (:action take-key
    :parameters (?k - key ?l - location)
    :precondition (and (robot-at ?l) (key-at ?k ?l))
    :effect (and (not (key-at ?k ?l)) (has-key ?k)))

  ;; Esterilizar el medicamento que se lleva en la mano
  (:action sterilize
    :parameters (?m - medicine ?l - location)
    :precondition (and (robot-at ?l) (sterilizer-room ?l) (carrying ?m))
    :effect (sterile ?m))

  ;; Cambiar de piso: solo si el robot esta limpio
  (:action use-elevator
    :parameters (?from ?to - location)
    :precondition (and (robot-at ?from) (elevator-link ?from ?to) (clean))
    :effect (and (not (robot-at ?from)) (robot-at ?to)))

  ;; Entrar al aislamiento: exige tarjeta y contamina al robot
  (:action enter-isolation
    :parameters (?k - key ?from ?to - location)
    :precondition (and (robot-at ?from) (door-link ?from ?to)
                       (isolation ?to) (has-key ?k) (opens ?k ?to))
    :effect (and (not (robot-at ?from)) (robot-at ?to) (not (clean))))

  ;; Entregar un medicamento esteril al paciente
  (:action deliver
    :parameters (?m - medicine ?p - patient ?l - location)
    :precondition (and (robot-at ?l) (patient-at ?p ?l)
                       (carrying ?m) (sterile ?m))
    :effect (and (delivered ?m ?p) (not (carrying ?m)) (hand-free)))

  ;; Descontaminar al robot
  (:action decontaminate
    :parameters (?l - location)
    :precondition (and (robot-at ?l) (decon-station ?l))
    :effect (clean))
)
