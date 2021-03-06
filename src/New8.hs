{-# LANGUAGE UndecidableInstances #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE AllowAmbiguousTypes #-}
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE KindSignatures #-}
{-# LANGUAGE PolyKinds #-}
{-# LANGUAGE RankNTypes #-}
{-# LANGUAGE TypeOperators #-}

module New8 where

import Control.Concurrent
import Control.Concurrent.Chan
import Dynamic
import GHC.TypeNats (KnownNat, Nat, natVal, type (+), type (-))
import Data.Kind
import Data.Data (Proxy)
import GHC.Base (Symbol)
import Data.Proxy
import GHC.TypeLits

-- data Fun s d
--   = F (d -> d)
--   | FIO (d -> IO d)
--   | SF (s -> d -> (s, d))
--   | SFIO (s -> d -> IO (s, d))

data Message = Message
  { nodeNumber :: Int,
    -- | messageNumber :: Int, 下游去重指定message的编号
    messageBody :: Dynamic
  }

data Fun s d m n
  = F (s -> Cache m d -> (s, Cache m d, Handle n d))

infixr 4 :|

data C m d where
  Nil :: C 0 d
  (:|) :: Chan d -> C m d -> C (m + 1) d

data Stream d m n = Stream (C m d -> IO (C n d))

sumFun :: Fun Int Dynamic 1 1
sumFun = F $ \s (xs :+ Cil) ->
  (s + fromIntegral (sum xs), [] :+ Cil, (fromIntegral s + sum xs) :- Hil)

getValue :: C m d -> IO (Maybe d)
getValue Nil = return Nothing

ml :: C m d -> C m d
ml Nil = Nil
ml (a :| xs) = a :| (ml xs)

init :: KnownNat n => s -> Backend s -> WindowType -> Triger -> (Fun s d m n, C n d) -> IO (Stream d m n)
init s0 (B1 f) (W1 s e) Complete (func, oc) = return $
  Stream $ \ic -> do
    forkIO $ do
      vs <- undefined
      return undefined
    return oc

(.|) :: Stream d m n -> Stream d n l -> Stream d m l
(.|) = undefined

type Source m d = C m d 
type Sink n d = C n d

conJoin :: Stream d 1 1 -> Stream d 1 1 -> Stream d 2 1 -> Stream d 2 1
conJoin
  (Stream f1)
  (Stream f2)
  (Stream f3) =
    Stream $ \(i1 :| i2 :| Nil) ->
      do
        i1' :| Nil <- f1 (i1 :| Nil)
        i2' :| Nil <- f2 (i2 :| Nil)
        f3 (i1' :| i2' :| Nil)

data Backend s
  = B1 (s -> IO ())
  | Database

type Start = Int

type End = Int

mkc :: [d] -> Cache m d 
mkc [] =  undefined


data Cache m d where
  Cil :: Cache 0 d
  (:+) :: [d] -> Cache m d -> Cache (m + 1) d

data Handle m d where
  Hil :: Handle 0 d
  (:-) :: d -> Handle m d -> Handle (m + 1) d

data WindowType
  = W1 Int Int
  | W2
  | W3

data Window m d = Window WindowType (Cache m d)

data Triger
  = Repeat Int
  | Complete

newtype NodeNumber 
    = NN Nat 

data V (s :: Symbol) a = V

data Join a = Join a

data Lc :: [(Symbol, Type)] -> Type where
    LNil :: Lc '[]
    (:|:) :: V s a -> Lc xs -> Lc ( '(s, a) ': xs) 

infixr 4 :|:

tin = (V :: V "start" Int) :|: (V :: V "fliter"  String ) :|: LNil

tout = (V :: V "end" Float) :|: (V :: V "test"  Int) :|: LNil


data N (s :: Symbol) (a :: [(Symbol, Type)]) (b :: [(Symbol, Type)]) = N

type SSS = (Symbol, [(Symbol, Type)], [(Symbol, Type)])

data State :: [(Symbol, [(Symbol, Type)], [(Symbol, Type)])] -> Type where
    Empty :: State '[]
    Append ::  forall i o s xs. NotElem s xs =>
        N s i o -> State xs -> State (AppendList '(s, i, o) xs )


t1 =  (N :: N "test" '[ '("start", Int)] '[ '("end", String)] )

st = (N :: N "start" '[] '[])

t0 =  Append t1 $ Append st Empty


type family AppendList x xs where
    AppendList x xs = x ': xs


type family NotElem (s :: Symbol) (es :: [SSS] ) :: Constraint where
    NotElem _ '[] = ()
    NotElem s ('(v, _, _) ': xs) =  
     If (CmpSymbol s v) (NotElem s xs)  ( TypeError (Text "节点 "  :<>: ShowType v :<>: Text " 出现了两次" ))


type family If (a :: Ordering) b c :: Constraint where
    If EQ _ c = c
    If _  b _ = b




data Node (s :: Symbol) i o
    = Node {
        ninput :: Lc i
      , noutput :: Lc o
      , funct :: Lc i -> Lc o
    } 



