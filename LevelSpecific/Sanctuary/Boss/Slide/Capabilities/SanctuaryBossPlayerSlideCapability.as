class USanctuaryBossPlayerSlideCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default TickGroup = EHazeTickGroup::Gameplay;

	USanctuaryBossSlidePlayerComponent SlideComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SlideComp = USanctuaryBossSlidePlayerComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (SlideComp.IsSliding())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!SlideComp.IsSliding())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		UMovementFloatingSettings::SetFloatingDirection(Player, EFloatingMovementFloatingDirection::Explicit, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		UMovementFloatingSettings::ClearFloatingDirection(Player, this);
		UMovementFloatingSettings::ClearExplicitFloatingDirection(Player, this);

		//Player.ClearGravityDirectionOverride(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		auto FloatingDirection = GetFloatingDirection();
		UMovementFloatingSettings::SetExplicitFloatingDirection(Player, FloatingDirection, this);
	}

	FVector GetFloatingDirection() const
	{
		auto ReferenceSpline = SlideComp.GetFloatingDirectionReferenceSpline();
		if(IsValid(ReferenceSpline))
		{
			FTransform SplineTransform = ReferenceSpline.GetClosestSplineWorldTransformToWorldLocation(Player.ActorCenterLocation);
			FVector RelativeLocation = SplineTransform.InverseTransformPositionNoScale(Player.ActorCenterLocation);
			RelativeLocation.X = 0;
			FVector Location = SplineTransform.TransformPositionNoScale(RelativeLocation);
			FVector Direction = (SplineTransform.Location - Location);
			return Direction.GetSafeNormal(ResultIfZero = FVector::UpVector);
		}

		auto Spline = SlideComp.GetSpline();
		if(IsValid(Spline))
		{
			float ClosestDistance = SlideComp.GetSpline().GetClosestSplineDistanceToWorldLocation(Player.ActorLocation);
			FQuat ClosestSplineRot = SlideComp.GetSpline().GetWorldRotationAtSplineDistance(ClosestDistance);
			FVector GravityDirection = (-ClosestSplineRot.UpVector.RotateTowards(ClosestSplineRot.ForwardVector, 2.0));
			return -GravityDirection;
		}

		return Player.MovementWorldUp;
	}
};