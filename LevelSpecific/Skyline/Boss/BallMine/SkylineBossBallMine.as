class ASkylineBossBallMine : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USphereComponent Collision;
	default Collision.SphereRadius = 200.0;
	default Collision.CollisionProfileName = n"BlockAllDynamic";
	default Collision.bGenerateOverlapEvents = false;

	UPROPERTY(DefaultComponent, Attach = Collision)
	USceneComponent Pivot;

	UPROPERTY(DefaultComponent)
	UGravityBikeFreeImpactResponseComponent ImpactResponseComp;

	UPROPERTY(DefaultComponent)
	UHazeMovementComponent MoveComp;

	USweepingMovementData Movement;

	FVector Gravity = FVector::UpVector * -3000.0;

	FVector AngularVelocity;

	float GroundDrag = 1.0;
	float AirDrag = 0.25;
	float AngularDrag = 1.0;

	float Restitution = 0.3;

	float Speed = 6000.0;

	TInstigated<AActor> CurrentTarget;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		{
			UMovementStandardSettings::SetWalkableSlopeAngle(this, 70.0, this, EHazeSettingsPriority::Defaults);
		}
	
		Movement = MoveComp.SetupSweepingMovementData();

		ImpactResponseComp.OnImpact.AddUFunction(this, n"HandleGravityBikeImpact");

		AddTarget(Game::Mio);
	}

	UFUNCTION()
	void AddTarget(AActor Target)
	{
		AActor NewTarget = Target;

		CurrentTarget.Apply(NewTarget, this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		FVector Velocity = MoveComp.Velocity;

		PrintToScreen("CurrentTarget: " + CurrentTarget.Get(), 0.0, FLinearColor::Red);
		PrintToScreen("Ground: " + MoveComp.IsOnAnyGround(), 0.0, FLinearColor::Red);

		FVector Force = FVector::ZeroVector;
		FQuat DesiredRotation = Velocity.ToOrientationQuat();

		if (!CurrentTarget.IsDefaultValue())
		{
			FVector ToTarget = CurrentTarget.Get().ActorLocation - ActorLocation;

			FVector LeanVector = Velocity.SafeNormal.CrossProduct(ToTarget.SafeNormal);

			float Lean = 45.0 * LeanVector.DotProduct(ActorUpVector);

			Pivot.RelativeRotation = FRotator(0.0, 0.0, Lean);

			float SpeedScale = 1.0;

			if (MoveComp.IsOnAnyGround())
			{
				ToTarget = ToTarget.VectorPlaneProject(MoveComp.CurrentGroundNormal);
				DesiredRotation = ToTarget.ToOrientationQuat();
			}
			else
				SpeedScale = 0.3;

			Force = ToTarget.SafeNormal * Math::Min(Speed, ToTarget.Size()) * SpeedScale;
		}

		float Drag = (MoveComp.IsOnAnyGround() ? GroundDrag : AirDrag);

		FVector Acceleration = Force
							 + Gravity
							 - Velocity * Drag;

		Velocity += Acceleration * DeltaSeconds;

		FQuat Rotation = FQuat::Slerp(ActorQuat, DesiredRotation, 6.0 * DeltaSeconds);

		Move(Velocity * DeltaSeconds, Rotation);

		FHitResult HitResult;
		if (GetImpact(HitResult) && MoveComp.WasInAir())
		{
			if (HitResult.Actor == CurrentTarget.Get())
			{
				auto GravityBikeFree = Cast<AGravityBikeFree>(HitResult.Actor);
				if (GravityBikeFree != nullptr)
					GravityBikeFree.GetDriver().DamagePlayerHealth(1.0);
			}

			if (MoveComp.WasInAir())
				Velocity = Math::GetReflectionVector(Velocity, HitResult.Normal) * Restitution;
		}

		FLinearColor Color = (MoveComp.IsOnAnyGround() ? FLinearColor::Green : FLinearColor::Red);

	//	Debug::DrawDebugSphere(ActorLocation, 410.0, 24, Color, 5.0, 0.0);
	//	Debug::DrawDebugLine(ActorLocation, ActorLocation + DesiredRotation.ForwardVector * 500.0, FLinearColor::Red, 50.0, 0.0);
	//	Debug::DrawDebugLine(ActorCenterLocation, ActorCenterLocation + DesiredRotation.ForwardVector * 500.0, FLinearColor::Red, 50.0, 0.0);
	}

	UFUNCTION()
	private void HandleGravityBikeImpact(AGravityBikeFree GravityBike, FGravityBikeFreeOnImpactData Data)
	{
		GravityBike.GetDriver().DamagePlayerHealth(1.0);
	}

	void Move(FVector DeltaMove, FQuat Rotation)
	{
		if (MoveComp.PrepareMove(Movement))
		{
			Movement.AddDelta(DeltaMove);
			Movement.SetRotation(Rotation);
			MoveComp.ApplyMove(Movement);
		}
	}

	bool GetImpact(FHitResult& OutHitResult)
	{
		if (MoveComp.HasGroundContact())
			OutHitResult = MoveComp.GroundContact.ConvertToHitResult();

		if (MoveComp.HasWallContact())
			OutHitResult = MoveComp.WallContact.ConvertToHitResult();

		if (MoveComp.HasCeilingContact())
			OutHitResult = MoveComp.CeilingContact.ConvertToHitResult();

		if (OutHitResult.bBlockingHit)
			return true;

		return false;		
	}
};