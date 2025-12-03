class USkylineBossStrafeRunAttackCapability : USkylineBossChildCapability
{
	default CapabilityTags.Add(SkylineBossTags::SkylineBossAttack);
	default CapabilityTags.Add(SkylineBossTags::SkylineBossStrafeRunAttack);

	TArray<USkylineBossStrafeRunComponent> StrafeRunComponents;
	TArray<ASkylineBossStrafeRun> StrafeRunActors;
	TArray<AActor> ActorsToIgnore;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();

		Boss.GetComponentsByClass(StrafeRunComponents);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (DeactiveDuration < 5.0)
			return false;

		if (Boss.LookAtTarget.Get() == nullptr)
			return false;

		if (Owner.GetDistanceTo(Boss.LookAtTarget.Get()) < Boss.Settings.MinLongRangeAttacks)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ActiveDuration > 2.0)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		auto Target = Boss.LookAtTarget.Get();

		PrintToScreen("StrafeRun" + Target, 3.0, FLinearColor::Green);
	
		for (auto StrafeRunComponent : StrafeRunComponents)
			StrafeRunComponent.BeginStrafeRun(Target);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		for (auto StrafeRunComponent : StrafeRunComponents)
			StrafeRunComponent.AbortStrafeRun();
	}
}