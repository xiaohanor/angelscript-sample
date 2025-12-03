class USkylineBossTankAutoCannonAttackCapability : USkylineBossTankChildCapability
{
	default CapabilityTags.Add(SkylineBossTankTags::SkylineBossTankAttack);
	default CapabilityTags.Add(SkylineBossTankTags::Attacks::SkylineBossTankAttackAutoCannon);

	TArray<USkylineBossTankAutoCannonComponent> AutoCannonComponents;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		
		BossTank.GetComponentsByClass(AutoCannonComponents);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
//		return false;

		if (!BossTank.HasValidTargetPlayer())
			return false;

//		if (!BossTank.HasAttackTarget())
//			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!BossTank.HasValidTargetPlayer())
			return true;

//		if (!BossTank.HasAttackTarget())
//			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		for (auto AutoCannonComponent : AutoCannonComponents)
		{
			AutoCannonComponent.AddTarget(Game::Mio);
			AutoCannonComponent.AddTarget(Game::Zoe);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		for (auto AutoCannonComponent : AutoCannonComponents)
		{
			AutoCannonComponent.Targets.Reset();
			AutoCannonComponent.Targets.Add(BossTank.GetAttackTarget());
			AutoCannonComponent.UpdateTargeting(DeltaTime);
		
			if (AutoCannonComponent.CanFire())
				AutoCannonComponent.Fire();
		}
	}
}