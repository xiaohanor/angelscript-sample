class UJetskiWaterSurfaceEventsCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Local;
	
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::AfterGameplay;

	AJetski Jetski;
	float LastTimeInWater = -1;
	bool bHasBroadcastStartThrottleInWater;

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

			case EJetskiMovementState::Underwater:
				return false;

			default:
				break;
		}

		const float WaveHeight = Jetski.GetWaveHeight();
		const float BotOfSphere = Jetski.GetBotOfSphere();

		if((BotOfSphere - Jetski::VisualEvents::ExtraWaterDistance) > WaveHeight)
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

			case EJetskiMovementState::Underwater:
				return true;

			default:
				break;
		}

		const float WaveHeight = Jetski.GetWaveHeight();
		const float BotOfSphere = Jetski.GetBotOfSphere();

		if((BotOfSphere - Jetski::VisualEvents::ExtraWaterDistance) > WaveHeight)
		{
			const float DistanceAboveWater = BotOfSphere - WaveHeight;
			if(DistanceAboveWater < Jetski::VisualEvents::IgnoreExitWaterDelayDistance)
			{
				if(Time::GetGameTimeSince(LastTimeInWater) < Jetski::VisualEvents::ExitWaterDelay)
					return false;
			}

			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		UJetskiEventHandler::Trigger_OnStartWaterSurfaceVisual(Jetski);

		LastTimeInWater = Time::GameTimeSeconds;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if(bHasBroadcastStartThrottleInWater)
			UJetskiEventHandler::Trigger_OnStopThrottleInWaterVisual(Jetski);

		UJetskiEventHandler::Trigger_OnStopWaterSurfaceVisual(Jetski);

		LastTimeInWater = -1;
		bHasBroadcastStartThrottleInWater = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		LastTimeInWater = Time::GameTimeSeconds;

		UpdateIsThrottlingInWater();
	}

	private void UpdateIsThrottlingInWater()
	{
		check(IsActive());

		const bool bIsThrottling = Jetski.Input.IsThrottling();

		if(bHasBroadcastStartThrottleInWater == bIsThrottling)
			return;

		if(bIsThrottling)
			UJetskiEventHandler::Trigger_OnStartThrottleInWaterVisual(Jetski);
		else
			UJetskiEventHandler::Trigger_OnStopThrottleInWaterVisual(Jetski);

		bHasBroadcastStartThrottleInWater = bIsThrottling;
	}
};