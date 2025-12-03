struct FCoastBossPlayerLaserOnImpactTickEffectParams
{
	UPROPERTY()
	FVector HitLocation;

	UPROPERTY()
	USceneComponent PlaneToAttachTo;
}

struct FCoastBossPlayerLaserStartImpactingEffectParams
{
	UPROPERTY()
	FVector HitLocation;

	UPROPERTY()
	USceneComponent PlaneToAttachTo;
}

struct FCoastBossPlayerLaserStopImpactingEffectParams
{
	UPROPERTY()
	USceneComponent PlaneToAttachTo;
}

UCLASS(Abstract)
class UCoastBossPlayerLaserEffectHandler : UHazeEffectEventHandler
{
	UPROPERTY(BlueprintReadOnly, NotVisible, Transient)
	ACoastBossPlayerLaser Laser;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Laser = Cast<ACoastBossPlayerLaser>(Owner);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnImpactTick(FCoastBossPlayerLaserOnImpactTickEffectParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartImpactingCoastBoss(FCoastBossPlayerLaserStartImpactingEffectParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStopImpactingCoastBoss(FCoastBossPlayerLaserStopImpactingEffectParams Params) {}

	UFUNCTION(BlueprintPure)
	FVector GetBeamEnd()
	{
		return Laser.BeamEnd;
	}
}