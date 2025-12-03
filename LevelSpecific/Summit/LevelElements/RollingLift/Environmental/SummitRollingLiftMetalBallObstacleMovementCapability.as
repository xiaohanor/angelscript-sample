class USummitRollingLiftMetalBallObstacleMovementCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);

	default DebugCategory = n"Movement";

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 100;

	ASummitRollingLiftMetalBallObstacle Ball;

	UHazeMovementComponent MoveComp;
	USteppingMovementData Movement;

	const float KnockbackCooldown = 0.1;

	FSplinePosition CurrentSplinePos;

	float CurrentSpeed = 0.0;

	float TimeStampLastKnockedBack = 0.0;
	FVector LastGroundNormal;

	bool bHasReachedEnd = false;
	bool bHasBeenMelted = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Ball = Cast<ASummitRollingLiftMetalBallObstacle>(Owner);
		Ball.OnCollisionDisabled.AddUFunction(this, n"OnCollisionDisabled");
		Ball.OnCollisionEnabled.AddUFunction(this, n"OnCollisionEnabled");

		MoveComp = UHazeMovementComponent::Get(Ball);
		Movement = MoveComp.SetupSteppingMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		// if(bHasBeenMelted)
		// 	return false;

		if(bHasReachedEnd)
			return false;

		if(!Ball.bIsRolling)
			return false;
			
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if(bHasReachedEnd)
			return true;

		// if(bHasBeenMelted)
		// 	return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		CurrentSplinePos = Ball.SplineToFollow.Spline.GetClosestSplinePositionToWorldLocation(Ball.ActorLocation);
		CurrentSpeed = 0.0;

		bHasReachedEnd = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{

	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MoveComp.PrepareMove(Movement))
		{
			if (HasControl())
			{
				if(!bHasReachedEnd && !bHasBeenMelted)
					KnockbackPlayerInFront();

				CurrentSpeed = Math::FInterpTo(CurrentSpeed, Ball.BaseSpeed, DeltaTime, Ball.StartAcceleration);

				if(!bHasReachedEnd)
				{
					bHasReachedEnd = !CurrentSplinePos.Move(CurrentSpeed * DeltaTime);
					RotateBasedOnSpeed();
				}

				FVector DeltaToSplinePos = CurrentSplinePos.WorldLocation - Ball.ActorLocation;
				DeltaToSplinePos = DeltaToSplinePos.ConstrainToPlane(MoveComp.WorldUp);

				Movement.AddDelta(DeltaToSplinePos);

				Movement.AddOwnerVerticalVelocity();
				Movement.AddGravityAcceleration();
			}
			// Remote update
			else
			{
				Movement.ApplyCrumbSyncedGroundMovement();
			}

			MoveComp.ApplyMove(Movement);
		}
	}

	private void RotateBasedOnSpeed()
	{	
		FVector RotationAxis;
		RotationAxis = CurrentSplinePos.WorldRightVector;

		float Angle = -CurrentSpeed / (Ball.SphereCollision.SphereRadius * Ball.SphereCollision.WorldScale.X);
		
		FRotator AdditionalRotation = FRotator::MakeFromEuler(RotationAxis * Angle);
		Ball.MeshComp.AddWorldRotation(AdditionalRotation);
	}

	void KnockbackPlayerInFront()
	{
		if(Ball.ActorVelocity.IsNearlyZero())
			return;

		if(Time::GetGameTimeSince(TimeStampLastKnockedBack) < KnockbackCooldown)
			return;

		FHazeTraceSettings Trace;
		Trace.TraceWithObjectType(EObjectTypeQuery::PlayerCharacter);
		Trace.UseSphereShape(Ball.SphereCollision);
		Trace.IgnoreActor(Ball, true);
		FVector VelocityDir = Ball.ActorVelocity.GetSafeNormal();
		FVector Start = Ball.ActorLocation;
		FVector End = Start + (VelocityDir * 400.0);
		auto Hits = Trace.QueryTraceMulti(Start, End);

		TEMPORAL_LOG(Ball)
			.HitResults("Trace For Players", Hits, Start, End, Trace.Shape)
			.DirectionalArrow("Velocity Dir", Ball.ActorLocation, VelocityDir * 5000, 40, 160, FLinearColor::Red)
		;

		for(auto Hit : Hits)
		{
			auto LiftComp = USummitTeenDragonRollingLiftComponent::Get(Hit.Actor);
			if(LiftComp != nullptr
			&& LiftComp.bIsDriver)
			{
				FVector Impulse = -Hit.ImpactNormal * Ball.KnockbackImpulse;
				Impulse += FVector::UpVector * 500.0;
				auto Player = Cast<AHazePlayerCharacter>(Hit.Actor);
				Player.AddMovementImpulse(Impulse);
				TimeStampLastKnockedBack = Time::GameTimeSeconds;	
			}
		}
	}

	UFUNCTION()
	private void OnCollisionDisabled()
	{
		bHasBeenMelted = true;
		Ball.SphereCollision.OverrideSphereRadius(Ball.GemBoulderActor.CapsuleComp.CapsuleRadius / Ball.SphereCollision.WorldScale.X, this, EInstigatePriority::High);
	}

	UFUNCTION()
	private void OnCollisionEnabled()
	{
		bHasBeenMelted = false;
		Ball.SphereCollision.ClearSphereRadiusOverride(this);
	}
};