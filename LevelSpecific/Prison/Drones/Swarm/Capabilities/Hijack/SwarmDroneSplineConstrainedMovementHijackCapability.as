class USwarmDroneSplineConstrainedMovementHijackCapability : UHazeCapability
{
	default TickGroup = EHazeTickGroup::InfluenceMovement;

	ASwarmDroneSimpleMovementHijackable SimpleMovementHijackableOwner;
	UHazeSplineComponent SplineComponent;

	float Velocity;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SimpleMovementHijackableOwner = Cast<ASwarmDroneSimpleMovementHijackable>(Owner);
		SplineComponent = Cast<UHazeSplineComponent>(SimpleMovementHijackableOwner.MovementSettings.SplineConstrainedSettings.SplineComponentReference.GetComponent(nullptr));
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (SimpleMovementHijackableOwner == nullptr)
			return false;

		if (SimpleMovementHijackableOwner.MovementSettings.HijackType != ESwarmDroneSimpleMovementHijackType::SplineConstrained)
			return false;

		if (SplineComponent == nullptr)
		{
			Print("OJ! ASwarmDroneSimpleMovementHijackable move spline must be specified on " + Owner.Name, 0.0);
			return false;
		}

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (HasControl())
		{
			float CurrentDistanceAtSpline = SplineComponent.GetClosestSplineDistanceToWorldLocation(Owner.ActorLocation);
			FVector UpVector = SplineComponent.GetWorldRotationAtSplineDistance(CurrentDistanceAtSpline).UpVector;

			FVector Input = SwarmDroneHijack::GetMovementInput(SimpleMovementHijackableOwner.HijackComponent.GetHijackPlayer(), GetAttributeVector2D(AttributeVectorNames::MovementRaw), UpVector);

			float DecelerationInterpSpeed = Math::Pow(1.0 - Input.Size(), 3.0);
			float Acceleration = Math::Lerp(SimpleMovementHijackableOwner.MovementSettings.Acceleration, SimpleMovementHijackableOwner.MovementSettings.Deceleration, DecelerationInterpSpeed);

			FVector SplineForward = SplineComponent.GetWorldForwardVectorAtSplineDistance(CurrentDistanceAtSpline);
			float TargetVelocity = Input.DotProduct(SplineForward) * SimpleMovementHijackableOwner.MovementSettings.MaxSpeed;
			Velocity = Math::FInterpTo(Velocity, TargetVelocity, DeltaTime, Acceleration * DeltaTime);

			float TargetDistanceAtSpline = Math::Clamp(CurrentDistanceAtSpline + Velocity * DeltaTime, 0.0, SplineComponent.GetSplineLength());

			FVector NextLocation = SplineComponent.GetWorldLocationAtSplineDistance(TargetDistanceAtSpline);

			Owner.SetActorLocation(NextLocation);
		}
		else
		{
			Owner.SetActorLocation(SimpleMovementHijackableOwner.CrumbSyncedPositionComponent.GetPosition().WorldLocation);
			Owner.SetActorRotation(SimpleMovementHijackableOwner.CrumbSyncedPositionComponent.GetPosition().WorldRotation);
		}
	}
}