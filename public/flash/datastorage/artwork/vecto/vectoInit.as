
//attach the artwork with it's center on top left
var ArtWork = attachMovie("ArtWork", "ArtWork", 10000, {_visible:false});
bg._x = -50;
bg._y = -50;

//vector inmages have layers that need to be set
this._parent.v_setColor(ArtWork);//calls DS_ItemMC

//Don't hide the background if it isn't loaded list as I want to hide hte loading symbol
if(this._parent.hideBG){
	
	bg._visible = false;
	
}