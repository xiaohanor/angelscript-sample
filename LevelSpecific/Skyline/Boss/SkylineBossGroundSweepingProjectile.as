class ASkylineBossGroundSweepingProjectile : ASkylineBossProjectile
{
	UPROPERTY(DefaultComponent)
	UHazeMovementComponent MoveComp;

	UPROPERTY(DefaultComponent)
	UGravityBikeFreeImpactResponseComponent ImpactResponseComp;

//	USteppingMovementData Movement;
	USimpleMovementData Movement;

	FVector InitialDirection;

	UPROPERTY(EditDefaultsOnly)
	float ExpireTime = 3.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

	//	Debug::DrawDebugLine(ActorLocation, ActorLocation + ActorForwardVector * 5000.0, FLinearColor::Red, 60.0, 1.0);

		{
			UMovementStandardSettings::SetWalkableSlopeAngle(this, 90.0, this, EHazeSettingsPriority::Defaults);
		}

		{
			FMovementSettingsValue Value;
			Value.Type = EMovementSettingsValueType::Value;
			Value.Value = 100.0;
			UMovementSteppingSettings::SetStepDownInAirSize(this, Value, this);
			UMovementSteppingSettings::SetStepUpSize(this, Value, this);
			UMovementSteppingSettings::SetStepDownSize(this, Value, this);
		}

//		Movement = MoveComp.SetupSteppingMovementData();
		Movement = MoveComp.SetupSimpleMovementData();

		MoveComp.AddMovementIgnoresActors(this, ActorsToIgnore);

		ImpactResponseComp.OnImpact.AddUFunction(this, n"HandleGravityBikeImpact");

		InitialDirection = ActorForwardVector;
	}

	UFUNCTION()
	private void HandleGravityBikeImpact(AGravityBikeFree GravityBike, FGravityBikeFreeOnImpactData Data)
	{
		GravityBike.GetDriver().DamagePlayerHealth(1.0);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		FVector LocationBeforeMove = ActorLocation;

		Velocity = InitialDirection * 6000.0
				 - FVector::UpVector * 5000.0;

		Move(Velocity * DeltaSeconds);
	
		if (MoveComp.HasAnyValidBlockingImpacts())
		{
			for (auto Impact : MoveComp.AllImpacts)
			{
				auto GravityBikeFree = Cast<AGravityBikeFree>(Impact.Actor);
				if (GravityBikeFree != nullptr)
				{
					GravityBikeFree.GetDriver().DamagePlayerHealth(0.5);
					break;
				}				
			}
		}

		if (MoveComp.HasImpactedWall())
		{
			HandleImpact(MoveComp.AllImpacts[0].ConvertToHitResult());
		}


		FVector FacingDirection = ActorLocation - LocationBeforeMove;
		SetActorRotation(FacingDirection.ToOrientationQuat());
	
		if (GameTimeSinceCreation > ExpireTime)
			DestroyActor();
	}

	void Move(FVector DeltaMove) override
	{
		if (MoveComp.PrepareMove(Movement))
		{
//			Movement.AddDelta(DeltaMove);
			Movement.AddDeltaFromMoveToPositionWithCustomHorizontalAndVerticalVelocity(ActorLocation + DeltaMove, Velocity.VectorPlaneProject(FVector::UpVector), FVector::ZeroVector);
		//	Movement.SetRotation(ActorForwardVector.ToOrientationRotator());
		//	Movement.SetRotation(FQuat::MakeFromZX(MoveComp.CurrentGroundNormal, InitialDirection.VectorPlaneProject(MoveComp.CurrentGroundNormal)));
			MoveComp.ApplyMove(Movement);
		}
	}
};