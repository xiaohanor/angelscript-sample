class UMoonMarketBouncyBallMovementCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default TickGroup = EHazeTickGroup::Movement;

	AMoonMarketBouncyBall Ball;

	UHazeMovementComponent MoveComp;
	UMoonMarketBouncyBallMovementData MoveData;

	FVector AngularVelocity;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Ball = Cast<AMoonMarketBouncyBall>(Owner);
		MoveComp = UHazeMovementComponent::Get(Owner);
		MoveData = MoveComp.SetupMovementData(UMoonMarketBouncyBallMovementData);
		MoveData.Radius = Ball.Sphere.ScaledSphereRadius;
		MoveData.Ball = Ball;
		MoveComp.bResolveMovementLocally.Apply(true, this);
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
		if(MoveComp.PrepareMove(MoveData))
		{
			const float HorizontalSpeedGroundDeceleration = 1;
			FVector HorizontalVelocity = MoveComp.HorizontalVelocity;
			FVector VerticalVelocity = MoveComp.VerticalVelocity;

			if(MoveComp.HasGroundContact())
				HorizontalVelocity = Math::VInterpTo(HorizontalVelocity, FVector::ZeroVector, DeltaTime, HorizontalSpeedGroundDeceleration);

			MoveData.AddVelocity(HorizontalVelocity + VerticalVelocity);
			MoveData.AddGravityAcceleration();
			MoveData.AddPendingImpulses();
			HandleRotation(DeltaTime);

			MoveComp.ApplyMove(MoveData);
		}
	}

	void HandleRotation(float DeltaTime)
	{
		float RotationMultiplier = 1;
		float BounceInterpSpeed = 20;
		float InAirInterpSpeed = 3;

		FVector TargetAngularVelocity = MoveComp.HorizontalVelocity.CrossProduct(FVector::UpVector);
		float Radius = Ball.Sphere.SphereRadius;
		
		if(MoveComp.HasAnyValidBlockingContacts())
			AngularVelocity = Math::VInterpTo(AngularVelocity, TargetAngularVelocity, DeltaTime, BounceInterpSpeed);
		else
			AngularVelocity = Math::VInterpTo(AngularVelocity, TargetAngularVelocity * 0.2, DeltaTime, InAirInterpSpeed);

		float RotationSpeed = (-AngularVelocity.Size() / Math::Max(0.01, Radius)) * RotationMultiplier;
		FVector RotationAxis = AngularVelocity.GetSafeNormal();
		FQuat DeltaRotation = FQuat(RotationAxis, RotationSpeed * DeltaTime);
		Ball.Mesh.AddWorldRotation(DeltaRotation);
	}
};