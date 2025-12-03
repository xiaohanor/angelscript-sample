class ATraceTestUtilty : AActor
{
	UPROPERTY(DefaultComponent, RootComponent, ShowOnActor)
	UTraceTestUtiltyComponent TraceDirection;
}

class UTraceTestUtiltyComponent : UArrowComponent
{
	default bTickInEditor = true;

	UPROPERTY(EditAnywhere, Category = Settings)	
	ETraceTestUtilityShapes TraceShape = ETraceTestUtilityShapes::Line;

	UPROPERTY(EditAnywhere, Category = Settings)
	float TraceDistance = 1000.0;

	UPROPERTY(EditAnywhere, Category = Settings)
	FName CollisionProfile = n"PlayerCharacter";

	// UPROPERTY(EditAnywhere, Category = Settings)
	// bool bUseActorRotation = true;

	UPROPERTY(EditAnywhere, Category = Settings, meta = (EditCondition="TraceShape == ETraceTestUtilityShapes::Box", EditConditionHides))
	FVector BoxExtents = FVector(100.0, 100.0, 100.0);

	UPROPERTY(EditAnywhere, Category = Settings, meta = (EditCondition="TraceShape == ETraceTestUtilityShapes::Sphere", EditConditionHides))
	float SphereRadius = 32.0;

	UPROPERTY(EditAnywhere, Category = Settings, meta = (EditCondition="TraceShape == ETraceTestUtilityShapes::Capsule", EditConditionHides))
	float CapsuleRadius = 32.0;

	UPROPERTY(EditAnywhere, Category = Settings, meta = (EditCondition="TraceShape == ETraceTestUtilityShapes::Capsule", EditConditionHides))
	float CapsuleHalfHeight = 80.0;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{		
		FHitResult TraceHit;
		switch (TraceShape)
		{
		case ETraceTestUtilityShapes::Line:
			TraceHit = TraceLine();
		break;
		case ETraceTestUtilityShapes::Box:
			TraceHit = TraceBox();
		break;
		case ETraceTestUtilityShapes::Sphere:
			TraceHit = TraceSphere();
		break;
		case ETraceTestUtilityShapes::Capsule:
			TraceHit = TraceCapsule();
		break;
		}

		if (!TraceHit.bBlockingHit)
			return;

		FRotator Rotation = FRotator::MakeFromXZ(TraceHit.ImpactNormal, FVector::UpVector);
		Debug::DrawDebugCoordinateSystem(TraceHit.ImpactPoint, Rotation, 250.0);
	}

	FHitResult TraceLine()
	{
		FHazeTraceSettings TraceSettings = Trace::InitProfile(CollisionProfile);
		TraceSettings.UseLine();
		TraceSettings.DebugDrawOneFrame();

		FHitResult TraceHit = TraceSettings.QueryTraceSingle(WorldLocation, WorldLocation + ForwardVector * TraceDistance);

		if (!TraceHit.bBlockingHit)
			return FHitResult();

		return TraceHit;
	}

	FHitResult TraceBox()
	{
		FHazeTraceSettings TraceSettings = Trace::InitProfile(CollisionProfile);
		FRotator Rotation = Owner.ActorRotation;
		TraceSettings.UseBoxShape(BoxExtents, Rotation.Quaternion());
		TraceSettings.DebugDrawOneFrame();

		FHitResult TraceHit = TraceSettings.QueryTraceSingle(WorldLocation, WorldLocation + ForwardVector * TraceDistance);

		if (!TraceHit.bBlockingHit)
			return FHitResult();

		return TraceHit;
	}	

	FHitResult TraceSphere()
	{
		FHazeTraceSettings TraceSettings = Trace::InitProfile(CollisionProfile);
		TraceSettings.UseSphereShape(SphereRadius);
		TraceSettings.DebugDrawOneFrame();

		FHitResult TraceHit = TraceSettings.QueryTraceSingle(WorldLocation, WorldLocation + ForwardVector * TraceDistance);

		if (!TraceHit.bBlockingHit)
			return FHitResult();

		return TraceHit;
	}	

	FHitResult TraceCapsule()
	{
		FHazeTraceSettings TraceSettings = Trace::InitProfile(CollisionProfile);
		TraceSettings.UseCapsuleShape(CapsuleRadius, CapsuleHalfHeight);
		TraceSettings.DebugDrawOneFrame();

		FHitResult TraceHit = TraceSettings.QueryTraceSingle(WorldLocation, WorldLocation + ForwardVector * TraceDistance);

		if (!TraceHit.bBlockingHit)
			return FHitResult();

		return TraceHit;
	}


}

enum ETraceTestUtilityShapes
{
	Line,
	Box,
	Sphere,
	Capsule
}