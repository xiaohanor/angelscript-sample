asset SplitTraversalControlInteractionSheet of UHazeCapabilitySheet
{
	AddCapability(n"DoubleInteractionCapability");
	AddCapability(n"SplitTraversalPushablePlatformCapability");

	Blocks.Add(n"Movement");
	Blocks.Add(n"GameplayAction");
}

class ASplitTraversalPushableActor : ADoubleInteractionActor
{
	default LeftInteraction.InteractionSheet = SplitTraversalControlInteractionSheet;

	EHazeWorldLinkLevel ActorSplit;

	UPROPERTY(EditAnywhere)
	AWorldLinkDoubleActor PushActor;

	UPROPERTY(EditAnywhere)
	ASplitTraversalTankFireInteraction FireInteraction;

	UPROPERTY(EditAnywhere)
	TArray<AActor> Platforms;

	UPROPERTY(EditAnywhere)
	AStaticCameraActor LeftCamera;

	AStaticCameraActor RightCamera;

	TPerPlayer<FVector> CurrentOffCenterOffset;
	TPerPlayer<FVector> TargetOffCenterOffset;

	FVector LeftRelative;
	FVector RightRelative;

	TArray<FVector> PlatformOriginalPosition;
	TArray<FHazeAcceleratedVector> PlatformCurrentPosition;

	float PlatformTargetPosition = 0.0;

	bool bIsCompleted = false;
	bool bWantStairs = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		auto Manager = ASplitTraversalManager::GetSplitTraversalManager();
		ActorSplit = Manager.GetSplitForLocation(ActorLocation);

		LeftRelative = LeftInteraction.RelativeLocation;
		RightRelative = RightInteraction.RelativeLocation;

		LeftInteraction.OnInteractionStarted.AddUFunction(this, n"OnStartInteraction");
		LeftInteraction.OnInteractionStopped.AddUFunction(this, n"OnStopInteraction");

		RightInteraction.OnInteractionStarted.AddUFunction(this, n"OnStartInteraction");
		RightInteraction.OnInteractionStopped.AddUFunction(this, n"OnStopInteraction");

		RightInteraction.AddInteractionCondition(this, FInteractionCondition(this, n"CanUseRightInteraction"));

		OnDoubleInteractionCompleted.AddUFunction(this, n"OnCompleted");

		RightCamera = AStaticCameraActor::Spawn(
			Manager.Position_Convert(LeftCamera.ActorLocation, EHazeWorldLinkLevel::SciFi, EHazeWorldLinkLevel::Fantasy),
		);

		for (AActor Step : Platforms)
		{
			PlatformOriginalPosition.Add(Step.ActorLocation);
			PlatformCurrentPosition.Add(FHazeAcceleratedVector());
			PlatformCurrentPosition.Last().SnapTo(Step.ActorLocation + FVector(0, 0, -800));
		}
	}

	UFUNCTION()
	private EInteractionConditionResult CanUseRightInteraction(
	                                                           const UInteractionComponent InteractionComponent,
	                                                           AHazePlayerCharacter Player)
	{
		if (PlatformTargetPosition == 1.0 && PlatformCurrentPosition[0].Value.Z >= PlatformOriginalPosition[0].Z + 445)
			return EInteractionConditionResult::Enabled;
		return EInteractionConditionResult::DisabledVisible;
	}

	UFUNCTION()
	void ClearInteractionCameras()
	{
		for (AHazePlayerCharacter Player : Game::Players)
		{
			Player.DeactivateCameraByInstigator(n"Completed", 2.0);
			TargetOffCenterOffset[Player] = FVector(0, 0, 0);
		}

		FireInteraction.Interaction.Enable(n"NotReady");
	}

	UFUNCTION()
	private void OnCompleted()
	{
		bIsCompleted = true;

		LeftInteraction.Disable(n"Done");
		RightInteraction.Disable(n"Done");

		for (AHazePlayerCharacter Player : Game::Players)
		{
			Player.ActivateCamera(
				Player.IsMio() ? LeftCamera : RightCamera,
				2.0, n"Completed");

			TargetOffCenterOffset[Player] = FVector(
				Player.IsMio() ? -1.0 : 1.0, 0, 0);
		}
	}

	UFUNCTION()
	private void OnStartInteraction(UInteractionComponent InteractionComponent,
	                                    AHazePlayerCharacter Player)
	{
	}

	UFUNCTION()
	private void OnStopInteraction(UInteractionComponent InteractionComponent,
	                                   AHazePlayerCharacter Player)
	{
	}

	void UpdatePlatforms(float DeltaTime)
	{
		for (int i = 0, Count = Platforms.Num(); i < Count; ++i)
		{
			FVector Target = PlatformOriginalPosition[i];
			Target += FVector(0, 0, 450 * PlatformTargetPosition);

			PlatformCurrentPosition[i].AccelerateTo(Target, 2.0, DeltaTime);
			Platforms[i].ActorLocation = PlatformCurrentPosition[i].Value;
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		for (AHazePlayerCharacter Player : Game::Players)
		{
			auto ViewPoint = Cast<UHazeCameraViewPoint>(Player.GetViewPoint());

			FVector TargetOffset = TargetOffCenterOffset[Player];
			FVector& Offset = CurrentOffCenterOffset[Player];

			if (!TargetOffset.IsNearlyZero() || !Offset.IsNearlyZero())
			{
				Offset = Math::VInterpConstantTo(Offset, TargetOffset, DeltaSeconds, 0.7);
				ViewPoint.ApplyOffCenterProjectionOffset(FVector2D(Offset.X, Offset.Y), this);
			}
			else
			{
				ViewPoint.ClearOffCenterProjectionOffset(this);
			}
		}

		auto Manager = ASplitTraversalManager::GetSplitTraversalManager();
		LeftInteraction.WorldLocation = Manager.Position_Convert(
			GetActorTransform().TransformPosition(LeftRelative),
			ActorSplit, EHazeWorldLinkLevel::SciFi
		);

		RightInteraction.WorldLocation = Manager.Position_Convert(
			GetActorTransform().TransformPosition(RightRelative),
			ActorSplit, EHazeWorldLinkLevel::Fantasy
		);

		UpdatePlatforms(DeltaSeconds);
	}
};