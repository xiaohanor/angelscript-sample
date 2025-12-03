class UBattlefieldHoverboardGroundImpactFloatinessCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(BattlefieldHoverboardCapabilityTags::Hoverboard);
	default DebugCategory = BattlefieldHoverboardDebugCategory::Hoverboard;  
	default TickGroup = EHazeTickGroup::BeforeMovement;

	UBattlefieldHoverboardComponent HoverboardComp;
	UBattlefieldHoverboardGrindingComponent GrindComp;

	UPlayerMovementComponent MoveComp;

	FHazeAcceleratedFloat AccOffset;

	const float OffsetDisappearStiffness = 80; 
	const float OffsetDisappearDamping = 0.3; 
	const float MaxOffset = 75.0;
	const FHazeRange OffsetImpulseSize = FHazeRange(800.0, 1500.0);
	const FHazeRange LandSpeedForImpulseSize = FHazeRange(500, 2000.0);

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		HoverboardComp = UBattlefieldHoverboardComponent::Get(Player);
		GrindComp = UBattlefieldHoverboardGrindingComponent::Get(Player);

		MoveComp = UPlayerMovementComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!HoverboardComp.IsOn())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!HoverboardComp.IsOn())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		AccOffset.SnapTo(Player.MeshOffsetComponent.RelativeLocation.DotProduct(FVector::UpVector));
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.MeshOffsetComponent.ResetOffsetWithLerp(this, 0.5);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(LandedOnGround())
			ApplyLandingImpulse();

		AccOffset.SpringTo(0.0, OffsetDisappearStiffness, OffsetDisappearDamping, DeltaTime);
		Player.MeshOffsetComponent.RelativeLocation = FVector::DownVector * Math::Min(AccOffset.Value, MaxOffset);
	}

	void ApplyLandingImpulse()
	{
		float SpeedAtImpact = MoveComp.PreviousVerticalVelocity.Size();
		float SpeedAlpha = Math::GetPercentageBetweenClamped(LandSpeedForImpulseSize.Min, LandSpeedForImpulseSize.Max, SpeedAtImpact);
		float ImpulseSize = OffsetImpulseSize.Lerp(SpeedAlpha);

		AccOffset.Velocity = ImpulseSize;
		AccOffset.Value += 1.0;
	}

	bool LandedOnGround() const
	{
		if(!MoveComp.IsOnAnyGround())
			return false;

		if(!MoveComp.WasInAir())
			return false;
		
		auto GroundImpact = MoveComp.GroundContact;
		auto GrindSplineComp = UBattlefieldHoverboardGrindSplineComponent::Get(GroundImpact.Actor);
		if(GrindSplineComp != nullptr)
			return false;

		return true;
	}
};