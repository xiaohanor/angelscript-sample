class ASplitTraversalWateringCan : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UFauxPhysicsAxisRotateComponent RotateComp;

	UPROPERTY(DefaultComponent, Attach = RotateComp)
	UFauxPhysicsForceComponent ForceComp;

	UPROPERTY(DefaultComponent)
	UInteractionComponent InteractionComp;
	default InteractionComp.InteractionCapability = n"SplitTraversalWateringCanAimCapability";

	UPROPERTY(DefaultComponent, Attach = RotateComp)
	UHazeCapsuleCollisionComponent WaterCollisionComp;

	UPROPERTY(DefaultComponent, Attach = RotateComp)
	USceneComponent WaterRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent SciFiRoot;

	UPROPERTY(DefaultComponent, Attach = SciFiRoot)
	USceneComponent SciFiRotateRoot;

	UPROPERTY(DefaultComponent, Attach = SciFiRotateRoot)
	USceneComponent SciFiWaterRoot;

	UPROPERTY(EditAnywhere)
	AHazeCameraActor Camera;

	UPROPERTY(EditAnywhere)
	float RotatingForce = 200.0;

	UPROPERTY(EditAnywhere)
	FTutorialPrompt TutorialPrompt;
	default TutorialPrompt.Action = ActionNames::PrimaryLevelAbility;

	bool bWatering = false;

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnActorModifiedInEditor()
	{
		SciFiRoot.SetWorldLocation(ActorLocation + FVector::ForwardVector * 500000.0);
		SciFiRoot.SetWorldRotation(ActorRotation);
	}
#endif

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		WaterCollisionComp.OnComponentBeginOverlap.AddUFunction(this, n"HandleBeginOverlap");
		WaterCollisionComp.OnComponentEndOverlap.AddUFunction(this, n"HandleEndOverlap");
		WaterCollisionComp.SetCollisionEnabled(ECollisionEnabled::NoCollision);
		WaterRoot.SetHiddenInGame(true, true);
		SciFiWaterRoot.SetHiddenInGame(true, true);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		SciFiRotateRoot.SetRelativeRotation(RotateComp.RelativeRotation);
	}

	UFUNCTION()
	private void HandleBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                                UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep,
	                                const FHitResult&in SweepResult)
	{
		auto ResposeComp = USplitTraversalWateringCanResponseComponent::Get(OtherActor);

		if (ResposeComp != nullptr)
		{
			ResposeComp.bOverlaping = true;
			ResposeComp.OnWaterBeginOverlap.Broadcast();
		}
	}

	UFUNCTION()
	private void HandleEndOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                              UPrimitiveComponent OtherComp, int OtherBodyIndex)
	{
		auto ResposeComp = USplitTraversalWateringCanResponseComponent::Get(OtherActor);

		if (ResposeComp != nullptr)
		{
			ResposeComp.bOverlaping = false;
			ResposeComp.OnWaterEndOverlap.Broadcast();
		}
	}

	UFUNCTION()
	void StartWater()
	{
		WaterCollisionComp.SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
		WaterRoot.SetHiddenInGame(false, true);
		SciFiWaterRoot.SetHiddenInGame(false, true);
	}

	UFUNCTION()
	void StopWater()
	{
		WaterCollisionComp.SetCollisionEnabled(ECollisionEnabled::NoCollision);
		WaterRoot.SetHiddenInGame(true, true);
		SciFiWaterRoot.SetHiddenInGame(true, true);
	}
};

class USplitTraversalWateringCanAimCapability : UInteractionCapability
{
	UPlayerMovementComponent MoveComp;

	ASplitTraversalWateringCan WateringCan;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		MoveComp = UPlayerMovementComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FInteractionCapabilityParams Params)
	{
		Super::OnActivated(Params);

		WateringCan = Cast<ASplitTraversalWateringCan>(ActiveInteraction.Owner);
		if (WateringCan.Camera != nullptr)
			Player.ActivateCamera(WateringCan.Camera, 2.0, this);

		Player.ShowTutorialPrompt(WateringCan.TutorialPrompt, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		if (WateringCan != nullptr)
			Player.DeactivateCamera(WateringCan.Camera);

		WateringCan.ForceComp.Force = FVector::ZeroVector;
		
		WateringCan.StopWater();

		Player.RemoveTutorialPromptByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (WasActionStarted(ActionNames::WeaponFire))
			WateringCan.StartWater();

		if (WasActionStopped(ActionNames::WeaponFire))
			WateringCan.StopWater();

		WateringCan.ForceComp.Force = FVector::RightVector * GetInputY() * WateringCan.RotatingForce;
	}

	UFUNCTION()
	float GetInputY()
	{
		return GetAttributeFloat(AttributeNames::MoveForward);
	}
};

event void FOnSplitTraversalWateringCanBeginOverlap();
event void FOnSplitTraversalWateringCanEndOverlap();

class USplitTraversalWateringCanResponseComponent : UActorComponent
{
	UPROPERTY()
	FOnSplitTraversalWateringCanBeginOverlap OnWaterBeginOverlap;

	UPROPERTY()
	FOnSplitTraversalWateringCanEndOverlap OnWaterEndOverlap;

	bool bOverlaping = false;

	UPROPERTY()
	float Progress = 0.0;

	UPROPERTY()
	float ProgressSpeed = 0.5;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bOverlaping && Progress < 1.0)
		{
			Progress += ProgressSpeed * DeltaSeconds;

			if (Progress > 1.0)
				Progress = 1.0;
		}
	}
};