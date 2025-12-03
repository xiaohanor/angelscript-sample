class UJetskiAirEventsCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Local;
	
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::AfterGameplay;

	AJetski Jetski;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Jetski = Cast<AJetski>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		switch(Jetski.GetMovementState())
		{
			case EJetskiMovementState::Ground:
				return false;

			case EJetskiMovementState::Water:
				return false;

			case EJetskiMovementState::Underwater:
				return false;

			default:
				break;
		}

		const float WaveHeight = Jetski.GetWaveHeight();
		const float BotOfSphere = Jetski.GetBotOfSphere();

		if((BotOfSphere - Jetski::VisualEvents::ExtraWaterDistance) < WaveHeight)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		switch(Jetski.GetMovementState())
		{
			case EJetskiMovementState::Ground:
				return true;

			case EJetskiMovementState::Water:
				return true;

			case EJetskiMovementState::Underwater:
				return true;

			default:
				break;
		}

		const float WaveHeight = Jetski.GetWaveHeight();
		const float BotOfSphere = Jetski.GetBotOfSphere();

		if((BotOfSphere - Jetski::VisualEvents::ExtraWaterDistance) < WaveHeight)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		UJetskiEventHandler::Trigger_OnStartAirVisual(Jetski);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		UJetskiEventHandler::Trigger_OnStopAirVisual(Jetski);
	}
};