event void FThrowableCrossedSplitScreen(bool bScifi);

class ASplitTraversalThrowable : AWorldLinkDoubleActor
{
	UPROPERTY(DefaultComponent, Attach = FantasyRoot)
	USceneComponent FantasyProp;
	UPROPERTY(DefaultComponent, Attach = ScifiRoot)
	USceneComponent ScifiProp;

	UPROPERTY(DefaultComponent, Attach = FantasyRoot)
	UOneShotInteractionComponent PickupInteraction;

	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent RequestComp;
	default RequestComp.PlayerCapabilities.Add(n"SplitTraversalThrowableHeldCapability");
	default RequestComp.PlayerCapabilities.Add(n"SplitTraversalThrowableThrowCapability");

	UPROPERTY(DefaultComponent)
	USceneComponent GlitchEffect;

	UPROPERTY(EditAnywhere)
	UAnimSequence ThrowAnimation;
	UPROPERTY(EditAnywhere)
	UHazeBoneFilterAsset ThrowBoneFilter;

	UPROPERTY()
	FThrowableCrossedSplitScreen OnThrowableCrossedSplitScreen;

	const float ThrowDuration = 1.0;

	bool bIsThrowInitiated = false;
	bool bIsThrowing = false;
	FVector2D StartScreenLocation;
	float BaseScreenDepth;

	bool bInScifi;

	float ThrowSpeed = 0.0;
	float ThrowDistance = 0.0;

	const float ThrowAcceleration = 1.0;
	const float ThrowInitialSpeed = 1.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		PickupInteraction.OnInteractionStarted.AddUFunction(this, n"StartPickup");
		PickupInteraction.OnInteractionStopped.AddUFunction(this, n"FinishPickup");

		ShowFantasy();
	}

	UFUNCTION()
	private void StartPickup(UInteractionComponent InteractionComponent, AHazePlayerCharacter Player)
	{
		PickupInteraction.Disable(n"PickedUp");
	}

	UFUNCTION()
	private void FinishPickup(UInteractionComponent InteractionComponent, AHazePlayerCharacter Player)
	{
		Player.RootOffsetComponent.ClearOffset(n"MoveToSmoothTeleport");

		auto ThrowableComp = USplitTraversalThrowablePlayerComponent::GetOrCreate(Player);
		ThrowableComp.HeldThrowable = this;
	}

	void ShowScifi()
	{
		FantasyProp.SetHiddenInGame(true, true);
		ScifiProp.SetHiddenInGame(false, true);
		GlitchEffect.AttachToComponent(FantasyRoot);
		bInScifi = true;

		OnThrowableCrossedSplitScreen.Broadcast(bInScifi);
	}

	void ShowFantasy()
	{
		FantasyProp.SetHiddenInGame(false, true);
		ScifiProp.SetHiddenInGame(true, true);
		GlitchEffect.AttachToComponent(ScifiRoot);
		bInScifi = false;

		OnThrowableCrossedSplitScreen.Broadcast(bInScifi);
	}

	AHazePlayerCharacter GetRelevantPlayer() const
	{
		if (bInScifi)
			return Game::Mio;
		else
			return Game::Zoe;
	}

	USceneComponent GetRelevantRoot() const
	{
		if (bInScifi)
			return ScifiRoot;
		else
			return FantasyRoot;
	}

	USceneComponent GetOppositeRoot() const
	{
		if (!bInScifi)
			return ScifiRoot;
		else
			return FantasyRoot;
	}

	void StartThrowing()
	{
		SceneView::ProjectWorldToScreenPosition(
			GetRelevantPlayer(),
			GetRelevantRoot().WorldLocation,
			StartScreenLocation,
		);

		BaseScreenDepth = GetRelevantPlayer().ViewLocation.Distance(GetRelevantRoot().WorldLocation);
		GlitchEffect.SetHiddenInGame(true, true);

		ThrowSpeed = ThrowInitialSpeed;
		ThrowDistance = 0.0;
		bIsThrowing = true;
	}

	EHazeWorldLinkLevel GetRelevantSplit()
	{
		if (bInScifi)
			return EHazeWorldLinkLevel::SciFi;
		else
			return EHazeWorldLinkLevel::Fantasy;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bIsThrowing)
		{
			ThrowSpeed += ThrowAcceleration * DeltaSeconds;
			ThrowDistance += ThrowSpeed * DeltaSeconds;

			AHazePlayerCharacter TargetPlayer = GetRelevantPlayer().OtherPlayer;
			FVector TargetLocation = TargetPlayer.Mesh.GetSocketLocation(n"RightAttach");

			FVector2D TargetScreenLocation;
			SceneView::ProjectWorldToScreenPosition(
				TargetPlayer,
				TargetLocation,
				TargetScreenLocation,
			);

			float TargetDepth = TargetPlayer.ViewLocation.Distance(TargetLocation) / BaseScreenDepth;

			FHazeRuntimeSpline ThrowSpline;
			ThrowSpline.AddPoint(FVector(StartScreenLocation.X, StartScreenLocation.Y, 1.0));
			ThrowSpline.AddPoint(FVector(0.5, 0.5, 1.0));
			ThrowSpline.AddPoint(FVector(TargetScreenLocation.X, TargetScreenLocation.Y, TargetDepth));

			FVector SplineLocation = ThrowSpline.GetLocationAtDistance(ThrowDistance);

			FVector Origin;
			FVector Direction;
			SceneView::DeprojectScreenToWorld_Absolute(
				FVector2D(SplineLocation.X, SplineLocation.Y), Origin, Direction
			);

			auto Manager = ASplitTraversalManager::GetSplitTraversalManager();
			auto LocationSplit = Manager.GetSplitForLocation(Origin);

			SetActorLocationInSplit(
				Origin + Direction * (SplineLocation.Z * BaseScreenDepth),
				LocationSplit,
			);

			FantasyProp.SetHiddenInGame(LocationSplit != EHazeWorldLinkLevel::Fantasy, true);
			ScifiProp.SetHiddenInGame(LocationSplit != EHazeWorldLinkLevel::SciFi, true);

			if (ThrowDistance > ThrowSpline.Length)
			{
				bInScifi = !bInScifi;

				GlitchEffect.SetHiddenInGame(false, true);
				if (bInScifi)
					ShowScifi();
				else
					ShowFantasy();

				auto ThrowableComp = USplitTraversalThrowablePlayerComponent::GetOrCreate(GetRelevantPlayer());
				ThrowableComp.HeldThrowable = this;

				bIsThrowing = false;
			}
		}
	}
};