class UIslandBuzzerPostLaunchTargetingCapability : UHazeCapability
{
	// Deterministic based on crumbed respawn
	default NetworkMode = EHazeCapabilityNetworkMode::Local;

	default CapabilityTags.Add(n"PostLaunchTargeting");

	default TickGroup = EHazeTickGroup::Gameplay;

	UIslandRedBlueTargetableComponent TargetableComp;
	UHazeActorRespawnableComponent RespawnComp;
	UIslandWalkerSettings Settings;
	float NerfTargetingTime = 0.0;
	float DefaultRange;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		TargetableComp = UIslandRedBlueTargetableComponent::Get(Owner);
		DefaultRange = TargetableComp.MaximumDistance;
		RespawnComp = UHazeActorRespawnableComponent::Get(Owner);
		RespawnComp.OnRespawn.AddUFunction(this, n"OnRespawn");
	}

	UFUNCTION()
	private void OnRespawn()
	{
		Settings = UIslandWalkerSettings::GetSettings(Cast<AHazeActor>(RespawnComp.Spawner));
		NerfTargetingTime = Time::GameTimeSeconds + Settings.PostSpawnNerfedTargetingDuration;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Settings == nullptr)
			return false;
		if (Time::GameTimeSeconds > NerfTargetingTime)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Time::GameTimeSeconds > NerfTargetingTime)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		TargetableComp.MaximumDistance = Settings.PostSpawnNerfedTargetingRange;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		TargetableComp.MaximumDistance = DefaultRange;
	}
};