
UCLASS(Abstract)
class UGameplay_Character_Boss_Island_WalkerBoss_FlameThrower_SoundDef : USoundDefBase
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
	void OnFireBurstStop(){}

	UFUNCTION(BlueprintEvent)
	void OnFireBurstStart(FIslandWalkerSprayFireParams Params){}

	UFUNCTION(BlueprintEvent)
	void OnFireBurstTelegraph(FIslandWalkerSprayFireParams Params){}

	/* END OF AUTO-GENERATED CODE */

	AAIIslandWalker Walker;
	AIslandWalkerHead WalkerHead;

	UPROPERTY(NotVisible)
	UHazeAudioEmitter FlameImpactEmitter;

	UFUNCTION(BlueprintEvent)
	void OnLegDestroyed(AIslandWalkerLegTarget Leg) {}		

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		WalkerHead = Cast<AIslandWalkerHead>(HazeOwner);

		Walker = Cast<AAIIslandWalker>(WalkerHead.HeadComp.NeckCableOrigin.Owner);
		Walker.LegsComp.OnLegDestroyed.AddUFunction(this, n"OnLegDestroyed");
	}

	UFUNCTION(BlueprintOverride)
	bool OverrideEmitterSceneAttachment(FName EmitterName, FName& ComponentName, AHazeActor& TargetActor,
										FName& BoneName, bool& bUseAttach)
	{
		TargetActor = HazeOwner;
		if(EmitterName == n"FlameImpactEmitter")
			bUseAttach = false;

		return true;
		
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(Walker.WalkerComp.bSuspended)
			return false;

		if(Walker.LegsComp.bIsUnbalanced)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Walker.WalkerComp.bSuspended)
			return true;

		if(Walker.LegsComp.bIsUnbalanced)
			return true;

		return false;
	}


	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		const FVector FuelSprayForwardLocation = WalkerHead.FlameThrower.WorldLocation + (WalkerHead.FlameThrower.ForwardVector * 1200);
		FlameImpactEmitter.SetEmitterLocation(FuelSprayForwardLocation, true);
	}

}