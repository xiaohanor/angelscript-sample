struct FAlienCruiserMissileLaunchParams
{
	UPROPERTY()
	USceneComponent MissileLaunchRoot;
}

struct FAlienCruiserMissileHitParams
{
	UPROPERTY()
	FVector MissileLocationAtImpact;

	UPROPERTY()
	FRotator MissileRotationAtImpact;
}

UCLASS(Abstract)
class UAlienCruiserEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnMissileLaunched(FAlienCruiserMissileLaunchParams Params)
	{

	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnMissileHit(FAlienCruiserMissileHitParams Params)
	{

	}
};