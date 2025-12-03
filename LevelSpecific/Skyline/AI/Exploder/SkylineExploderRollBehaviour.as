class USkylineExploderRollCapability : UHazeCapability
{
	USkylineExploderRollComponent RollComp;
	UBasicAICharacterMovementComponent MoveComp;
	
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		RollComp = USkylineExploderRollComponent::Get(Owner);
		MoveComp = UBasicAICharacterMovementComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!MoveComp.IsOnAnyGround())
			return false;
		if(MoveComp.Velocity.IsNearlyZero(10.0))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!MoveComp.IsOnAnyGround())
			return true;
		if(MoveComp.Velocity.IsNearlyZero(10.0))
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{		
		RollComp.MoveRotation(MoveComp.Velocity.Size() * 0.02);
	}
}