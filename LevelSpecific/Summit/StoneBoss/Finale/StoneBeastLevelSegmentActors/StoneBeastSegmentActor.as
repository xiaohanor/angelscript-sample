class AStoneBeastSegmentActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;
	default Root.SetMobility(EComponentMobility::Movable);

	UPROPERTY(DefaultComponent, Attach = Root)
	UPlayerInheritMovementComponent InheritMovementComp;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent Visual;
	default Visual.SetWorldScale3D(FVector(5.0));
#endif

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent RotateRoot;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"StoneBeastSegmentMovementCapability");

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListComponent;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 50000.0;

	UPROPERTY(EditAnywhere, Category = "Setup")
	float Speed = 0.75;

	UPROPERTY(EditAnywhere, Category = "Setup")
	bool bStartDisabled = false;

	UPROPERTY(EditAnywhere, Category = "Setup|Vertical")
	float VerticalStartingTime = 0.0;

	UPROPERTY(EditAnywhere, Category = "Setup|Vertical")
	float VerticalDistance = 80.0;

	UPROPERTY(EditAnywhere, Category = "Setup|Pitching")
	float PitchStartingTime = 0.0;

	UPROPERTY(EditAnywhere, Category = "Setup|Pitching")
	float PitchRange = 0.0;

	UPROPERTY(EditAnywhere)
	int BPEnablerID = 0;

	// FRuntimeFloatCurve MovementCurve;
	// default MovementCurve.AddDefaultKey(0, 0.0);
	// default MovementCurve.AddDefaultKey(0.5, 1.0);
	// default MovementCurve.AddDefaultKey(1.0, 0.0);

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TArray<AActor> AttachedActors;
		GetAttachedActors(AttachedActors);
		for (AActor Actor : AttachedActors)
		{
			Actor.AttachToComponent(RotateRoot, NAME_None, EAttachmentRule::KeepWorld);
		}

		if (bStartDisabled)
			AddActorDisable(this);
	}

	void EnableFromStartDisabled()
	{
		RemoveActorDisable(this);
	}
};