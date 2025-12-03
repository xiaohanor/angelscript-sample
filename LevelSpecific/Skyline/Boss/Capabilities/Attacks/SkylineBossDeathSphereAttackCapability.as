class USkylineBossDeathSphereAttackCapability : USkylineBossChildCapability
{
	default CapabilityTags.Add(SkylineBossTags::SkylineBossAttack);

	TArray<AActor> ActorsToIgnore;
	USkylineBossDeathSphereComponent DeathSphereComponent;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
	
		DeathSphereComponent = USkylineBossDeathSphereComponent::Get(Boss);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ActiveDuration > 5.0)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		auto Target = Boss.LookAtTarget.Get();

		PrintToScreen("DeathSphere!" + Target, 3.0, FLinearColor::Green);

		SpawnActor(DeathSphereComponent.DeathSphereClass, Boss.ActorLocation, Boss.ActorRotation);
	
		for (auto Player : Game::Players)
		{
			FHazePointOfInterestFocusTargetInfo POITarget;
			POITarget.SetFocusToActor(Owner);

			FApplyPointOfInterestSettings POISettings;
			POISettings.Duration = 2.0;
			Player.ApplyPointOfInterest(this, POITarget, POISettings, 2.0, EHazeCameraPriority::VeryHigh);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}
}