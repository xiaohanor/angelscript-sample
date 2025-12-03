UCLASS(Abstract)
class USkylineHighwayBossVehicleEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnMoveToBarrage() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnGunStartTelegraphing(FSkylineHighwayBossVehicleEffectHandlerOnGunStartTelegraphingData Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnGunStopTelegraphing() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnGunFire(FSkylineHighwayBossVehicleEffectHandlerOnGunFireData Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnMoveToArenaSpline() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnDamaged() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnDefeated() {}
}

struct FSkylineHighwayBossVehicleEffectHandlerOnGunStartTelegraphingData
{
	FSkylineHighwayBossVehicleEffectHandlerOnGunStartTelegraphingData(USceneComponent Left, USceneComponent Right, float Duration)
	{
		MuzzleLeft = Left;
		MuzzleRight = Right;
		TelegraphDuration = Duration;
	}

	UPROPERTY()
	USceneComponent MuzzleLeft;
	
	UPROPERTY()
	USceneComponent MuzzleRight;
	
	UPROPERTY()
	float TelegraphDuration;
}

struct FSkylineHighwayBossVehicleEffectHandlerOnGunFireData
{
	FSkylineHighwayBossVehicleEffectHandlerOnGunFireData(USceneComponent _Muzzle, int _ShotIndex)
	{
		Muzzle = _Muzzle;
		ShotIndex = ShotIndex;
	}

	UPROPERTY()
	USceneComponent Muzzle;

	UPROPERTY()
	int ShotIndex = 0;
}