struct FAlienCruiserMissileExplosionResponseParams
{
	UPROPERTY()
	FVector MissileLocationAtImpact;

	UPROPERTY()
	FRotator MissileRotationAtImpact;

	UPROPERTY()
	float DistanceToMissileAtImpact;
}

event void FAlienCruiseMissileExplosionResponse(FAlienCruiserMissileExplosionResponseParams Params);

class UAlienCruiserMissileResponseComponent : USceneComponent
{
	UPROPERTY()
	FAlienCruiseMissileExplosionResponse OnMissileExploded;
};