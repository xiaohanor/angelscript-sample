class AAbyssPlatform : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent Collision;
	default Collision.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Block);

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MeshComp;
	default MeshComp.SetCollisionEnabled(ECollisionEnabled::NoCollision);

	UPROPERTY(EditAnywhere)
	bool bDebugOn;

	//REMOVE
	UPROPERTY(EditInstanceOnly)
	AAbyssPlatformManager Manager;

	FVector StartLocation;
	FQuat StartQuat;
	FVector TargetLocation;
	FQuat TargetQuat;

	FRotator StartRelativeRotation;

	bool bIsActive;

	float Speed;
	float BaseSpeed = 2000.0;

	bool bStartShake;

	float RYawSpeed;
	float RYawAmount;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		RYawAmount = Math::RandRange(4.5, 6.5);
		RYawSpeed = Math::RandRange(30.5, 40.5);
		StartRelativeRotation = MeshComp.RelativeRotation;
		// Manager.AddPlatformReference(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		//TODO make rotation a lerp w/ alpha instead
		FVector CurrentTargetLocation = bIsActive ? TargetLocation : StartLocation;
		FQuat CurrentTargetQuat = bIsActive ? TargetQuat : StartQuat;

		// if (bDebugOn)
		// {
		// 	PrintToScreen(f"{CurrentTargetQuat=}");
		// 	PrintToScreen(f"{StartQuat=}");
		// 	PrintToScreen(f"{ActorRotation=}");
		// }
		
		ActorLocation = Math::VInterpConstantTo(ActorLocation, CurrentTargetLocation, DeltaSeconds, Speed);
		ActorRotation = Math::QInterpConstantTo(ActorRotation.Quaternion(), CurrentTargetQuat, DeltaSeconds, 8.0).Rotator();

		if (bStartShake)
		{
			float Sin = Math::Sin(Time::GameTimeSeconds * RYawSpeed);
			MeshComp.RelativeRotation = StartRelativeRotation + FRotator(Sin * RYawAmount,0,0);
			// PrintToScreen(f"{RYawSpeed=}");
		}
	}

	void IniateStartTransform(FVector ManagerPosition, FVector NewStart, FQuat NewQuat)
	{
		Speed = BaseSpeed + (ManagerPosition - NewStart).Size();
		StartLocation = NewStart;
		StartQuat = NewQuat;
		TargetLocation = ActorLocation;
		TargetQuat = ActorRotation.Quaternion();
		ActorLocation = StartLocation;
		ActorRotation = StartQuat.Rotator();
	}

	void StartShake()
	{
		bStartShake = true;
	}

	void StopShake()
	{
		bStartShake = false;
	}

	void ResetShake()
	{
		bStartShake = false;
		MeshComp.RelativeRotation = StartRelativeRotation;
	}

	void ActivatePlatform()
	{
		bIsActive = true;
	}

	void DeactivatePlatform()
	{
		MeshComp.RelativeRotation = StartRelativeRotation;
		bIsActive = false;
	}
};