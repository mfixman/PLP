module Routes where

import Data.List
import Data.Maybe

data PathPattern = Literal String | Capture String deriving (Eq, Show)

data Routes f = Route [PathPattern] f | Scope [PathPattern] (Routes f) | Many [Routes f] deriving Show

-- Ejercicio 1: Dado un elemento separador y una lista, se deber a partir la lista en sublistas de acuerdo a la aparicíon del separador (sin incluirlo).

-- Split reduce un separador y un string a una lista de string.
-- Dado un separador y un elemento de un string, la funcion lambda agrega este
-- elemento al final de la ultima lista a menos que el elemento sea el separador.
-- En ese caso, crea una lista nueva (string vacio) al final de la lista de lista.
split :: Eq a => a -> [a] -> [[a]]
split d = foldl
        (\ l c ->
                if c == d then
                        l ++ [[]]
                else
                        init l ++ [last l ++ [c]]
        )
        [[]]

-- Ejercicio 2: A partir de una cadena que denota un patrón de URL se deberá construir la secuencia de literales y capturas correspondiente.

-- parseEntity usa pattern matching para determinar si un argumento es una
-- captura o un literal.
-- pattern usa split para separar un string en una lista de entities y luego
-- parsea cada una de ellas.
parseEntity :: String -> PathPattern
parseEntity (':':xs) = Capture xs
parseEntity x = Literal x

pattern :: String -> [PathPattern]
pattern = map parseEntity . split '/'

-- Ejercicio 3: Obtiene el valor registrado en una captura determinada. Se puede suponer que la captura está definida en el contexto.
type PathContext = [(String, String)]

-- Busca el segundo elemento de la tupla del primer elemento de la lista (que
-- deberia ser el unico) que tenga como primer elemento de la tupla cierto argumento.
get :: String -> PathContext -> String
get s = snd.head.filter ((==s).fst)

-- Ejercicio 4: Dadas una ruta particionada y un patrón de URL, trata de aplicar el patrón a la ruta y devuelve, en caso de que
--              la ruta sea un prefijo válido para el patrón, el resto de la ruta que no se haya llegado a consumir y el contexto capturado hasta el punto alcanzado.
-- Se puede usar recursión explícita.

captures :: [String] -> [PathPattern] -> [(String, String)]
captures h [] = []
captures (h:hs) (Literal l:ls) = captures hs ls
captures (h:hs) (Capture l:ls) = (l, h) : captures hs ls

literals :: [String] -> [PathPattern] -> Maybe([String])
literals h [] = Just h
literals [] l = Nothing
literals (h:hs) (Capture l:ls) = literals hs ls
literals (h:hs) (Literal l:ls)
        | h == l = literals hs ls
        | otherwise = Nothing

matches :: [String] -> [PathPattern] -> Maybe ([String], PathContext)
matches hs ls = literals hs ls >>= Just . flip (,) (captures hs ls)

-- DSL para rutas
route :: String -> a -> Routes a
route s f = Route (pattern s) f

scope :: String -> Routes a -> Routes a
scope s r = Scope (pattern s) r

many :: [Routes a] -> Routes a
many l = Many l

-- data Routes f = Route [PathPattern] f | Scope [PathPattern] (Routes f) | Many [Routes f]
-- Ejercicio 5: Definir el fold para el tipo Routes f y su tipo. Se puede usar recursión explícita.
--foldrRoutes :: ([PathPattern] -> a -> c -> c) -> ([PathPattern] -> c -> c ) -> ((Routes-> c ) -> [Routes] -> c) -> Routes -> c -> c
-- caso base, tengo un Route osea que es un caso no recursivo, aplico la funcion
-- de reduce para este contructor, fr 
foldRoutes fr _ _     (Route pp ff)= fr pp ff 
-- caso donde tengo un scope, osea un pathpatter y un routes osea que es recursivo
-- la funcion de reduce del scope es fs y toma un patpatter mas el resultado recursivo de foldRoutes
foldRoutes fr fs fm    (Scope pp r)= fs pp $ foldRoutes fr fs fm   r 
-- en este caso many es un array de Routes, asi que fm es la funcion de reduce 
-- que toma el resultado del foldr sobre el array de routes. Osea que reduce
-- el resultado de llamar foldRoutes sobre cada uno de los Routes
foldRoutes fr fs fm   (Many r) = fm $ map (foldRoutes fr fs fm)    r
-- test
-- foldRoutes (\x y  -> "1") (\x y -> y ++ "2")  (\x  -> concat x) (route "/hola/chau" "mundo")
-- foldRoutes (\x y  -> "1") (\x y -> y ++ "2")  (\x  -> concat x) ( scope   "/casa"  (route "/hola/chau" "mundo") )
-- foldRoutes (\x y  -> "1") (\x y -> y ++ "2")  (\x  -> concat x) ( many  [( scope   "/casa"  (route "/hola/chau" "mundo") ) , ( scope   "/casa"  (route "/hola/chau" "mundo") ) , (route "/lala" "chau " ) ] )



-- Auxiliar para mostrar patrones. Es la inversa de pattern.
patternShow :: [PathPattern] -> String
patternShow ps = concat $ intersperse "/" ((map (\p -> case p of
  Literal s -> s
  Capture s -> (':':s)
  )) ps)

-- Ejercicio 6: Genera todos los posibles paths para una ruta definida.
paths :: Routes a -> [String]
paths = foldRoutes (\x _ ->   [ ( patternShow x ) ]  ) 
                   (\x y ->  map  (\z ->  (patternShow x )++"/"  ++ z ) y )
                   (\x -> concat x)
-- paths ( many [ route "" "ver inicio", route "ayuda" "ver ayuda", scope "materia/:nombre/alu/:lu" $ many [ route "inscribir" "inscribe alumno", route "aprobar" "aprueba alumno" ] , route "alu/:lu/aprobadas" "ver materias aprobadas por alumno" ] )
-- paths (  many [route "ayuda" "ver ayuda" , route "chau" "hola ", scope "/juan" (many [route "a" "b",route "c" "d"])] )


-- Ejercicio 7: Evalúa un path con una definición de ruta y, en caso de haber coincidencia, obtiene el handler correspondiente 
--              y el contexto de capturas obtenido.
{-
Nota: la siguiente función viene definida en el módulo Data.Maybe.
 (=<<) :: (a->Maybe b)->Maybe a->Maybe b
 f =<< m = case m of Nothing -> Nothing; Just x -> f x
-}
eval :: Routes a -> String -> Maybe (a, PathContext)
eval = undefined


-- Ejercicio 8: Similar a eval, pero aquí se espera que el handler sea una función que recibe como entrada el contexto 
--              con las capturas, por lo que se devolverá el resultado de su aplicación, en caso de haber coincidencia.
exec :: Routes (PathContext -> a) -> String -> Maybe a
exec routes path = undefined

-- Ejercicio 9: Permite aplicar una funci ́on sobre el handler de una ruta. Esto, por ejemplo, podría permitir la ejecución 
--              concatenada de dos o más handlers.
wrap :: (a -> b) -> Routes a -> Routes b
wrap f = undefined

-- Ejercicio 10: Genera un Routes que captura todas las rutas, de cualquier longitud. A todos los patrones devuelven el mismo valor. 
--               Las capturas usadas en los patrones se deberán llamar p0, p1, etc. 
--               En este punto se permite recursión explícita.
catch_all :: a -> Routes a
catch_all h = undefined
