UCLASS(Abstract)
class APrisonerTransportPlatform : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent PlatformRoot;

	UPROPERTY(DefaultComponent, Attach = PlatformRoot)
	USceneComponent VOAttachRootA;

	UPROPERTY(DefaultComponent, Attach = PlatformRoot)
	USceneComponent VOAttachRootB;

	UPROPERTY(DefaultComponent, Attach = PlatformRoot)
	USceneComponent VOAttachRootC;

	UPROPERTY(DefaultComponent, Attach = PlatformRoot)
	USceneComponent BackPoint;

	UPROPERTY(DefaultComponent, Attach = PlatformRoot)
	USceneComponent LeftTopHatchRoot;

	UPROPERTY(DefaultComponent, Attach = PlatformRoot)
	USceneComponent RightTopHatchRoot;

	UPROPERTY(DefaultComponent, Attach = PlatformRoot)
	USwingPointComponent SwingPointComp;
	default SwingPointComp.bIgnorePointOwner = false;

	UPROPERTY(DefaultComponent, Attach = PlatformRoot)
	UPlayerInheritMovementComponent InheritMovementComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UBoxComponent OverlapTrigger;

	UPROPERTY(DefaultComponent, Attach = PlatformRoot)
	USceneComponent PropellerRoot;

	UPROPERTY(DefaultComponent, Attach = PlatformRoot)
	UHazeSkeletalMeshComponentBase PrisonersMesh;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilityClasses.Add(UPrisonerTransportPlatformMoveCapability);

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedActorComp;

	UPROPERTY(DefaultComponent)
	UPrisonerTransportDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 10000;

	UPROPERTY(DefaultComponent)
	UMovementImpactCallbackComponent MovementImpactCallbackComp;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UTemporalLogTransformLoggerComponent TransformLoggerComp;
#endif

	UPROPERTY(EditInstanceOnly)
	ASplineActor SplineActor;

	float StartDistanceAlongSpline = 0;

	UPROPERTY(EditAnywhere)
	float MoveSpeed = 900.0;

	UPROPERTY(EditAnywhere)
	bool bMoving = true;

	UPROPERTY(EditInstanceOnly)
	bool bPreviewPosition = false;
	UPROPERTY(EditInstanceOnly, meta = (ClampMin = "0.0", ClampMax = "1.0", UIMin = "0.0", UIMax = "1.0"))
	float PreviewFraction = 0.0;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike OpenTopHatchesTimeLike;

	bool bOpeningTopHatches = false;

	UPROPERTY(EditAnywhere)
	bool bHidePrisonerOnRestart = false;

	UPROPERTY(EditAnywhere)
	bool bSwingPointEnabled = true;

	float IncreasedSwingPreviewRange = 3600.0;
	float DecreasedSwingPreviewRange = 500.0;

	UPROPERTY(VisibleInstanceOnly, Meta = (UIMin = "0.0", UIMax = "2.0"))
	float HoverTimeOffset = 0.0;
	float HoverRollRange = 1.0;
	float HoverRollSpeed = 1.5;
	float HoverPitchRange = 1.5;
	float HoverPitchSpeed = 2.0;
	FVector HoverOffsetRange = FVector(0.0, 15.0, 30.0);
	FVector HoverOffsetSpeed = FVector(0.0, 0.5, 0.75);

	bool bLandingReactionEnabled = false;
	bool bLandingReactionTriggered = false;
	bool bLandingSkipReaction = false;

	UPROPERTY(BlueprintReadOnly)
	TSubclassOf<APrisonerTransportVOActor> VOActorClassA;
	UPROPERTY(BlueprintReadOnly)
	APrisonerTransportVOActor VoActorA;

	UPROPERTY(BlueprintReadOnly)
	TSubclassOf<APrisonerTransportVOActor> VOActorClassB;
	UPROPERTY(BlueprintReadOnly)
	APrisonerTransportVOActor VoActorB;

	UPROPERTY(BlueprintReadOnly)
	TSubclassOf<APrisonerTransportVOActor> VOActorClassC;
	UPROPERTY(BlueprintReadOnly)
	APrisonerTransportVOActor VoActorC;

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnActorModifiedInEditor()
	{
		if (bPreviewPosition && SplineActor != nullptr)
		{
			FTransform PreviewTransform = SplineActor.Spline.GetWorldTransformAtSplineDistance(SplineActor.Spline.SplineLength * PreviewFraction);
			FRotator Rot = FRotator(PreviewTransform.Rotation);
			Rot.Pitch = Math::Clamp(Rot.Pitch, -8.0, 8.0);
			SetActorLocationAndRotation(PreviewTransform.Location, Rot);
		}

		HoverTimeOffset = Math::RandRange(0.0, 2.0);
	}
#endif

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		VoActorA = SpawnActor(VOActorClassA, bDeferredSpawn = true);
		VoActorA.MakeNetworked(this, n"VoActorA");
		FinishSpawningActor(VoActorA);
		VoActorA.AttachToComponent(VOAttachRootA);

		VoActorB = SpawnActor(VOActorClassB, bDeferredSpawn = true);
		VoActorB.MakeNetworked(this, n"VoActorB");
		FinishSpawningActor(VoActorB);
		VoActorB.AttachToComponent(VOAttachRootB);

		VoActorC = SpawnActor(VOActorClassC, bDeferredSpawn = true);
		VoActorC.MakeNetworked(this, n"VoActorC");
		FinishSpawningActor(VoActorC);
		VoActorC.AttachToComponent(VOAttachRootC);

		StartDistanceAlongSpline = SplineActor.Spline.GetClosestSplineDistanceToWorldLocation(ActorLocation);

		OpenTopHatchesTimeLike.BindUpdate(this, n"UpdateOpenTopHatches");
		OpenTopHatchesTimeLike.BindFinished(this, n"FinishOpenTopHatches");

		if (!bSwingPointEnabled)
			SwingPointComp.Disable(this);

		MovementImpactCallbackComp.OnGroundImpactedByPlayer.AddUFunction(this, n"PlayerLanded");
	}

	void ReachedEndOfSpline()
	{
		bLandingReactionTriggered = false;
		
		if (bHidePrisonerOnRestart)
			HidePrisoners();

		UPrisonerTransportPlatformEffectEventHandler::Trigger_PrisonerResetReaction(this);
	}

	UFUNCTION()
	void OpenTopHatches()
	{
		bOpeningTopHatches = true;
		OpenTopHatchesTimeLike.Play();

		UPrisonerTransportPlatformEffectEventHandler::Trigger_OpenTopHatches(this);
	}

	UFUNCTION()
	void CloseTopHatches()
	{
		bOpeningTopHatches = false;
		OpenTopHatchesTimeLike.Reverse();

		UPrisonerTransportPlatformEffectEventHandler::Trigger_CloseTopHatches(this);
	}

	UFUNCTION(NotBlueprintCallable)
	void UpdateOpenTopHatches(float CurValue)
	{
		float Rot = Math::Lerp(0.0, 100.0, CurValue);
		LeftTopHatchRoot.SetRelativeRotation(FRotator(0.0, 0.0, -Rot));
		RightTopHatchRoot.SetRelativeRotation(FRotator(0.0, 0.0, Rot));
	}

	UFUNCTION(NotBlueprintCallable)
	void FinishOpenTopHatches()
	{
		if (bOpeningTopHatches)
			TopHatchesOpened();
		else
			TopHatchesClosed();
	}

	UFUNCTION()
	void SetLandingReactionEnabled(bool bEnabled)
	{
		bLandingReactionEnabled = bEnabled;
	}

	UFUNCTION()
	private void PlayerLanded(AHazePlayerCharacter Player)
	{
		if (bLandingReactionTriggered)
			return;

		if (bLandingReactionEnabled)
		{
			FPrisonerTransportPlatformEffectEventReactionParams Params;
			Params.Player = Player;
			UPrisonerTransportPlatformEffectEventHandler::Trigger_PrisonerLandingReaction(this, Params);
		}
		else
		{
			UPrisonerTransportPlatformEffectEventHandler::Trigger_PrisonerLandingSkipReaction(this);
		}

		bLandingReactionTriggered = true;
	}

	void TopHatchesOpened()
	{

	}

	void TopHatchesClosed()
	{

	}

	UFUNCTION()
	void HidePrisoners()
	{
		PrisonersMesh.SetHiddenInGame(true);
	}

	UFUNCTION()
	void RevealPrisoners()
	{
		PrisonersMesh.SetHiddenInGame(false);
	}

	UFUNCTION()
	void SetIncreasedSwingPreviewRange()
	{
		SwingPointComp.AdditionalVisibleRange = IncreasedSwingPreviewRange;
	}

	UFUNCTION()
	void SetDecreasedSwingPreviewRange()
	{
		SwingPointComp.AdditionalVisibleRange = DecreasedSwingPreviewRange;
	}
};

UFUNCTION(BlueprintCallable, BlueprintPure)
TArray<APrisonerTransportPlatform> GetAllPrisonerTransportPlatforms()
{
	TListedActors<APrisonerTransportPlatform> PrisonerTransportPlatforms;
	return PrisonerTransportPlatforms.Array;
}

class APrisonerTransportVOActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent)
	UBillboardComponent BillboardComp;

	UPROPERTY(DefaultComponent)
	UHazeVoxCharacterTemplateComponent VoxComp;
}