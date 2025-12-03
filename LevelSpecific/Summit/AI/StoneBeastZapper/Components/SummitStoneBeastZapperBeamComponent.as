class USummitStoneBeastZapperBeamComponent : UActorComponent
{
	UPROPERTY()
	FSummitStoneBeastZapperBeamParams BeamParams;
}

struct FSummitStoneBeastZapperBeamParams
{
	UPROPERTY()
	FVector BeamStartLocation;

	UPROPERTY()
	FVector BeamEndLocation;
}