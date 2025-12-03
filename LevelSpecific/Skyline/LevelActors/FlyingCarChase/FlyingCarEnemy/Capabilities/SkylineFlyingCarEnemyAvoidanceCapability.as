class USkylineFlyingCarEnemyAvoidanceCapability : UHazeCapability
{
	default CapabilityTags.Add(n"FlyingCarEnemyAvoidance");
	default CapabilityTags.Add(n"FlyingCarEnemyMovement");

	UHazeMovementComponent MovementComponent;

	USkylineFlyingCarEnemyMovementData Movement;

	ASkylineFlyingCarEnemy FlyingCarEnemy;

	float AvoidanceRadius = 500.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MovementComponent = UHazeMovementComponent::Get(Owner);
		Movement = MovementComponent.SetupMovementData(USkylineFlyingCarEnemyMovementData);

		FlyingCarEnemy = Cast<ASkylineFlyingCarEnemy>(Owner);
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
		auto Trace = Trace::InitChannel(ECollisionChannel::ECC_Visibility);
		Trace.IgnoreActor(Owner);
		Trace.IgnoreActor(FlyingCarEnemy.FollowTarget);
		Trace.UseSphereShape(AvoidanceRadius);
		auto HitResult = Trace.QueryTraceSingle(Owner.ActorLocation, Owner.ActorLocation + Owner.ActorVelocity * 0.7 + FVector::ForwardVector * 1.0);

		FVector Avoidance;

		if (HitResult.bBlockingHit)
		{
			Avoidance = (Owner.ActorLocation - HitResult.ImpactPoint).VectorPlaneProject(Owner.ActorVelocity.GetSafeNormal());
			Avoidance += Owner.ActorUpVector;
		//	Debug::DrawDebugLine(Owner.ActorLocation, Owner.ActorLocation + Avoidance, FLinearColor::Red, 20.0, 0.0);
		//	Debug::DrawDebugPoint(HitResult.ImpactPoint, 100.0, FLinearColor::Yellow, 0.0);
		}

		float Alpha = 1.0 - (Avoidance.Size() / AvoidanceRadius);

		FlyingCarEnemy.Avoidance = Avoidance.GetSafeNormal() * Alpha;

	//	Debug::DrawDebugSphere(Owner.ActorLocation + Owner.ActorVelocity * 0.7, AvoidanceRadius, 24, FLinearColor::Red, 3.0, 0.0);
	}
}