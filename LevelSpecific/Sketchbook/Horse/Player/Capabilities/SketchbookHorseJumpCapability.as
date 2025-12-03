class USketchbookHorseJumpCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 90;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	USketchbookHorsePlayerComponent PlayerComp;
	UPlayerMovementComponent MoveComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PlayerComp = USketchbookHorsePlayerComponent::Get(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!WasActionStarted(ActionNames::MovementJump))
			return false;

		if(MoveComp.IsInAir())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!MoveComp.IsInAir())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.AddMovementImpulse(FVector::UpVector * 1000);

		PlayerComp.Horse.Mesh.SetAnimTrigger(n"Jump");
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}
};