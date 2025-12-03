class USlopeSlideCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	
	default CapabilityTags.Add(DesertSlopeSlide::Tags::DesertSlopeSlide);
	
	default TickGroup = EHazeTickGroup::Input;
	default TickGroupOrder = 100;

	UPlayerMovementComponent MoveComp;
	UPlayerStepDashComponent DashComp;
	ESlideType SlideType = ESlideType::Freeform;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		DashComp = UPlayerStepDashComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!MoveComp.HasGroundContact())
			return false;

		if(IsGoingUpSlope())
			return false;

		if(IsInputGoingUpSlope())
			return false;

		if(MoveComp.GroundContact.ImpactNormal.GetAngleDegreesTo(FVector::UpVector) < DesertSlopeSlide::StartSlideAngle)
			return false;

		if (MoveComp.GroundContact.Actor != nullptr)
		{
			if (MoveComp.GroundContact.Actor.Class != ALandscape)
				return false;
		}

		if(DashComp.IsDashing())
			return false;

		return true;
	}
	
	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(IsGoingUpSlope())
			return true;

		if(IsInputGoingUpSlope())
			return true;

		if(!MoveComp.HasGroundContact())
			return true;

		if(MoveComp.GroundContact.ImpactNormal.GetAngleDegreesTo(FVector::UpVector) > DesertSlopeSlide::StopSlideAngle)
			return true;

		if(DashComp.IsDashing())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		FSlideParameters SlideParams;
		SlideParams.SlideType = SlideType;
		Player.ForcePlayerSlide(this, SlideParams);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.ClearForcePlayerSlide(this);
	}

	bool IsGoingUpSlope() const
	{
		const FVector SlopePlane = MoveComp.GroundContact.ImpactNormal;

		FVector SlopeDirection = SlopePlane.ProjectOnTo(FVector::UpVector).GetSafeNormal();
		SlopeDirection = SlopeDirection.VectorPlaneProject(SlopePlane).GetSafeNormal();
		SlopeDirection = -SlopeDirection;

		FVector MovementInput = MoveComp.MovementInput;
		MovementInput.Z = 0;

		const float Dot = (MoveComp.Velocity).DotProduct(SlopeDirection);
		return Dot < -DesertSlopeSlide::SlideVelocityThreshold;
	}

	bool IsInputGoingUpSlope() const
	{
		const FVector SlopePlane = MoveComp.GroundContact.ImpactNormal;

		FVector SlopeDirection = SlopePlane.ProjectOnTo(FVector::UpVector).GetSafeNormal();
		SlopeDirection = SlopeDirection.VectorPlaneProject(SlopePlane).GetSafeNormal();
		SlopeDirection = -SlopeDirection;

		const float Dot = (MoveComp.MovementInput * 500).DotProduct(SlopeDirection);
		return Dot < -DesertSlopeSlide::SlideVelocityThreshold;
	}

}