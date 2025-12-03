class USketchbookGoatJumpCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	
	default CapabilityTags.Add(Sketchbook::Goat::Tags::SketchbookGoat);

	default TickGroup = EHazeTickGroup::ActionMovement;

	ASketchbookGoat Goat;
	USketchbookGoatSplineMovementComponent SplineComp;

	UHazeMovementComponent MoveComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Goat = Cast<ASketchbookGoat>(Owner);
		SplineComp = USketchbookGoatSplineMovementComponent::Get(Goat);
		
		MoveComp = UHazeMovementComponent::Get(Goat);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(SplineComp.IsInAir())
			return false;

		// Temp because jumping in the loop sucks
		if(!SplineComp.GetCurrentSplineActor().bAllowJumping)
			return false;

		if(Goat.JumpZone != nullptr)
		{
			if(Goat.RootOffsetComp.ForwardVector.DotProduct(Goat.JumpZone.ActorForwardVector) > 0)
				return false;
		}

		if(!IsActioning(ActionNames::MovementJump))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!SplineComp.IsInAir())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		// Based on calculate maximum height formula: h=v²/(2g), rearranged to solve for upwards speed based on max height and gravity: v=sqrt(h*2g)
		float Impulse = Math::Sqrt(2.0 * MoveComp.GravityForce * Sketchbook::Goat::JumpHeight);
		Impulse -= MoveComp.VerticalSpeed;

		FVector Velocity = Goat.ActorHorizontalVelocity;
		Velocity += Goat.ActorUpVector * Sketchbook::Goat::JumpSpeed;
		Goat.SetActorVelocity(Velocity);
		SplineComp.bCanExitAir = false;

		if(Impulse > 0)
			Goat.AddMovementImpulseToReachHeight(Impulse);

		Goat.SetAnimTrigger(n"Jump");
		Goat.MountedPlayer.PlayForceFeedback(Goat.JumpForceFeedback,false,false,this,0.2);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if(Goat.MountedPlayer != nullptr)
			Goat.MountedPlayer.PlayForceFeedback(Goat.JumpForceFeedback,false,false,this,1);
	}
};