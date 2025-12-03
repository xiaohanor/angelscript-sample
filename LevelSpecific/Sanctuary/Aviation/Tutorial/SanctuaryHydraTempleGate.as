event void FSanctuaryHydraTempleGateSignature();

class ASanctuaryHydraTempleGate : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent BirdAttachmentRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent FishRotateRoot;

	UPROPERTY(DefaultComponent, Attach = FishRotateRoot)
	USceneComponent FishAttachmentRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent BirdStatueLocation;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent FishStatueLocation;

	UPROPERTY(EditAnywhere)
	UAnimSequence BirdSitAnimation;
	UPROPERTY(EditAnywhere)
	UAnimSequence BirdFlyAnimation;

	UPROPERTY()
	FHazeTimeLike FlyTimeLike;
	default FlyTimeLike.UseSmoothCurveZeroToOne();
	default FlyTimeLike.Duration = 3;

	UPROPERTY(EditInstanceOnly)
	TArray<ASanctuaryHydraTempleEntrancePodium> Podiums;

	UPROPERTY()
	FSanctuaryHydraTempleGateSignature OnActivated;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComp;

	ASanctuaryMegaCompanion FishCompanion;
	ASanctuaryMegaCompanion BirdCompanion;

	FTransform InitialBirdTransform;
	FTransform InitialFishTransform;

	float RotationSpeed = 150.0;

	bool bActivated = false;
	bool bCrumbActivated = false;
	float TryLateSetupCooldown = 0.2;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		FlyTimeLike.BindUpdate(this, n"FlyTimeLikeUpdate");
		FlyTimeLike.BindFinished(this, n"FlyTimeLikeFinished");

		InitialBirdTransform = BirdStatueLocation.WorldTransform;
		InitialFishTransform = FishStatueLocation.WorldTransform;
	}

	private void HandleLateSetup(float DeltaSeconds)
	{
		bool bNeedsSetup = FishCompanion == nullptr || BirdCompanion == nullptr;
		TryLateSetupCooldown -= DeltaSeconds;
		if (bNeedsSetup && TryLateSetupCooldown < 0.0)
		{
			TryLateSetupCooldown = 0.2;
			LateSetup();
		}
	}

	private void LateSetup()
	{
		USanctuaryCompanionMegaCompanionPlayerComponent MioPlayerComponent = USanctuaryCompanionMegaCompanionPlayerComponent::Get(Game::Mio);
		if (MioPlayerComponent != nullptr)
			BirdCompanion = MioPlayerComponent.MegaCompanion;
		USanctuaryCompanionMegaCompanionPlayerComponent ZoePlayerComponent = USanctuaryCompanionMegaCompanionPlayerComponent::Get(Game::Zoe);
		if (ZoePlayerComponent != nullptr)
			FishCompanion = ZoePlayerComponent.MegaCompanion;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		HandleLateSetup(DeltaSeconds);

		if (bCrumbActivated)
			FishRotateRoot.AddRelativeRotation(FRotator(0.0, 0.0, RotationSpeed * DeltaSeconds));

		HandleActivate();
	}

	private void HandleActivate()
	{
		if (HasControl())
		{
			bool bBothInside = true;
			for (ASanctuaryHydraTempleEntrancePodium Podium : Podiums)
			{
				if (!Podium.bActive)
					bBothInside = false;
			}
			if (bBothInside && !bActivated)
			{
				bActivated = true;
				CrumbActivate();
			}
		}
	}

	UFUNCTION()
	private void FlyTimeLikeUpdate(float CurrentValue)
	{
		FVector BirdLoc = Math::Lerp(InitialBirdTransform.Location, BirdAttachmentRoot.WorldLocation, CurrentValue);
		FRotator BirdRot = Math::LerpShortestPath(InitialBirdTransform.Rotation.Rotator(), BirdAttachmentRoot.WorldRotation, CurrentValue);

		FVector FishLoc = Math::Lerp(InitialFishTransform.Location, FishAttachmentRoot.WorldLocation, CurrentValue);
		FRotator FishRot = Math::LerpShortestPath(InitialFishTransform.Rotation.Rotator(), FishAttachmentRoot.WorldRotation, CurrentValue);

		BirdCompanion.SetActorLocationAndRotation(BirdLoc, BirdRot);
		FishCompanion.SetActorLocationAndRotation(FishLoc, FishRot);

		RotationSpeed = CurrentValue * 250.0;
	}

	UFUNCTION()
	private void FlyTimeLikeFinished()
	{
		FishCompanion.AttachToComponent(FishAttachmentRoot, NAME_None, EAttachmentRule::KeepWorld);
		BirdCompanion.AttachToComponent(BirdAttachmentRoot, NAME_None, EAttachmentRule::KeepWorld);
	}

	UFUNCTION(CrumbFunction)
	private void CrumbActivate()
	{
		bCrumbActivated = true;
		FlyTimeLike.Play();
		BP_Activate();
		OnActivated.Broadcast();

		FHazePlaySlotAnimationParams Params;
		Params.Animation = BirdFlyAnimation;
		Params.bLoop = true;
		BirdCompanion.SkeletalMesh.PlaySlotAnimation(Params);
	}

	UFUNCTION(BlueprintEvent)
	private void BP_Activate(){}
};