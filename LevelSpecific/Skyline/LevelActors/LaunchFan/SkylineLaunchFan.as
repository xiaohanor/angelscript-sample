class ASkylineLaunchFan : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UCapsuleComponent Trigger;
	default Trigger.CapsuleRadius = 100.0;
	default Trigger.CapsuleHalfHeight = 200.0;
	default Trigger.bGenerateOverlapEvents = true;
	default Trigger.CollisionResponseToAllChannels = ECollisionResponse::ECR_Ignore;
	default Trigger.SetCollisionResponseToChannel(ECollisionChannel::PlayerCharacter, ECollisionResponse::ECR_Overlap);

	UPROPERTY(DefaultComponent)
	UArrowComponent LaunchLocation;

	UPROPERTY(DefaultComponent)
	USkylineInterfaceComponent InterfaceComp;

	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent CapabilityRequestComp;

	UPROPERTY(EditAnywhere, Meta = (MakeEditWidget))
	FVector TargetLocation;

	UPROPERTY(EditAnywhere)
	float JumpHeight = 500.0;

	UPROPERTY(EditAnywhere)
	float Cooldown = 1.0;

	bool bHasLaunched = false;
	float ActivationTime = 0.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Trigger.OnComponentBeginOverlap.AddUFunction(this, n"HandleTriggerOverlap");

		InterfaceComp.OnActivated.AddUFunction(this, n"HandleActivated");
		InterfaceComp.OnDeactivated.AddUFunction(this, n"HandleDectivated");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bHasLaunched && Time::GameTimeSeconds > ActivationTime + Cooldown)
		{
			InterfaceComp.TriggerActivate();
			bHasLaunched = false;
		}
	}

	UFUNCTION()
	private void HandleTriggerOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep, const FHitResult&in SweepResult)
	{
		auto Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		auto UserComp = USkylineLaunchFanUserComponent::Get(Player);
		if (UserComp == nullptr)
			return;

		UserComp.Launch(LaunchLocation.WorldLocation, LaunchLocation.ForwardVector * 2000.0);
	}

	UFUNCTION()
	private void HandleActivated(AActor Caller)
	{
		Launch();
	}

	UFUNCTION()
	private void HandleDectivated(AActor Caller)
	{
	}

	void Launch()
	{
		auto Trace = Trace::InitFromPrimitiveComponent(Trigger);
		auto Overlaps = Trace.QueryOverlaps(Trigger.WorldLocation);

		for (auto Overlap : Overlaps)
		{
			auto Player = Cast<AHazePlayerCharacter>(Overlap.Actor);
			if (Player != nullptr)
			{
				auto LaunchComp = USkylineLaunchPadUserComponent::Get(Player);
				FVector TargetLocationWorld = ActorTransform.TransformPositionNoScale(TargetLocation);

				LaunchComp.Launch(TargetLocationWorld);
				Debug::DrawDebugPoint(TargetLocationWorld, 100.0, FLinearColor::Green, 5.0);
			}


//				Player.AddMovementImpulseToReachHeight(JumpHeight);
		}
	
		InterfaceComp.TriggerDeactivate();

		ActivationTime = Time::GameTimeSeconds;
		bHasLaunched = true;

		BP_OnLaunch();
	}

	/* BlueprintEvents */
	UFUNCTION(BlueprintEvent, NotBlueprintCallable)
	void BP_OnLaunch() {}
};