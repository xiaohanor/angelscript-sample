class ULightSeekerPlayerWalkingOnSeekerCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);

	default TickGroup = EHazeTickGroup::InfluenceMovement;
	default TickGroupOrder = 10;

	UPlayerMovementComponent MoveComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!HasControl())
			return false;
		
		if (!MoveComp.IsOnAnyGround())
			return false;

		ALightSeeker WalkingOnSeeker = Cast<ALightSeeker>(MoveComp.GetGroundContact().Actor);
		if (WalkingOnSeeker == nullptr)
			return false;

		return true;		
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!MoveComp.IsOnAnyGround())
			return true;

		ALightSeeker WalkingOnSeeker = Cast<ALightSeeker>(MoveComp.GetGroundContact().Actor);
		if (WalkingOnSeeker == nullptr)
			return true;

		return false;		
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		ALightSeeker WalkingOnSeeker = Cast<ALightSeeker>(MoveComp.GetGroundContact().Actor);
		UMovementStandardSettings::SetWalkableSlopeAngle(Player, WalkingOnSeeker.PlayerWalkableAngleOverride, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		UMovementStandardSettings::ClearWalkableSlopeAngle(Player, this);
	}

}