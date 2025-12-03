struct FSummitExplodyFruitExplosionParams
{
	UPROPERTY()
	FVector ExplosionLocation;

	UPROPERTY()
	UPrimitiveComponent HitComponent;
}

event void FOnExplodyFruitExplode(FSummitExplodyFruitExplosionParams Params);

class USummitExplodyFruitResponseComponent : UActorComponent
{
	UPROPERTY()
	FOnExplodyFruitExplode OnFruitExplode;
};