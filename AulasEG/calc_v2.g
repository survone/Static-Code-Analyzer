grammar calc;

@header{
import java.util.HashMap;
import java.util.ArrayList;
}


@members{
enum Tipo {REAL, INT};



//*===========  Produto ============= */
public class Par{
	private String tipo;
	private float value;
	
	public Par(){
		this.tipo = "";
		this.value = 0;
	}
	
	public Par(String tipo, float value){
		this.tipo = tipo;
		this.value = value;
	}
	
	public String getTipo(){return this.tipo;}	
	public float getValue(){return this.value;}
	
	public void setTipo(String tipo){this.tipo = tipo;}	
	public void setValue(float val){this.value = val;}
		
	//public String toString(){
//	return "Produto -> " + this.referencia + "\nDescricao: " + this.descricao + "\nPreco por unidade: " + 
//		this.precouni + "\nQuantidade" + this.quantidade + "\n";
//	}
	
//	public float precoTotal(){
//		return this.precouni * this.quantidade;
//	}
	
}



}



language returns [HashMap<String,Par> identificadores]
	 @init {HashMap <String,Par>declarations_in = new HashMap<String,Par>();}
	:	 ((declaration[declarations_in]{declarations_in=$declaration.declarations_out;} 
		  |attrib [declarations_in]
		  | io[declarations_in]) ';' )*
		  		{$identificadores = $declaration.declarations_out;}
	;
	
declaration [HashMap<String,Par> declarations_in] returns [HashMap<String,Par> declarations_out]
	:	(tipo=Type_Int | tipo=Type_Real)   ID {
						if (declarations_in.containsKey($ID.text)){
							System.out.println( "A variavel " + $ID.text +" ja foi declarada antes.\n");
							declarations_out = declarations_in;
							}
						else	{
							Par p = new Par($tipo.text,0);
					 		 declarations_in.put($ID.text, p);
					 		 declarations_out = declarations_in;
							} 
						}
	;

attrib	[HashMap<String,Par> declarations_in]
	:	ID '=' expression [declarations_in] 
			{
				if (!declarations_in.containsKey($ID.text)){
					 System.out.println("A variavel "+ $ID.text + " ainda nao foi declarada!\n" );
					 }
				else {
					//declarations_in.setValue();
					if (declarations_in.get($ID.text).getTipo().equals("int") && $expression.tipo == Tipo.REAL )
						System.out.println( "Possivel perda de precis�o! (guardar real em variavel inteira)");
					//System.out.println(declarations_in.get($ID.text).getTipo());	
					//System.out.println($expression.tipo);
					//System.out.println($expression.valor + "<-valor");				
				}
			}
	;
	 
io	[HashMap<String,Par> declarations_in]
	:	'?' ID {}
	|	'!' expression [declarations_in]
	;
	
expression [HashMap<String,Par> declarations_in] 
	returns [Tipo tipo, float valor]
           @init {Tipo val = Tipo.INT; float valor; Tipo tipo;} 
	: 
	|	t1=term[declarations_in]{valor = $t1.valor;} (operatorAdd t2=term[declarations_in]{
									if($t2.tipo == Tipo.REAL)
										val = Tipo.REAL;
									if($operatorAdd.text.equals('+'))
										valor = valor + $t2.valor;
									else
										valor = valor - $t2.valor;})*
								 { 
								if($t1.tipo == Tipo.REAL || val == Tipo.REAL)
							 		tipo = Tipo.REAL;
							 	else 
							 		tipo = Tipo.INT;
							 	valor = $t1.valor + $t2.valor;
							 	}
					
	;
	
term	[HashMap<String,Par> declarations_in]
	returns [Tipo tipo, float valor]
	@init {Tipo val = Tipo.INT; float valor; Tipo tipo;}
	:	f1=factor[declarations_in]{valor = $f1.valor;} (operatorMul f2=factor[declarations_in]{
									if($f2.tipo == Tipo.REAL)
										val = Tipo.REAL;
									if($operatorMul.text.equals('*'))
										valor = valor * $f2.valor;
									else
										valor = valor / $f2.valor;})* 
							{if($f1.tipo == Tipo.REAL || val == Tipo.REAL) 
							 	tipo = Tipo.REAL;
							 else 
							 	tipo = Tipo.INT;
							 }  
	;
	
factor	[HashMap<String,Par> declarations_in]
	returns [Tipo tipo,float valor]
	@init { float valor=2000; Tipo tipo = Tipo.INT;}
	:	'(' expression[declarations_in] ')' {tipo = $expression.tipo; valor = $expression.valor;System.out.println($expression.valor);}
	| 	value[declarations_in] {tipo = $value.tipo; valor = $value.valor;System.out.println("valor na produ�ao factor: "+$value.valor);} 
	;
	
operatorAdd
	:	'+' | '-'
	;
	
operatorMul
	:	'*' | 'div'
	;
	
operator:	'+' | '-' | '*' | 'div'
	;
	

value  	[HashMap<String,Par> declarations_in]
	returns[Tipo tipo, float valor]
	@init {float valor;Tipo tipo = Tipo.INT;} 
 	:	ID {String type = declarations_in.get($ID.text).getTipo();
 		if (type.equals("int"))tipo = Tipo.INT; else tipo = Tipo.REAL; 
 		valor = declarations_in.get($ID.text).getValue();System.out.println("valor na produ�ao  value: "+valor);
 		} 
 		| INT {tipo = Tipo.INT; valor = Integer.parseInt($INT.text);System.out.println("valor na produ�ao  value: "+valor);}
 		| FLOAT {tipo = Tipo.REAL; valor = Float.parseFloat($FLOAT.text);System.out.println("valor na produ�ao  value: "+valor);}
 	;

Type_Int:	 'int'
	;
		
Type_Real
	:	'real'	 
	;


ID  :	('a'..'z'|'A'..'Z'|'_') ('a'..'z'|'A'..'Z'|'0'..'9'|'_')*
    ;

INT :	'0'..'9'+
    ;

FLOAT
    :   ('0'..'9')+ '.' ('0'..'9')* EXPONENT?
    |   '.' ('0'..'9')+ EXPONENT?
    |   ('0'..'9')+ EXPONENT
    ;

COMMENT
    :   '//' ~('\n'|'\r')* '\r'? '\n' {$channel=HIDDEN;}
    |   '/*' ( options {greedy=false;} : . )* '*/' {$channel=HIDDEN;}
    ;

WS  :   ( ' '
        | '\t'
        | '\r'
        | '\n'
        ) {$channel=HIDDEN;} 
    ;

fragment
EXPONENT : ('e'|'E') ('+'|'-')? ('0'..'9')+ ;

