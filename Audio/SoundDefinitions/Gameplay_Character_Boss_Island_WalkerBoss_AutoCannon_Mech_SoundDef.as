
UCLASS(Abstract)
class UGameplay_Character_Boss_Island_WalkerBoss_AutoCannon_Mech_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void OnStoppedLaser(){}

	UFUNCTION(BlueprintEvent)
	void OnStartedLaser(FIslandWalkerLaserEventData Data){}

	UFUNCTION(BlueprintEvent)
	void OnShellExplosion(FIslandWalkerShellExplosionEventData Data){}

	UFUNCTION(BlueprintEvent)
	void OnTelegraphLaser(FIslandWalkerLaserEventData Data){}

	/* END OF AUTO-GENERATED CODE */

	UFUNCTION(BlueprintEvent)
	void OnLegDestroyed(AIslandWalkerLegTarget Leg)
	{
	}

	AAIIslandWalker Walker;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		Walker = Cast<AAIIslandWalker>(HazeOwner);
		Walker.LegsComp.OnLegDestroyed.AddUFunction(this, n"OnLegDestroyed");
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
}