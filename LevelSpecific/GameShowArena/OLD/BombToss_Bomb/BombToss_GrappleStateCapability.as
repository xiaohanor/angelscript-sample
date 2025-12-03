class UBombTossGrappleStateCapability : UHazePlayerCapability
{
	UBombTossPlayerComponent BombTossPlayerComponent;
	UHazeMovementComponent MovementComponent;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		BombTossPlayerComponent = UBombTossPlayerComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(BombTossPlayerComponent.CurrentGrapplingBombToss == nullptr)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(BombTossPlayerComponent.CurrentGrapplingBombToss == nullptr)
			return true;

		if(!BombTossPlayerComponent.CurrentGrapplingBombToss.bIsThrown)
			return true;

		if(BombTossPlayerComponent.CurrentGrapplingBombToss.Velocity.IsNearlyZero())
			return true;

		if(BombTossPlayerComponent.CurrentGrapplingBombToss.MovementComponent.HasGroundContact())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		BombTossPlayerComponent.CurrentGrapplingBombToss = nullptr;
	}
}