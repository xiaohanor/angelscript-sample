class UBallistaHydraSplinePlatformWaveLaunchCapability : UHazeCapability
{
	default TickGroup = EHazeTickGroup::Gameplay;

	ABallistaHydraSplinePlatform Platform;
	UMedallionPlayerReferencesComponent MioRefsComp;

	int LastActivationCounter = 0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MioRefsComp = UMedallionPlayerReferencesComponent::GetOrCreate(Game::Mio);
		Platform = Cast<ABallistaHydraSplinePlatform>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MioRefsComp.Refs == nullptr)
			return false;
		if (!MioRefsComp.Refs.WaveAttackActor.bWaveActive)
			return false;
		if (LastActivationCounter >= MioRefsComp.Refs.WaveAttackActor.WaveActivationCounter)
			return false;
		if (!MioRefsComp.Refs.WaveAttackActor.InWaveRange(Platform.ActorLocation))
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
		LastActivationCounter = MioRefsComp.Refs.WaveAttackActor.WaveActivationCounter;
		Platform.bLaunchPlatform = true;

		FMedallionHydraWaveAttackPlatformData Data;
		Data.Platform = Platform;
		UMedallionHydraWaveAttackEventHandler::Trigger_OnWaveAttackPlatformLaunch(MioRefsComp.Refs.WaveAttackActor, Data);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Platform.bLaunchPlatform = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
	}
};