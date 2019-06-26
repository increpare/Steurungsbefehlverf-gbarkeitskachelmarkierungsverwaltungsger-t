import haxe.rtti.XmlParser;
import haxe.ds.Vector;
import js.html.svg.AnimatedBoolean;
import haxegon.*;
import utils.*;
import starling.core.Starling;
import StringTools;
import haxe.Serializer;
import haxe.Unserializer;



class Main {	

	private static function playSound(s:Int){
		if (Globals.state.audio==0){
			return;
		}
		untyped __js__('playSound({0},0.2)',s);
	}

	//rot(1) 62, 84

	//blau(2) 26, 120	

	//orange(3) 62, 120

	//grün(4) 26,84 - 


	var farben_offs_x = [62,26,62,26];
	var farben_offs_y = [84,120,120,84];

	var tasten_offs_x = [6,6,0,18];
	var tasten_offs_y = [0,18,6,6];

	//[farbe][richtung]
	var tasten_namen = [];

 	static public function deepCopy<T>( arr : Array<T> ) : Array<T>
    {

        if(arr.length > 0 && Std.is(arr[0], Array)){
            var r = new Array<T>();
            for( i in 0...arr.length ) {
                r.push(cast deepCopy(untyped arr[i]));
            }
            return r;
        } else {
            return arr.copy();
        }
    }

	var posses = [[1,1],[1,2],[2,1],[2,2]];

	function setup(){
		Gfx.clearcolor = Col.TRANSPARENT;
		Starling.current.stage.color=0x000000;

		var richtungenNamen = ["oben","unten","links","rechts"];

		for (i in 0...4){//farbe
			var reihe = [];
			for (j in 0...4){//richtung
				var n = (i+1)+"_"+richtungenNamen[j];
				reihe.push(n);
			}
			tasten_namen.push(reihe);
		}
		trace(tasten_namen);
	}
	
	var letzte_breite:Int=-1;
	var coff_x:Int=0;
	var coff_y:Int=0;
	
	function redrawbg(){
		var sw:Int = Gfx.screenwidth;
		var sh:Int = Gfx.screenheight;
		letzte_breite=sw;
		var tw = Gfx.imagewidth("bgtile");
		var th = Gfx.imageheight("bgtile");

		var i=0;
		while(i<sw){
			var j=0;
			while (j<sw){
				Gfx.drawimage(i,j,"bgtile");
				j+=th;
			}
			i+=tw;
		}

		var cw = Gfx.imagewidth("bg");
		// var ch = Gfx.imagewidth("bh");

		coff_x = Math.floor(sw/2-cw/2);
		coff_y = 0; 
		Gfx.drawimage(coff_x,coff_y,"bg");
	}

	function reset(){
		setup();
	}
	
	function init(){
		// Sound.play("t2");
		//Music.play("music",0,true);
		Gfx.resizescreen(0, 182,true);
		SpriteManager.enable();
		setup();
	
	}	
	

	var tick:Int=0;

	var target_farbe:Int=-1;
	var target_richtung:Int=-1;
	var an:Bool=false;
	var gewonnen:Bool=false;

	var cursornamen = ["cursor1","cursor2","cursor3","cursor4"];

	var Richtungraster = [
		[2,3,2,1],
		[0,3,0,0],
		[1,1,2,1],
		[0,3,2,3]
		];

	var deltas = [ 
		[0,-1],
		[0,1],
		[-1,0],
		[1,0],
	];

	function kannsteueren(richtung:Int):Bool{
		for (i in 0...4){
			var px = posses[i][0];
			var py = posses[i][1];
			var r = Richtungraster[px][py];
			if (r==richtung){
				return true;
			}
		}
		return false;
	}

	function PosAt(x:Int,y:Int):Int{
		if (x<0||x>3 || y<0||y>3){
			return -1;
		}
		for (i in 0...4){
			var p = posses[i];
			if (p[0]==x&&p[1]==y){
				return i;
			}
		}
		return -1;
	}

	var undostack : Array<Array<Array<Int>>>=[];

	function versuchUndo(){
		if (undostack.length==0){
			//BEEP undostack leer
			return;
		}
	 	posses = undostack.pop();
		 //BEEP rückgängig SFX
	}
	function druck(farbe:Int,richtung:Int){
		if (farbe==4){
			versuchUndo();
			return;
		}
		if (kannsteueren(richtung)==false){
			//BEEP (nicht besetzt)
			return;
		}
		var posseskopie = deepCopy(posses);
		var p = posses[farbe];
		var px = p[0];
		var py = p[1];	
		var tx = px+deltas[richtung][0];
		var ty = py+deltas[richtung][1];
		if (tx<0||tx>3 || ty<0||ty>3){
			//BEEP (out of bounds)
			return;
		} 

		if (PosAt(tx,ty)>=0){
			//BEEP collision
			return;
		}

		p[0]=tx;
		p[1]=ty;

		//BEEP erfolgereiche bewegung

		undostack.push(posseskopie);
		checkSolve();
	}
	
	var targetposses = [
		[3,0],
		[3,3],
		[0,0],
		[0,3]
	];

	function checkSolve(){
		//rbog
		for (i in 0...4){			
			if (
				targetposses[i][0]!=posses[i][0] ||
				targetposses[i][1]!=posses[i][1]
			) {
				return;
			}
		}
		gewonnen=true;
		//BEEP
	}

	function update() {	
		tick++;

		if (letzte_breite!=Gfx.screenwidth){
			letzte_breite=Gfx.screenwidth;
			redrawbg();
		}

		var hover:Bool=false;

		if (Mouse.leftclick()){
			var mx = Mouse.x;
			var my = Mouse.y;
			var ox = mx-coff_x;
			var oy = my-coff_y;
			target_farbe=-1;
			target_richtung=-1;

			//Steurungtasten
			if (
				(ox>=Globals.tastenhitmaskBounds.x)
				&& (ox<Globals.tastenhitmaskBounds.x+Globals.tastenhitmaskBounds.w)
				&& (oy>=Globals.tastenhitmaskBounds.y)
				&& (oy<Globals.tastenhitmaskBounds.y+Globals.tastenhitmaskBounds.h)
				
			) {
				var o2x=ox-Globals.tastenhitmaskBounds.x;
				var o2y=oy-Globals.tastenhitmaskBounds.y;
				var thm = Globals.tastenhitmask[o2x+Globals.tastenhitmaskBounds.h*o2y];
				trace("THM " +thm);
				if (thm>0){
					target_farbe = Globals.tastenhitmaskdictinv[thm][0];
					target_richtung = Globals.tastenhitmaskdictinv[thm][1];
					if (an){
						druck(target_farbe,target_richtung);
					}
					hover=true;
				}
			} else if (
				(ox>=Globals.anaufhitmaskBounds.x)
				&& (ox<Globals.anaufhitmaskBounds.x+Globals.anaufhitmaskBounds.w)
				&& (oy>=Globals.anaufhitmaskBounds.y)
				&& (oy<Globals.anaufhitmaskBounds.y+Globals.anaufhitmaskBounds.h)
				) {
					an=!an;
					if (an){
						posses = [[1,1],[1,2],[2,1],[2,2]];
						gewonnen=false;
						undostack=[];
					}
				}
		} else if (!Mouse.leftheld()){
			target_farbe=-1;
			target_richtung=-1;
		}


		Gfx.drawimage(coff_x,coff_y,"bg");
		if ( an){
			Gfx.drawimage(coff_x+19,coff_y+13,"poweron");

			if (gewonnen){
				Gfx.drawimage(coff_x+29,coff_y+15,"endbildschirm");

			} else {
				Gfx.drawimage(coff_x+29,coff_y+15,"spielbildschirm");
				

				for (i in 0...4){
					var p = posses[i];
					var sx = coff_x + 29 + 16*p[0] + 1;
					var sy = coff_y + 15 + 16*p[1] + 1;
					Gfx.drawimage(sx,sy,cursornamen[i]);
				}
			}
		}

		if (target_farbe==4){//rückgängig
			var t_x = coff_x + 54;
			var t_y = coff_y + 112;
			Gfx.drawimage(t_x,t_y,"ruchgaengig");				

		} else if (target_farbe>=0){
			var t_x = coff_x + farben_offs_x[target_farbe] + tasten_offs_x[target_richtung];
			var t_y = coff_y + farben_offs_y[target_farbe] + tasten_offs_y[target_richtung];
			var t_name = tasten_namen[target_farbe][target_richtung];
			Gfx.drawimage(t_x,t_y,t_name);				
		}
	}
}
