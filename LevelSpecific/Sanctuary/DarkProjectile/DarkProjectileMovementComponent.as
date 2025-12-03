class UDarkProjectileMovementComponent : UActorComponent
{
	default PrimaryComponentTick.bStartWithTickEnabled = false;

	UPROPERTY(Category = "Movement")
	ETraceTypeQuery TraceTypeQuery = ETraceTypeQuery::WeaponTracePlayer;

	UPROPERTY(Category = "Movement")
	FVector Velocity;
	UPROPERTY(Category = "Movement")
	float Drag;
	UPROPERTY(Category = "Movement")
	bool bConstrainVelocity;
	UPROPERTY(Category = "Movement", Meta = (EditCondition = "bConstrainVelocity", EditConditionHides))
	float MaxVelocity;

	UPROPERTY(Category = "Movement")
	bool bUseGravity;
	UPROPERTY(Category = "Movement", Meta = (EditCondition = "bUseGravity", EditConditionHides))
	FVector Gravity = -FVector::UpVector * 980.0;

	UPROPERTY(NotVisible, Transient, Category = "Movement")
	FDarkProjectileTargetData HomingTarget;
	UPROPERTY(Category = "Movement")
	float HomingNearDistance = 0.0;
	UPROPERTY(Category = "Movement")
	float HomingFraction = 1.0;

	UPROPERTY(Category = "Movement", AdvancedDisplay)
	FVector AdjustmentVelocity;
	UPROPERTY(Category = "Movement", AdvancedDisplay)
	float AdjustmentPower;
	UPROPERTY(Category = "Movement", AdvancedDisplay)
	float AdjustmentDrag;

	private FVector InitialLocation;
	private FVector InitialDirection;

	UFUNCTION(BlueprintCallable, Category = "Movement")
	void Initialize(const FVector& InVelocity,
		const FDarkProjectileTargetData& InHomingTarget)
	{
		Velocity = InVelocity;
		HomingTarget = InHomingTarget;

		InitialLocation = Owner.ActorLocation;
		InitialDirection = Velocity.GetSafeNormal();
	}

	UFUNCTION(BlueprintCallable, Category = "Movement")
	FVector CalculateAcceleration(float DeltaTime,
		const FVector& InVelocity)
	{
		FVector Acceleration;
		if (bUseGravity)
			Acceleration += Gravity;
		Acceleration -= InVelocity * Drag;
		return Acceleration;
	}

	UFUNCTION(BlueprintCallable, Category = "Movement")
	FVector CalculateVelocity(float DeltaTime, 
		const FVector& InVelocity)
	{
		FVector NewVelocity = InVelocity + (CalculateAcceleration(DeltaTime, InVelocity) * DeltaTime);
		if (bConstrainVelocity && NewVelocity.SizeSquared() > Math::Square(MaxVelocity))
			NewVelocity = NewVelocity.GetSafeNormal() * MaxVelocity;

		if (HomingTarget.IsValid())
		{
			const FVector ToTarget = (HomingTarget.WorldLocation - Owner.ActorLocation);
			if (ToTarget.SizeSquared() > Math::Square(HomingNearDistance))
				NewVelocity = ToTarget.GetSafeNormal() * NewVelocity.Size();
		}

		return NewVelocity;
	}

	UFUNCTION(BlueprintCallable, Category = "Movement")
	FVector CalculateDeltaMovement(float DeltaTime,
		const FVector& OldVelocity,
		const FVector& NewVelocity)
	{
		return (OldVelocity * DeltaTime) + (NewVelocity - OldVelocity) * DeltaTime * .5;
	}

	UFUNCTION(BlueprintCallable, Category = "Movement")
	bool SweepDeltaMovement(FVector&inout DeltaMovement,
		float CollisionRadius,
		FHitResult&out HitResult)
	{
		const FVector StartLocation = Owner.ActorLocation;
		const FVector EndLocation = StartLocation + DeltaMovement;

		auto Trace = Trace::InitChannel(TraceTypeQuery);
		Trace.IgnoreActor(Owner);
		Trace.IgnoreActor(Game::Mio);
		Trace.IgnoreActor(Game::Zoe);
		Trace.UseSphereShape(CollisionRadius);

		HitResult = Trace.QueryTraceSingle(StartLocation, EndLocation);

		if (HitResult.bBlockingHit)
		{
			DeltaMovement *= HitResult.Time;
			return true;
		}

		return false;
	}
	
	UFUNCTION(BlueprintCallable, Category = "Movement")
	bool PerformMove(float DeltaTime, float CollisionRadius, FHitResult&out HitResult)
	{
		// Calculates new velocity by adding acceleration/drag/homing
		const FVector NewVelocity = CalculateVelocity(DeltaTime, Velocity);

		// Calculates delta movement by verlet integration
		FVector DeltaMovement = CalculateDeltaMovement(DeltaTime, Velocity, NewVelocity);

		// Update velocity after delta has been calculated
		Velocity = NewVelocity;

		// TODO: Prototype stuff to clean up
		const FVector AdjustmentAcceleration = ((InitialLocation - Owner.ActorLocation).VectorPlaneProject(DeltaMovement.GetSafeNormal()) * AdjustmentPower) - AdjustmentVelocity * AdjustmentDrag;
		const FVector NewAdjustmentVelocity = AdjustmentVelocity + (AdjustmentAcceleration * DeltaTime);
		FVector AdjustmentDelta = CalculateDeltaMovement(DeltaTime, AdjustmentVelocity, NewAdjustmentVelocity);
		AdjustmentVelocity = NewAdjustmentVelocity;
		DeltaMovement += AdjustmentDelta;

		if (!DeltaMovement.IsNearlyZero())
		{
			SweepDeltaMovement(DeltaMovement, CollisionRadius, HitResult);

			Owner.SetActorLocationAndRotation(
				Owner.ActorLocation + DeltaMovement,
				FRotator::MakeFromX(DeltaMovement.GetSafeNormal())
			);

			if (HomingTarget.IsValid())
			{
				const FVector ToTarget = (HomingTarget.WorldLocation - Owner.ActorLocation);
				const float TargetDistSqr = Math::Square(ToTarget.Size() - CollisionRadius);
				const float DropDistSqr = Math::Square(HomingNearDistance);

				if (TargetDistSqr <= DropDistSqr ||
					DeltaMovement.GetSafeNormal().DotProduct(ToTarget.GetSafeNormal()) < 0.0)
					HomingTarget = FDarkProjectileTargetData();
			}
		}

		return HitResult.bBlockingHit;
	}
}