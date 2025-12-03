class ASummitWaterTempleInnerBreakingActivatorLever : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent LeverRoot;

	UPROPERTY(DefaultComponent, Attach = LeverRoot)
	UStaticMeshComponent LeverMesh;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent LeverBase;

	UPROPERTY(DefaultComponent, Attach = Root)
	UInteractionComponent InteractionComp;
	default InteractionComp.InteractionCapability = n"SummitWaterTempleInnerBreakingActivatorLeverInteractionCapability";
	default InteractionComp.MovementSettings = FMoveToParams::SmoothTeleport();
	default InteractionComp.ActionShape.BoxExtents = FVector(75, 75, 100);
	default InteractionComp.ActionShapeTransform = FTransform(FVector(-75, 0, 100));
	default InteractionComp.FocusShape.SphereRadius = 7300.0;
	default InteractionComp.UsableByPlayers = EHazeSelectPlayer::Mio;
	default InteractionComp.WidgetVisualOffset = FVector(0.0, 0.0, 200.0);
	default InteractionComp.bPlayerCanCancelInteraction = false;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 15000.0;

	UPROPERTY(DefaultComponent)
	UTemporalLogTransformLoggerComponent TempLogTransformComp;

	UPROPERTY(EditDefaultsOnly, Category = "Setup")
	UHazeLocomotionFeatureBase LeverFeature;

	UPROPERTY(EditAnywhere, Category = "Settings")
	FVector PlayerOffset = FVector(-80, 0, 15);

	// UPROPERTY(EditAnywhere, Category = "Settings")
	// float MoveLeverDuration = 0.5;

	UPROPERTY(EditAnywhere, Category = "Settings")
	bool bLeverGoesToLeft = true;

	UPROPERTY()
	ESummitActivatorLeverEvent OnActivationStarted;

	UPROPERTY()
	ESummitActivatorLeverEvent OnLeverBroken;

	float TimeWhenBreak = MAX_flt;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float StartRoll = 20.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float TargetRoll = -5.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	FRuntimeFloatCurve AlphaCurve;
	default AlphaCurve.AddDefaultKey(0.0, 0.0);
	default AlphaCurve.AddDefaultKey(1.0, 1.0);

	FVector HandleRelativeLocation;
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		HandleRelativeLocation = LeverRoot.RelativeLocation;
		SetActorTickEnabled(false);
	}

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		LeverRoot.RelativeRotation = FRotator(0.0, 0.0, StartRoll);
	}

	void BreakOffHandle()
	{
		TimeWhenBreak = Time::GameTimeSeconds;
		// FauxAxisRotateComp.DetachFromParent(true, true);
		SetActorTickEnabled(true);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		float ActiveDuration = Time::GetGameTimeSince(TimeWhenBreak);
		float RotationAlpha = Math::Saturate(ActiveDuration / 1.0);
		float RotationEasing = Math::CircularIn(0, 1, RotationAlpha);
		// float RootOffset = 0;
		float HeightOffset = Math::Lerp(0, 10, Math::Saturate((ActiveDuration - 0.2) / 0.4));
		// if (ActiveDuration > 0.5)
		// {
		// 	float RootOffsetAlpha = Math::Saturate((ActiveDuration - 0.5) / 0.4);
		// 	float RootOffsetEasing = Math::Lerp(0, 1, RootOffsetAlpha);
		// 	RootOffset = Math::Lerp(0, -60, RootOffsetEasing);
		// }
		LeverRoot.RelativeLocation = HandleRelativeLocation + FVector(0, 0, HeightOffset);
		FRotator NewRotation = FRotator(0, 0, TargetRoll) + FRotator(0, 0, Math::Lerp(0, -85, RotationEasing));
		LeverRoot.RelativeRotation = NewRotation;
	}
};