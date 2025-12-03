class USummitDarkCaveChainedBallRotationCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default DebugCategory = n"Movement";

	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 100;

	ASummitDarkCaveChainedBall Ball;

	UHazeMovementComponent MoveComp;

	const float OnGroundAngularInterpSpeed = 10.0;
	const float InAirAngularInterpSpeed = 1.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Ball = Cast<ASummitDarkCaveChainedBall>(Owner);

		MoveComp = UHazeMovementComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(Ball.bIsChained)
			return false;

		if (Ball.bLandedInGoal)
			return false;

		if(Ball.AttachedChains.Num() > 0)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Ball.bIsChained)
			return true;

		if (Ball.bLandedInGoal)
			return true;

		if(Ball.AttachedChains.Num() > 0)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(HasControl())
		{
			FVector TargetAngularVelocity = MoveComp.HorizontalVelocity.CrossProduct(FVector::UpVector);;
			float Radius = Ball.SphereComp.ScaledSphereRadius;
			
			if(MoveComp.IsOnWalkableGround() || MoveComp.HasWallContact())
				Ball.AngularVelocity = Math::VInterpTo(Ball.AngularVelocity, TargetAngularVelocity, DeltaTime, OnGroundAngularInterpSpeed);
			else
				Ball.AngularVelocity = Math::VInterpTo(Ball.AngularVelocity, TargetAngularVelocity * 0.2, DeltaTime, InAirAngularInterpSpeed);

			float RotationSpeed = -Ball.AngularVelocity.Size() / Radius;
			FVector RotationAxis = Ball.AngularVelocity.GetSafeNormal();
			FQuat DeltaRotation = FQuat(RotationAxis, RotationSpeed * DeltaTime);
			Ball.MeshComp.AddWorldRotation(DeltaRotation);
			Ball.SyncedBallRotationComp.SetValue(Ball.MeshComp.WorldRotation);
		}
		else
		{
			Ball.MeshComp.WorldRotation = Ball.SyncedBallRotationComp.Value;
		}
	}
};