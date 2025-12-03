event void FBombTossStartHoldingEvent(AHazePlayerCharacter Player);

class ABombToss_Bomb : AHazeActor
{
	access ReadOnly = private, *(readonly);

	UPROPERTY(DefaultComponent, RootComponent)
	USphereComponent Collision;
	default Collision.SetCollisionProfileName(n"BlockAllDynamic");
	default Collision.SetCollisionResponseToChannel(ECollisionChannel::EnemyCharacter, ECollisionResponse::ECR_Block);

	UPROPERTY(DefaultComponent, Attach = Collision)
	UStaticMeshComponent Mesh;
	default Mesh.CollisionProfileName = n"NoCollision";

	UPROPERTY(DefaultComponent)
	UHazeMovementComponent MovementComponent;
	USweepingMovementData Movement;

	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent RequestComponent;

	UPROPERTY(DefaultComponent, BlueprintHidden, NotEditable)
	UHazeListedActorComponent ListedActorComp;
	default ListedActorComp.bDelistWhileActorDisabled = false;

	UPROPERTY(DefaultComponent, Attach = Collision)
	UBombTossGrapplePointComponent GrappleToComp;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bStartDisabled = true;

	UPROPERTY()
	FBombTossStartHoldingEvent OnStartHolding;

	UPROPERTY(EditAnywhere)
	float GrappleSignificantVelocityThreshold = 1000.0;

	UPROPERTY(EditAnywhere)
	float GrappleToMeImpulse = 5000.0;

	UPROPERTY(EditAnywhere)
	float GrappleTowardsEachOtherPlayerImpulse = 2000.0;

	UPROPERTY(EditAnywhere)
	float GrappleTowardsEachOtherBallImpulse = 2000.0;

	UPROPERTY(EditAnywhere)
	float CooldownToCatchAfterThrowing = 0.1;

	UPROPERTY(EditAnywhere)
	float CooldownToThrowAfterCatching = 0.1;

	UPROPERTY(EditAnywhere)
	bool bGrappleTowardsEachOtherRequiresAirborne = true;

	UPROPERTY()
	float ExplodeTimerDuration = 8;

	FVector Velocity;
	FVector AngularVelocity;

	const float HomingDistance = 500;
	const float Drag = 1.0;
	const float Restitution = 0.6;
	const float CatchSphereRadius = 750;

	const float Gravity = 850.0;

	access:ReadOnly bool bIsThrown = true;
	access:ReadOnly float TimeOfLastChangeToIsThrown = -100.0;

	bool bShouldLaunch = false;
	FVector PendingLaunchVelocity;

	AActor Thrower;

	USceneComponent Target;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		// Set up Resolver Settings
		UMovementResolverSettings::SetMaxRedirectIterations(this, 3, this, EHazeSettingsPriority::Defaults);
		UMovementResolverSettings::SetMaxDepenetrationIterations(this, 2, this, EHazeSettingsPriority::Defaults);

		// Set up Standard Settings
		UMovementStandardSettings::SetWalkableSlopeAngle(this, 0.0, this, EHazeSettingsPriority::Defaults);

		Movement = MovementComponent.SetupSweepingMovementData();
		MovementComponent.AddMovementIgnoresActor(Game::Mio, Game::Mio);
		MovementComponent.AddMovementIgnoresActor(Game::Zoe, Game::Zoe);

		this.JoinTeam(n"BombTossTeam");

		for (auto Player : Game::Players)
		{
			auto BombTossPlayerComponent = UBombTossPlayerComponent::Get(Player);
			BombTossPlayerComponent.BombTossBombs.Add(this);
		}
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		for (auto Player : Game::Players)
		{
			auto BombTossPlayerComponent = UBombTossPlayerComponent::Get(Player);
			BombTossPlayerComponent.BombTossBombs.Remove(this);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (!bIsThrown)
			return;

		auto HitResults = GetImpacts();

		if (HitResults.Num() > 0 && HitResults[0].bBlockingHit)
		{
			// Check for response component
			auto BombTossResponseComponent = UBombTossResponseComponent::Get(HitResults[0].Actor);
			if (BombTossResponseComponent != nullptr)
				BombTossResponseComponent.TryApplyImpact(HitResults[0].Component, HitResults[0].Location, HitResults[0].Normal);

			ActorVelocity = Math::GetReflectionVector(MovementComponent.PreviousVelocity, HitResults[0].Normal) * Restitution;

			AngularVelocity += ActorTransform.InverseTransformVectorNoScale(HitResults[0].ImpactNormal.CrossProduct(MovementComponent.PreviousVelocity) * 0.01);

			if (ActorVelocity.Size() > 300.0)
				BP_Impact(HitResults[0].Location, HitResults[0].Normal);

			MovementComponent.RemoveMovementIgnoresActor(Thrower);
			Thrower = nullptr;
		}

		if (MovementComponent.PrepareMove(Movement))
		{
			AngularVelocity -= AngularVelocity * Drag * DeltaSeconds;
			Velocity = MovementComponent.Velocity;
			float Force = Velocity.Size();

			if (Thrower != nullptr)
			{
				AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Thrower).OtherPlayer;
				float Dist = GetDistanceTo(Player);

				if (Dist < HomingDistance)
				{
					FVector Dir = FVector(Player.ActorLocation - ActorLocation);
					Dir.Normalize();

					Velocity = Dir * Force;
				}
			}

			if (bShouldLaunch)
			{
				Velocity = PendingLaunchVelocity;
				bShouldLaunch = false;
			}

			FVector Acceleration = -MovementComponent.WorldUp * Gravity;

			Movement.AddVelocity(Velocity);
			Movement.AddAcceleration(Acceleration);
			Movement.BlockGroundTracingForThisFrame();
			Movement.SetRotation(GetMovementRotation(DeltaSeconds));

			MovementComponent.ApplyMove(Movement);
		}
	}

	void Launch(FVector LaunchVelocity)
	{
		DetachFromActor();
		SetIsThrown(true);
		AngularVelocity = ActorUpVector * 20.0;
		//		ActorVelocity = LaunchVelocity;
		PendingLaunchVelocity = LaunchVelocity;
		bShouldLaunch = true;
	}

	void SetIsThrown(bool bNewState)
	{
		if (bIsThrown == bNewState)
			return;

		bIsThrown = bNewState;
		TimeOfLastChangeToIsThrown = Time::GetGameTimeSeconds();

		if (bIsThrown)
		{
			GrappleToComp.bIsAutoAimEnabled = true;
			BP_Throw();
		}
		else
			GrappleToComp.bIsAutoAimEnabled = false;
		BP_Grapple();
	}

	FQuat GetMovementRotation(float DeltaSeconds)
	{
		return ActorQuat * FQuat(AngularVelocity.GetSafeNormal(), AngularVelocity.Size() * DeltaSeconds);
	}

	TArray<FMovementHitResult> GetImpacts()
	{
		TArray<FMovementHitResult> HitResults;

		if (MovementComponent.HasGroundContact())
			HitResults.Add(MovementComponent.GroundContact);

		if (MovementComponent.HasWallContact())
			HitResults.Add(MovementComponent.WallContact);

		if (MovementComponent.HasCeilingContact())
			HitResults.Add(MovementComponent.CeilingContact);

		return HitResults;
	}

	UFUNCTION(BlueprintEvent)
	void BP_Impact(FVector Location, FVector Normal)
	{
	}

	UFUNCTION(BlueprintEvent)
	void BP_Throw()
	{
	}

	UFUNCTION(BlueprintEvent)
	void BP_BombCaught()
	{
	}

	UFUNCTION(BlueprintEvent)
	void BP_Grapple()
	{
	}

	UFUNCTION(BlueprintEvent)
	void OnChangeBallColor(FLinearColor NewColor)
	{}
}