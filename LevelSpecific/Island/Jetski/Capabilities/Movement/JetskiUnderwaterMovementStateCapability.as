class UJetskiUnderwaterMovementStateCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Local;

	default CapabilityTags.Add(CapabilityTags::Movement);

	default TickGroup = EHazeTickGroup::LastMovement;

	AJetski Jetski;
	UHazeMovementComponent MoveComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Jetski = Cast<AJetski>(Owner);
		MoveComp = Jetski.MoveComp;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(Jetski.GetMovementState() != EJetskiMovementState::Underwater)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Jetski.GetMovementState() != EJetskiMovementState::Underwater)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		FJetskiOnEnterUnderwaterEventData EventData;
		EventData.Location = Jetski.GetWaveLocation();
		EventData.Velocity = MoveComp.Velocity;
		EventData.WaveNormal = Jetski.GetUpVector(EJetskiUp::WaveNormal);
		EventData.bEnterWasFromAir = Jetski.GetPreviousMovementState() == EJetskiMovementState::Air;
		EventData.bEnterWasFromGround = Jetski.GetPreviousMovementState() == EJetskiMovementState::Ground;
		UJetskiEventHandler::Trigger_OnStartUnderwaterMovement(Jetski, EventData);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		FJetskiOnExitUnderwaterEventData EventData;
		EventData.Location = Jetski.GetWaveLocation();
		EventData.Velocity = MoveComp.Velocity;
        EventData.bExitWasJump = Jetski.bIsJumpingFromUnderwater;
		UJetskiEventHandler::Trigger_OnStopUnderwaterMovement(Jetski, EventData);
	}
};