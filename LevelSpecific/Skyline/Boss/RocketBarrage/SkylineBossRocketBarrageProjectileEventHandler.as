struct FSkylineBossRocketBarrageOnImpactEventData
{
	UPROPERTY(BlueprintReadOnly)
	FVector Location;

	UPROPERTY(BlueprintReadOnly)
	FVector Normal;
};

UCLASS(Abstract)
class USkylineBossRocketBarrageProjectileEventHandler : UHazeEffectEventHandler
{
	UPROPERTY(NotEditable, BlueprintReadOnly)
	ASkylineBossRocketBarrageProjectile Rocket;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Rocket = Cast<ASkylineBossRocketBarrageProjectile>(Owner);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLaunch() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnImpact(FSkylineBossRocketBarrageOnImpactEventData EventData) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnUnspawn() {}
};