
UCLASS(Abstract)
class UGameplay_Character_Boss_Island_WalkerBoss_FuelFlameThrower_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void OnHeadChaseSprayFireStop(){}

	UFUNCTION(BlueprintEvent)
	void OnHeadChaseSprayFireStart(FIslandWalkerSprayFireParams Params){}

	UFUNCTION(BlueprintEvent)
	void OnHeadChaseTelegraphFire(FIslandWalkerSprayFireParams Params){}

	UFUNCTION(BlueprintEvent)
	void OnFirewallIgnitionStop(){}

	UFUNCTION(BlueprintEvent)
	void OnFirewallIgnitionStart(FIslandWalkerSprayFireParams Params){}

	UFUNCTION(BlueprintEvent)
	void OnFirewallTelegraphIgnition(FIslandWalkerSprayFireParams Params){}

	UFUNCTION(BlueprintEvent)
	void OnFirewallSprayFuelStop(){}

	UFUNCTION(BlueprintEvent)
	void OnFirewallSprayFuelStart(FIslandWalkerSprayFireParams Params){}

	UFUNCTION(BlueprintEvent)
	void OnFirewallSprayFuelTelegraph(FIslandWalkerSprayFireParams Params){}

	UFUNCTION(BlueprintEvent)
	void OnFireBurstTelegraph(FIslandWalkerSprayFireParams Params){}

	/* END OF AUTO-GENERATED CODE */

	AIslandWalkerHead WalkerHead;

	UPROPERTY(NotVisible)
	UHazeAudioEmitter SprayImpactEmitter;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		WalkerHead = Cast<AIslandWalkerHead>(HazeOwner);
	}

	UFUNCTION(BlueprintOverride)
	bool OverrideEmitterSceneAttachment(FName EmitterName, FName& ComponentName, AHazeActor& TargetActor,
										FName& BoneName, bool& bUseAttach)
	{
		TargetActor = HazeOwner;
		if(EmitterName == n"SprayImpactEmitter")
			bUseAttach = false;

		return true;
		
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		const FVector FuelSprayForwardLocation = WalkerHead.FuelAndFlameThrower.WorldLocation + (WalkerHead.FuelAndFlameThrower.ForwardVector * 1200);
		SprayImpactEmitter.SetEmitterLocation(FuelSprayForwardLocation, true);
	}

}