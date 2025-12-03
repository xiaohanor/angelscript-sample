struct FIslandSidescrollerAlternatingCogWheelElevatorMoveCapabilityActivationParams
{
	bool bMovingDown = false;
	FVector TargetLocation;
}

class UIslandStormdrainAlternatingCogWheelElevatorMoveCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default TickGroup = EHazeTickGroup::Gameplay;

	AIslandSidescrollerAlternatingCogWheelElevator Elevator;
	AHazePlayerCharacter PlayerWhoShotPanel;

	FVector TargetLocation;

	bool bIsMovingDown = false;

	float MovedDistance = 0.0;
	float CurrentSpeed = 0.0;

	AHazePlayerCharacter CurrentControlSide;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Elevator = Cast<AIslandSidescrollerAlternatingCogWheelElevator>(Owner);
		Elevator.SetActorControlSide(Game::Mio);
		CurrentControlSide = Game::Mio;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FIslandSidescrollerAlternatingCogWheelElevatorMoveCapabilityActivationParams& Params) const
	{
		if(Elevator.LeftGoDownPanel.OverchargeComp.ChargeAlpha >= 1.0
		|| Elevator.RightGoDownPanel.OverchargeComp.ChargeAlpha >= 1.0)
		{
			// At the bottom
			if(Elevator.TimesMovedDown >= Elevator.TimesToMoveDown)
				return false;

			FVector MoveDownDelta = -Elevator.ElevatorRoot.UpVector * Elevator.MoveLength;
			FVector NewTargetLocation = Elevator.ElevatorStartLocation + MoveDownDelta * (Elevator.TimesMovedDown + 1);
			Params.TargetLocation = NewTargetLocation;
			Params.bMovingDown = true;
			return true;
		}

		if(Elevator.LeftGoUpPanel.OverchargeComp.ChargeAlpha >= 1.0
		|| Elevator.RightGoUpPanel.OverchargeComp.ChargeAlpha >= 1.0)
		{
			// At the top
			if(Elevator.TimesMovedDown <= -Elevator.TimesToMoveUp)
				return false;

			FVector MoveDownDelta = -Elevator.ElevatorRoot.UpVector * Elevator.MoveLength;
			FVector NewTargetLocation = Elevator.ElevatorStartLocation + MoveDownDelta * (Elevator.TimesMovedDown - 1);
			Params.TargetLocation = NewTargetLocation;
			Params.bMovingDown = false;
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(MovedDistance >= Elevator.MoveLength)
			return true;

		// TODO (FL): Seems to overshoot if rotation speed is too high?

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FIslandSidescrollerAlternatingCogWheelElevatorMoveCapabilityActivationParams Params)
	{
		Elevator.TogglePanels(false);

		TargetLocation = Params.TargetLocation;
		bIsMovingDown = Params.bMovingDown;
		CurrentSpeed = 0.0;
		MovedDistance = 0.0;

		Elevator.bIsMoving = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Elevator.ElevatorRoot.WorldLocation = TargetLocation;
		if(bIsMovingDown)
			Elevator.TimesMovedDown++;
		else
			Elevator.TimesMovedDown--;
		Elevator.FixupCogRotationAtEndOfMove();

		Elevator.TogglePanels(true);
		Elevator.TogglePanelsBasedOnFacing();

		Elevator.StopElevator();
	
		Elevator.bIsMoving = false;

		Elevator.SetActorControlSide(CurrentControlSide.OtherPlayer);
		CurrentControlSide = CurrentControlSide.OtherPlayer;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		CurrentSpeed = Math::FInterpTo(CurrentSpeed, Elevator.MoveMaxSpeed, DeltaTime, Elevator.MoveAcceleration);
		float MoveDeltaLength = CurrentSpeed * DeltaTime;
		FVector MoveDir = bIsMovingDown ? FVector::DownVector : FVector::UpVector;
		Elevator.ElevatorRoot.AddLocalOffset(MoveDir * MoveDeltaLength);
		MovedDistance += MoveDeltaLength;
		Elevator.RotateCog(DeltaTime, -CurrentSpeed);

		float MoveAlpha = MovedDistance / -Elevator.MoveLength;
		// TODO (FL): Set moving panels charge to alpha
	}
};