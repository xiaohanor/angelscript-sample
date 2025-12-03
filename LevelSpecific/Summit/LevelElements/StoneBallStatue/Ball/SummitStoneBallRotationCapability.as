class USummitStoneBallRotationCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default DebugCategory = n"Movement";

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 100;

	ASummitStoneBall Ball;

	UHazeMovementComponent MoveComp;

	const float OnGroundAngularInterpSpeed = 10.0;
	const float InAirAngularInterpSpeed = 1.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Ball = Cast<ASummitStoneBall>(Owner);

		MoveComp = UHazeMovementComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
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
			float Radius = Ball.SphereCollision.ScaledSphereRadius;
			
			if(MoveComp.IsOnWalkableGround())
				Ball.AngularVelocity = Math::VInterpTo(Ball.AngularVelocity, TargetAngularVelocity, DeltaTime, OnGroundAngularInterpSpeed);
			else
				Ball.AngularVelocity = Math::VInterpTo(Ball.AngularVelocity, TargetAngularVelocity * 0.2, DeltaTime, InAirAngularInterpSpeed);

			float RotationSpeed = (-Ball.AngularVelocity.Size() / Radius) * Ball.RotationMultiplier;
			FVector RotationAxis = Ball.AngularVelocity.GetSafeNormal();
			FQuat DeltaRotation = FQuat(RotationAxis, RotationSpeed * DeltaTime);
			Ball.MeshOffsetComp.AddWorldRotation(DeltaRotation);

			Ball.SyncedRotation.SetValue(Ball.MeshOffsetComp.WorldRotation);
		}
		else
		{
			Ball.MeshOffsetComp.WorldRotation = Ball.SyncedRotation.Value;
		}
	}
};