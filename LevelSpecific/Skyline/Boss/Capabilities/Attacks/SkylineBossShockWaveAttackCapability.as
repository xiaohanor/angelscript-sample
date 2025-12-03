class USkylineBossShockWaveAttackCapability : USkylineBossChildCapability
{
	default CapabilityTags.Add(SkylineBossTags::SkylineBossAttack);
	default CapabilityTags.Add(SkylineBossTags::SkylineBossShockwaveAttack);

	TArray<AActor> ActorsToIgnore;
	USkylineBossShockWaveComponent ShockWaveComponent;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
	
		ShockWaveComponent = USkylineBossShockWaveComponent::Get(Owner);
	}	

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(Boss.bIsControlledByCutscene)
			return false;

		if(!Boss.CoreComponent.IsCoreExposed())
			return false;

		if (DeactiveDuration < 3.0)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		FVector SpawnLocation = Boss.CoreCollision.WorldLocation;
		SpawnLocation.Z = Boss.CurrentHub.ActorLocation.Z;

		auto ShockWave = SpawnActor(ShockWaveComponent.ShockWaveClass, SpawnLocation);
		ShockWaveComponent.ShockWaves.Add(ShockWave);
		ShockWave.OnEndPlay.AddUFunction(ShockWaveComponent, n"RemoveShockWave");
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}
}