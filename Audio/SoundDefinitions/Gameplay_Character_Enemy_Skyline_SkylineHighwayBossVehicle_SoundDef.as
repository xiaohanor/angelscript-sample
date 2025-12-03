
UCLASS(Abstract)
class UGameplay_Character_Enemy_Skyline_SkylineHighwayBossVehicle_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void OnDefeated(){}

	UFUNCTION(BlueprintEvent)
	void OnMoveToArenaSpline(){}

	UFUNCTION(BlueprintEvent)
	void OnMoveToBarrage(){}

	UFUNCTION(BlueprintEvent)
	void OnDamaged(){}

	/* END OF AUTO-GENERATED CODE */

	UPROPERTY(BlueprintReadOnly)
	ASkylineHighwayBossVehicle BossVehicle;

	USkylineHighwayBossVehicleGunComponent BossGunComp;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		BossVehicle = Cast<ASkylineHighwayBossVehicle>(HazeOwner);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		// GunComponent is created in runtime, so this is the ugly way to fetch it...
		if(BossGunComp == nullptr)
			BossGunComp = USkylineHighwayBossVehicleGunComponent::Get(BossVehicle);
	}

	UFUNCTION(BlueprintPure, Meta = (CompactNodeTitle = "Is In Barrage"))
	bool IsInBarrage() 
	{
		if(BossGunComp == nullptr)
			return false;

		return BossGunComp.bIsInBarrage;
	}

}