class UIslandZombieDeathComponent : UActorComponent
{
	AHazeActor HazeOwner;
	UHazeActorRespawnableComponent RespawnComp;
	UBasicAIHealthComponent HealthComp;
	UIslandNunchuckTargetableComponent NunchuckTargetableComp;
	UScifiCopsGunShootTargetableComponent CopsGunsShootTargetableComp;
	UScifiCopsGunThrowTargetableComponent CopsGunsThrowTargetableComp;
	UIslandNecromancerReviveTargetComponent ReviveComp;

	bool bDeathActive;
	FVector DeathDirection;
	EIslandZombieDeathType DeathType = EIslandZombieDeathType::MAX;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		HazeOwner = Cast<AHazeActor>(Owner);
		NunchuckTargetableComp = UIslandNunchuckTargetableComponent::Get(Owner);
		CopsGunsShootTargetableComp = UScifiCopsGunShootTargetableComponent::Get(Owner);
		CopsGunsThrowTargetableComp = UScifiCopsGunThrowTargetableComponent::Get(Owner);
		RespawnComp = UHazeActorRespawnableComponent::Get(Owner);
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		RespawnComp.OnRespawn.AddUFunction(this, n"OnRespawn");

		ReviveComp = UIslandNecromancerReviveTargetComponent::GetOrCreate(Owner);
		ReviveComp.OnRevive.AddUFunction(this, n"OnRevive");

		Reset();
	}

	UFUNCTION()
	private void OnRevive()
	{
		ReviveComp.bEnabled = false;
		HealthComp.Reset();
		OnRespawn();
	}

	bool IsDead()
	{
		return HealthComp.IsDead() && !bDeathActive;
	}

	void StartDeath()
	{
		bDeathActive = true;
		Owner.AddActorCollisionBlock(this);

		// Turn off all the targetables
		NunchuckTargetableComp.Disable(n"Death");
		CopsGunsShootTargetableComp.Disable(n"Death");
		CopsGunsThrowTargetableComp.Disable(n"Death");
	}

	void CompleteDeath()
	{
		if(HealthComp.IsDead() && ReviveComp.IsRevivable())
			ReviveComp.bEnabled = true;
		else
			Owner.AddActorDisable(this);
		UBasicAIDamageEffectHandler::Trigger_OnDeath(HazeOwner);
	}

	void Reset()
	{
		DeathDirection = FVector::ZeroVector;
		DeathType = EIslandZombieDeathType::MAX;
	}

	UFUNCTION()
	private void OnRespawn()
	{
		HazeOwner.RemoveActorDisable(this);		
		bDeathActive = false;
		Owner.RemoveActorCollisionBlock(this);

		NunchuckTargetableComp.Enable(n"Death");
		CopsGunsShootTargetableComp.Enable(n"Death");
		CopsGunsThrowTargetableComp.Enable(n"Death");
		
		Reset();
	}
}

enum EIslandZombieDeathType
{
	Pushing,
	MAX
}