class UGravityBikeBladeAnimationCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);

	default TickGroup = EHazeTickGroup::LastMovement;

	UGravityBikeBladePlayerComponent BladeComp;
	UGravityBikeSplineDriverComponent DriverComp;
	AGravityBikeSpline GravityBike;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		BladeComp = UGravityBikeBladePlayerComponent::Get(Player);
		DriverComp = UGravityBikeSplineDriverComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(DriverComp.GravityBike == nullptr)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(DriverComp.GravityBike == nullptr)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		GravityBike = DriverComp.GravityBike;

		BladeComp.PreviousGravityDirection = GravityBike.GetGravityDir();
		BladeComp.NewGravityDirection = BladeComp.PreviousGravityDirection;
		
		BladeComp.AnimationData.PreviousGravityDirection = BladeComp.PreviousGravityDirection;
		BladeComp.AnimationData.NewGravityDirection = BladeComp.NewGravityDirection;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		GravityBike = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		BladeComp.AnimationData.bEquippedGravityBlade = IsGravityBladeEquipped();
		BladeComp.AnimationData.bThrowGravityBlade = BladeComp.State == EGravityBikeBladeState::Throwing;

		if(BladeComp.AnimationData.bThrowGravityBlade)
		{
			FVector TargetRelativeLocation = Player.ActorTransform.InverseTransformPositionNoScale(BladeComp.GetThrowTargetTransform().Location);
			TargetRelativeLocation = TargetRelativeLocation.VectorPlaneProject(FVector::ForwardVector);
			float AngleFromVertical = TargetRelativeLocation.GetAngleDegreesTo(FVector::UpVector);
			float SideSign = Math::Sign(TargetRelativeLocation.Y);
			AngleFromVertical *= SideSign;
			BladeComp.AnimationData.BladeThrowSide = Math::GetMappedRangeValueClamped(FVector2D(-45, 45), FVector2D(-1, 1), AngleFromVertical);
		}
		else
		{
			BladeComp.AnimationData.BladeThrowSide = 0;
		}

		BladeComp.AnimationData.bIsChangingGravity = BladeComp.IsGrappling();
		BladeComp.AnimationData.RotateDirection = BladeComp.RotateDirection;

		if(BladeComp.IsGrappling())
		{
			BladeComp.AnimationData.GravityChangeAlpha = BladeComp.GravityChangeAlpha;
			BladeComp.AnimationData.GravityChangeDuration = BladeComp.GravityChangeDuration;
			BladeComp.AnimationData.PreviousGravityDirection = BladeComp.PreviousGravityDirection;
			BladeComp.AnimationData.NewGravityDirection = BladeComp.NewGravityDirection;
		}
		else
		{
			BladeComp.AnimationData.GravityChangeAlpha = 0;
			BladeComp.AnimationData.GravityChangeDuration = 0;
		}
	}

	bool IsGravityBladeEquipped() const
	{
		if(BladeComp.HasThrowTarget())
			return true;

		switch(BladeComp.State)
		{
			case EGravityBikeBladeState::Throwing:
				return true;

			default:
				break;
		}

		return false;
	}
}