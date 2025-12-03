struct FIslandStormdrainAlternatingCogWheelElevatorGoDownCapabilityActivationParams
{
	AIslandOverloadShootablePanel PanelActivated;
	FVector TargetLocation;
}

class UIslandStormdrainAlternatingCogWheelElevatorGoDownCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default TickGroup = EHazeTickGroup::Gameplay;

	AIslandStormdrainAlternatingCogWheelElevator Elevator;
	AHazePlayerCharacter PlayerWhoShotPanel;
	AIslandOverloadShootablePanel PanelActivated;

	FVector TargetLocation;

	float MovedDistance = 0.0;
	float CurrentSpeed = 0.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Elevator = Cast<AIslandStormdrainAlternatingCogWheelElevator>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FIslandStormdrainAlternatingCogWheelElevatorGoDownCapabilityActivationParams& Params) const
	{
		// At the bottom
		if(Elevator.TimesMovedDown >= Elevator.TimesToMoveDown)
			return false;

		if(Elevator.bIsMoving)
			return false;
			
		if(Elevator.FirstPanel.OverchargeComp.ChargeAlpha >= 1.0)
		{
			FVector MoveDownDelta = -Elevator.ElevatorRoot.UpVector * Elevator.MoveDownLength;
			FVector NewTargetLocation = Elevator.ElevatorStartLocation + MoveDownDelta * (Elevator.TimesMovedDown + 1);
			Params.TargetLocation = NewTargetLocation;
			Params.PanelActivated = Elevator.FirstPanel;
			return true;
		}

		if(Elevator.SecondPanel.OverchargeComp.ChargeAlpha >= 1.0)
		{
			FVector MoveDownDelta = -Elevator.ElevatorRoot.UpVector * Elevator.MoveDownLength;
			FVector NewTargetLocation = Elevator.ElevatorStartLocation + MoveDownDelta * (Elevator.TimesMovedDown + 1);
			Params.TargetLocation = NewTargetLocation;
			Params.PanelActivated = Elevator.SecondPanel;
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(MovedDistance <= -Elevator.MoveDownLength)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FIslandStormdrainAlternatingCogWheelElevatorGoDownCapabilityActivationParams Params)
	{
		UIslandStormdrainAlternatingCogWheelElevatorEffectHandler::Trigger_OnStartMovingDown(Elevator);
		Elevator.MovingShakeComp.ActivateMovableCameraShake();
		PanelActivated = Params.PanelActivated;
		if(PanelActivated.UsableByPlayer == EHazePlayer::Mio)
			PlayerWhoShotPanel = Game::Mio;
		else
			PlayerWhoShotPanel = Game::Zoe;

		Elevator.TogglePanelForPlayer(PanelActivated, PlayerWhoShotPanel, false);

		TargetLocation = Params.TargetLocation;
		CurrentSpeed = 0.0;
		MovedDistance = 0.0;

		Elevator.bIsMoving = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		UIslandStormdrainAlternatingCogWheelElevatorEffectHandler::Trigger_OnStopMovingDown(Elevator);
		Elevator.ElevatorRoot.WorldLocation = TargetLocation;
		Elevator.TimesMovedDown++;

		if(Elevator.TimesToMoveDown == Elevator.TimesMovedDown)
			UIslandStormdrainAlternatingCogWheelElevatorEffectHandler::Trigger_OnReachedLowestPosition(Elevator);

		Elevator.FixupCogRotationAtEndOfMove();

		PanelActivated.OverchargeComp.ResetChargeAlpha(this);

		Elevator.TogglePanelForPlayer(PanelActivated, PlayerWhoShotPanel, true);
		Elevator.StopElevator();
	
		Elevator.bIsMoving = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		CurrentSpeed = Math::FInterpTo(CurrentSpeed, -Elevator.MoveDownMaxSpeed, DeltaTime, Elevator.MoveDownAcceleration);
		float MoveDelta = CurrentSpeed * DeltaTime;
		float MinDelta = MovedDistance - Elevator.MoveDownLength;
		MoveDelta = Math::Max(MoveDelta, MinDelta);
		Elevator.ElevatorRoot.AddLocalOffset(FVector(0, 0, MoveDelta));
		MovedDistance += MoveDelta;
		Elevator.RotateCog(MoveDelta);

		ForceFeedback::PlayWorldForceFeedbackForFrame(Elevator.MovingFF, Elevator.ElevatorRoot.WorldLocation, 9000, 1800);

		if(PanelActivated.OverchargeComp.OptionalDisplay != nullptr)
		{
			float MoveAlpha = MovedDistance / -Elevator.MoveDownLength;
			PanelActivated.OverchargeComp.OptionalDisplay.Display.SetFillPercentage(MoveAlpha);
		}
	}
};