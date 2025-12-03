struct FIslandStormdrainAlternatingCogWheelElevatorTriedGoingDownAtBottomActivationParams
{
	AIslandOverloadShootablePanel PanelActivated;
}

class UIslandStormdrainAlternatingCogWheelElevatorTriedGoingDownAtBottomCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default TickGroup = EHazeTickGroup::Gameplay;

	AIslandStormdrainAlternatingCogWheelElevator Elevator;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Elevator = Cast<AIslandStormdrainAlternatingCogWheelElevator>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FIslandStormdrainAlternatingCogWheelElevatorTriedGoingDownAtBottomActivationParams& Params) const
	{
		if(Elevator.TimesMovedDown < Elevator.TimesToMoveDown)
			return false;

		if(Elevator.FirstPanel.OverchargeComp.ChargeAlpha >= 1.0)
		{
			Params.PanelActivated = Elevator.FirstPanel;
			return true;
		}

		if(Elevator.SecondPanel.OverchargeComp.ChargeAlpha >= 1.0)
		{
			Params.PanelActivated = Elevator.SecondPanel;
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FIslandStormdrainAlternatingCogWheelElevatorTriedGoingDownAtBottomActivationParams Params)
	{
		Elevator.OnTriedGoingPastBottom.Broadcast();
		Params.PanelActivated.OverchargeComp.ResetChargeAlpha(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}
};