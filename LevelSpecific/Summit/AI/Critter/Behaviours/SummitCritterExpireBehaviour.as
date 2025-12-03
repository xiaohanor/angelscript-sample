class USummitCritterExpireBehaviour : UBasicBehaviour
{
	USummitCritterSettings CritterSettings;
	UBasicAIHealthComponent HealthComp;
	UHazeActorRespawnableComponent RespawnComp;

	float SpawnTime;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		CritterSettings = USummitCritterSettings::GetSettings(Owner);
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		RespawnComp = UHazeActorRespawnableComponent::Get(Owner);

		RespawnComp.OnRespawn.AddUFunction(this, n"OnReset");
		OnReset();
	}

	UFUNCTION()
	private void OnReset()
	{
		SpawnTime = Time::GetGameTimeSeconds();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if(Time::GetGameTimeSince(SpawnTime) > CritterSettings.LifeDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		HealthComp.Die();
	}
}