class ASkylineFlyingCarJumpingNpc : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent NpcPivot;

	UPROPERTY(DefaultComponent, Attach = NpcPivot)
	UCapsuleComponent Collision;
	default Collision.CapsuleRadius = 30.0;
	default Collision.CapsuleHalfHeight = 80.0;
	default Collision.RelativeLocation = FVector::UpVector * Collision.CapsuleHalfHeight;
	default Collision.CollisionProfileName = n"BlockAllDynamic";
	default Collision.bGenerateOverlapEvents = false;

	UPROPERTY(DefaultComponent)
	UBillboardComponent TargetLocationBillBoard;

	UPROPERTY(DefaultComponent, Attach = NpcPivot)
	UStaticMeshComponent StaticMeshComp;
	default StaticMeshComp.CollisionProfileName = CollisionProfile::NoCollision;

	UPROPERTY(DefaultComponent, Attach = NpcPivot)
	UStaticMeshComponent JumpingMeshComp;
	default JumpingMeshComp.CollisionProfileName = CollisionProfile::NoCollision;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 15000;

	UPROPERTY(DefaultComponent)
	USkylineFlyingCarImpactResponseComponent ImpactResponseComp;
	default ImpactResponseComp.VelocityLostOnImpact = 0;

	UPROPERTY(EditAnywhere)
	APlayerTrigger Trigger;


	float ArcHeight = 200.0;
	float FlightTime = 0.0;

	float FlightDuration;

	FVector StartLocation;
	FVector TargetLocation;

	FQuat ActorStarRotation; 
	FQuat LocationRotation;

	

	FVector TargetOffset;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		FlightDuration = Math::RandRange(1.7, 2.3);
		JumpingMeshComp.SetHiddenInGame(true);
		ImpactResponseComp.OnImpactedByFlyingCar.AddUFunction(this, n"OnImpactedByFlyingCar");
		Trigger.OnPlayerEnter.AddUFunction(this, n"HandlePlayerEnter");
		StartLocation = ActorLocation;
		TargetLocation = TargetLocationBillBoard.GetWorldLocation();

		ActorStarRotation = GetActorTransform().GetRotation();
		LocationRotation = TargetLocationBillBoard.GetComponentQuat();

		SetActorTickEnabled(false);
	}
	
	UFUNCTION()
	private void HandlePlayerEnter(AHazePlayerCharacter Player)
	{
		JumpingMeshComp.SetHiddenInGame(false);
		StaticMeshComp.SetHiddenInGame(true);
		SetActorTickEnabled(true);
	}


	UFUNCTION()
	private void OnImpactedByFlyingCar(ASkylineFlyingCar FlyingCar, FFlyingCarOnImpactData ImpactData)
	{
		BP_OnImpactedByFlyingCar();
		DestroyActor();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		
		FlightTime += DeltaSeconds;
		float Alpha = Math::Min(1.0, FlightTime / FlightDuration);

		FVector Location = Math::Lerp(StartLocation, TargetLocation, Alpha);
		FQuat Rotation = FQuat::Slerp(ActorStarRotation, LocationRotation, Alpha);
		Location.Z += Math::Sin(Alpha * PI) * ArcHeight;

		ActorLocation = Location;
		NpcPivot.SetRelativeRotation(Rotation);
	
	}


	void Explode()
	{
		DestroyActor();
	}

	UFUNCTION(BlueprintEvent)
	void BP_OnImpactedByFlyingCar() {}
};