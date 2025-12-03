class ASummitBouncyBirdNest : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent RotateRoot;

	UPROPERTY(DefaultComponent, Attach = RotateRoot)
	USceneComponent PlatformRoot;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 16500.0;

	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent RequestComp;
	default RequestComp.PlayerCapabilityClasses.Add(USummitBouncyBirdNestPlayerLandCapability);

	UPROPERTY(DefaultComponent)
	USceneComponent MiddleOfBasketRoot;

	UPROPERTY(DefaultComponent)
	UTemporalLogTransformLoggerComponent TempLogTransformComp;

	/** A fraction of the lowest dip before it launches the player it is on
	 * Lowest dip refers to how low it has been angled that undulation
	 * 
	 * If it as lowest has gone 15 degrees this time, 
	 * 0.5 will make it launch the player at 7.5 degrees lower than default */
	UPROPERTY(EditAnywhere, Category = "Settings")
	float FractionOfLowestDipToLaunch = 0.5;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float PlayerLaunchImpulseSize = 1600.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float PlatformAngularImpulseOnImpact = 90.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float PlayerMinVelocityForAngularImpulse = 200.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	UForceFeedbackEffect LaunchRumble;

	UPROPERTY(EditAnywhere, Category = "Settings")
	TSubclassOf<UCameraShakeBase> LaunchCameraShake;

	UPROPERTY(EditAnywhere, Category = "Eggs")
	TArray<ASummitBouncyBirdNestEgg> AttachEggs;

	UPROPERTY(EditInstanceOnly, Category = "Eggs")
	bool bLaunchToOtherNest = true;

	UPROPERTY(EditInstanceOnly, Category = "Eggs", Meta = (EditCondition = "bLaunchToOtherNest", EditConditionHides))
	ASummitBouncyBirdNest CatchingOtherNest;

	UPROPERTY(EditInstanceOnly, Category = "Eggs", Meta = (EditCondition = "bLaunchToOtherNest", EditConditionHides))
	float EggLaunchHeight = 1000.0;

	FHazeAcceleratedRotator AccPlatformRotation;

	TPerPlayer<UPlayerMovementComponent> MoveComp;
	float StartRoll;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartRoll = RotateRoot.RelativeRotation.Roll;

		for(auto Egg : AttachEggs)
		{
			AttachEgg(Egg);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		AccPlatformRotation.SpringTo(FRotator::ZeroRotator, 120, 0.2, DeltaSeconds);
		RotateRoot.RelativeRotation = AccPlatformRotation.Value;
	}

	void ApplyLandImpulse()
	{
		AccPlatformRotation.Velocity += FRotator(0, 0, PlatformAngularImpulseOnImpact);
		AccPlatformRotation.Velocity.Roll = Math::Min(AccPlatformRotation.Velocity.Roll, PlatformAngularImpulseOnImpact);
	}

	UFUNCTION(BlueprintPure)
	float GetNestPlatformRotationAlpha() const
	{
		return Math::GetMappedRangeValueClamped(FVector2D(5, -2.0), FVector2D(-1, 1), AccPlatformRotation.Value.Roll);
	}

	void LaunchAllEggsOnBirdNest()
	{
		for(auto Egg : AttachEggs)
		{
			if(Egg != nullptr)
				Egg.GetLaunched(this);
		}
		AttachEggs.Empty();
	}

	void AttachEgg(ASummitBouncyBirdNestEgg Egg)
	{
		if(Egg != nullptr)
			Egg.AttachToComponent(PlatformRoot, AttachmentRule = EAttachmentRule::KeepWorld);
	}
};