class UMoonMarketYarnBallAirRotationCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default DebugCategory = n"Movement";
	default NetworkMode = EHazeCapabilityNetworkMode::Local;

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 100;

	AMoonMarketYarnBall Ball;

	UHazeMovementComponent MoveComp;

	const float InAirAngularInterpSpeed = 1.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Ball = Cast<AMoonMarketYarnBall>(Owner);
		MoveComp = UHazeMovementComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(MoveComp.IsOnWalkableGround())
			return false;

		if(Math::IsNearlyZero(MoveComp.HorizontalVelocity.Size()))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(MoveComp.IsOnWalkableGround())
			return true;

		if(Math::IsNearlyZero(MoveComp.HorizontalVelocity.Size()))
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
		FVector TargetAngularVelocity = MoveComp.HorizontalVelocity.CrossProduct(FVector::UpVector);
		
		if(Math::IsNearlyZero(TargetAngularVelocity.Size()))
			return;

		Ball.AngularVelocity = Math::VInterpTo(Ball.AngularVelocity, TargetAngularVelocity * 0.2, DeltaTime, InAirAngularInterpSpeed);

		float RotationSpeed = (-Ball.AngularVelocity.Size() / Math::Max(0.01, Ball.Collision.SphereRadius));
		FVector RotationAxis = Ball.AngularVelocity.GetSafeNormal();
		FQuat DeltaRotation = FQuat(RotationAxis, RotationSpeed * DeltaTime);
		Ball.Mesh.AddWorldRotation(DeltaRotation);
	}
};