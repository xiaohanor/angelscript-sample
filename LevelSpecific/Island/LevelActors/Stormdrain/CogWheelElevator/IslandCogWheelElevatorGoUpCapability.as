struct FIslandStormdrainAlternatingCogWheelElevatorGoUpActivationParams
{
	float MoveUpDistance;
}

class UIslandStormdrainAlternatingCogWheelElevatorGoUpCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default TickGroup = EHazeTickGroup::Gameplay;

	AIslandStormdrainAlternatingCogWheelElevator Elevator;

	float MoveUpDistance;
	float MovedDistance = 0.0;
	float CurrentSpeed = 0.0;
	float PreviousCogRotationPitch;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Elevator = Cast<AIslandStormdrainAlternatingCogWheelElevator>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FIslandStormdrainAlternatingCogWheelElevatorGoUpActivationParams& Params) const
	{
		if(Elevator.TimesMovedDown == 0)
			return false;

		if(Elevator.bIsMoving)
			return false;

		if(Time::GetGameTimeSince(Elevator.TimePanelLastShot) >= Elevator.TimeAfterShootingUntilElevatorMovesUp)
		{
			Params.MoveUpDistance = Elevator.MoveDownLength * Elevator.TimesMovedDown;
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(MovedDistance >= MoveUpDistance)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FIslandStormdrainAlternatingCogWheelElevatorGoUpActivationParams Params)
	{
		UIslandStormdrainAlternatingCogWheelElevatorEffectHandler::Trigger_OnStartMovingUp(Elevator);
		Elevator.MovingShakeComp.ActivateMovableCameraShake();
		MoveUpDistance = Params.MoveUpDistance;

		for(auto Player : Game::Players)
		{
			Elevator.TogglePanelForPlayer(Elevator.FirstPanel, Player, false);
			Elevator.TogglePanelForPlayer(Elevator.SecondPanel, Player, false);
		}

		MovedDistance = 0.0;
		CurrentSpeed = 0.0;

		Elevator.FirstPanel.EnablePanel();

		Elevator.bIsMoving = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		UIslandStormdrainAlternatingCogWheelElevatorEffectHandler::Trigger_OnReachedHighestPosition(Elevator);

		for(auto Player : Game::Players)
		{
			Elevator.TogglePanelForPlayer(Elevator.FirstPanel, Player, true);
			Elevator.TogglePanelForPlayer(Elevator.SecondPanel, Player, true);
		}

		Elevator.ElevatorRoot.WorldLocation = Elevator.ElevatorStartLocation; 
		Elevator.TimesMovedDown = 0;

		Elevator.StopElevator();

		Elevator.FixupCogRotationAtEndOfMove();

		Elevator.bIsMoving = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		CurrentSpeed = Math::FInterpTo(CurrentSpeed, Elevator.MoveUpMaxSpeed, DeltaTime, Elevator.MoveUpAcceleration);
		float MoveDelta = CurrentSpeed * DeltaTime;
		float MaxDelta = MoveUpDistance - MovedDistance;
		MoveDelta = Math::Min(MoveDelta, MaxDelta);
		Elevator.ElevatorRoot.AddLocalOffset(FVector(0, 0, MoveDelta));
		MovedDistance += MoveDelta;

		PreviousCogRotationPitch = Elevator.CogWheelRoot.RelativeRotation.Pitch;
		Elevator.RotateCog(MoveDelta);
		float CurrentPitch = Elevator.CogWheelRoot.RelativeRotation.Pitch;

		ForceFeedback::PlayWorldForceFeedbackForFrame(Elevator.MovingFF, Elevator.ElevatorRoot.WorldLocation, 9000, 1800);

		if(ActiveDuration > 0.0 && ((PreviousCogRotationPitch < 0.0 && CurrentPitch >= 0.0) || (PreviousCogRotationPitch >= 0.0 && CurrentPitch < 0.0)))
		{
			UIslandStormdrainAlternatingCogWheelElevatorEffectHandler::Trigger_OnPassed180DegreesOfRotationGoingUp(Elevator);
		}
	}
};