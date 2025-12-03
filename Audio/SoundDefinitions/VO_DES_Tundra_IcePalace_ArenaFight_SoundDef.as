
UCLASS(Abstract)
class UVO_DES_Tundra_IcePalace_ArenaFight_SoundDef : UHazeVOSoundDef
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void ChestBeltGrabbed(FTundraBossChestBeltData TundraBossChestBeltData){}

	UFUNCTION(BlueprintEvent)
	void ChestBeltDeactivating(FTundraBossChestBeltData TundraBossChestBeltData){}

	UFUNCTION(BlueprintEvent)
	void ChestBeltActivating(FTundraBossChestBeltData TundraBossChestBeltData){}

	UFUNCTION(BlueprintEvent)
	void TakeDamageHitByBall(){}

	UFUNCTION(BlueprintEvent)
	void TakeDamageGroundSlam(){}

	UFUNCTION(BlueprintEvent)
	void OnMonkeyPunchStarted(){}

	UFUNCTION(BlueprintEvent)
	void OnFloored(){}

	UFUNCTION(BlueprintEvent)
	void OnBreakFreeNoDamage(){}

	UFUNCTION(BlueprintEvent)
	void OnBreakFreeAfterDamage(){}

	UFUNCTION(BlueprintEvent)
	void OnBreakFreeFromStruggle(){}

	UFUNCTION(BlueprintEvent)
	void OnClawAttackStarted(){}

	UFUNCTION(BlueprintEvent)
	void OnAttack(FTundraBossAttackData TundraBossAttackData){}

	UFUNCTION(BlueprintEvent)
	void OnClawAttackEnded(){}

	UFUNCTION(BlueprintEvent)
	void OnClawAttackLeft(){}

	UFUNCTION(BlueprintEvent)
	void OnClawAttackRight(){}

	/* END OF AUTO-GENERATED CODE */

	UFUNCTION(BlueprintEvent)
	void OnPlayerDied() {}
	
	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		for (auto Player : Game::Players)
		{
			auto HealthComp = UPlayerHealthComponent::Get(Player);
			HealthComp.OnStartDying.AddUFunction(this, n"OnPlayerDied");
		}
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		for (auto Player : Game::Players)
		{
			auto HealthComp = UPlayerHealthComponent::Get(Player);
			HealthComp.OnStartDying.UnbindObject(this);			
		}
	}

}