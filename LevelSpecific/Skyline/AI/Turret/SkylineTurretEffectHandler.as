struct FSkylineTurretBladeHitImpactParams
{
	FSkylineTurretBladeHitImpactParams(FVector Location)
	{
		HitLocation = Location;
	}

	UPROPERTY()
	FVector HitLocation;
}

struct FSkylineTurretTelegraphingParams
{
	FSkylineTurretTelegraphingParams(USceneComponent Left, USceneComponent Right, FVector TurretLocation, float Duration)
	{
		MuzzleLeft = Left;
		MuzzleRight = Right;
		TurretActorLocation = TurretLocation;
		TelegraphDuration = Duration;
	}

	UPROPERTY()
	USceneComponent MuzzleLeft;
	
	UPROPERTY()
	USceneComponent MuzzleRight;
	
	UPROPERTY()
	FVector TurretActorLocation;

	UPROPERTY()
	float TelegraphDuration;
}


UCLASS(Abstract)
class USkylineTurretEffectHandler : UHazeEffectEventHandler
{
    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnDeath() {}

    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnDamage(FSkylineTurretBladeHitImpactParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnStartTelegraphing(FSkylineTurretTelegraphingParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnStopTelegraphing() {}
}