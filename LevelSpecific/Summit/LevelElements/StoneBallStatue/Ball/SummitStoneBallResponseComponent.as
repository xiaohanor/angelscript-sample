struct FSummitStoneBallExplosionParams
{
	UPROPERTY()
	FVector ExplosionLocation;

	UPROPERTY()
	UPrimitiveComponent HitComponent;
}

event void FOnStoneBallExplode(FSummitStoneBallExplosionParams Params);

class USummitStoneBallResponseComponent : UActorComponent
{
	UPROPERTY()
	FOnStoneBallExplode OnStoneBallExploded;
};