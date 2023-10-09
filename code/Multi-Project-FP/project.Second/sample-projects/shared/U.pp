unit U;

interface

   function Add(a: integer; b: integer) : integer;
   function Multiply(a: integer; b: integer) : integer;

implementation

   function LibMultiply(a: integer; b: integer) : integer; external 'lib' name 'Multiply';

   function Multiply(a: integer; b: integer) : integer;
   begin
        result := LibMultiply(a, b);
   end;

   function Add(a: integer; b: integer) : integer;
   begin
        result := a + b;
   end;

begin
end.