class USummitWaterTempleInnerActivatorLeverResetCapability : UHazeCapability
{
	default TickGroup = EHazeTickGroup::ActionMovement;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	ASummitWaterTempleInnerActivatorLever Lever;

	const float LeverRotationMax = 20.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Lever = Cast<ASummitWaterTempleInnerActivatorLever>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FSummitWaterTempleLeverMoveParams& Params) const
	{
		if(!Lever.bResetRequested)
			return false;

		if(Time::GetGameTimeSince(Lever.LastTimeFinishedInteraction) < Lever.ResetDelay)
			return false;
		
		if(Time::GetGameTimeSince(Lever.LastTimeFinishedInteraction) < Lever.ResetDelay + Lever.ResetDuration)
		{
			// Lerp from whatever value we have currently to start
			Params.StartRoll = Lever.LeverRoot.RelativeRotation.Roll;
			Params.TargetRoll = Lever.GetStartRotationDegrees();
			Params.bLeverGoesToLeft = Lever.bLeverGoesToLeft;
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(ActiveDuration > Lever.ResetDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FSummitWaterTempleLeverMoveParams Params)
	{
		Lever.StartRoll = Params.StartRoll;
		Lever.TargetRoll = Params.TargetRoll;
		Lever.bLeverGoesToLeft = Params.bLeverGoesToLeft;
		Lever.OnResetStarted.Broadcast();
		// USummitWaterTempleInnerActivatorLeverEventHandler::Trigger_OnResetStarted(Lever);

		Lever.bResetRequested = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if(Lever.bReEnableAfterReset)
			Lever.InteractionComp.Enable(Lever);

		// Lever.RotateLever(1.0);
		Lever.OnResetFinished.Broadcast();
		// USummitWaterTempleInnerActivatorLeverEventHandler::Trigger_OnResetFinished(Lever);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// float Alpha = ActiveDuration / Lever.ResetDuration;
		// Lever.RotateLever(Alpha, 1.5);
	}
};