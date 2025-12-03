class AMeltdownUnderwaterThrowable : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UOneShotInteractionComponent PickupInteraction;
	default PickupInteraction.UsableByPlayers = EHazeSelectPlayer::Zoe;
	default PickupInteraction.MovementSettings = FMoveToParams::NoMovement();
	
	UPROPERTY(DefaultComponent)
	UOneShotInteractionComponent ThrowInteraction;
	default ThrowInteraction.UsableByPlayers = EHazeSelectPlayer::Zoe;

	UPROPERTY(EditAnywhere)
	TSubclassOf<AHazeActor> SpawnObject;
	UPROPERTY(EditAnywhere)
	float SpawnForwardOffset = 1000.0;
	UPROPERTY(EditAnywhere)
	float SpawnDownwardOffset = 400.0;

	bool bPickedUp = false;
	bool bThrown = false;

	FTransform OriginalPosition;
	FHazeAcceleratedFloat Offset;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OriginalPosition = ActorTransform;
		Offset.SnapTo(300.0);

		PickupInteraction.OnOneShotBlendingOut.AddUFunction(this, n"OnPickedUp");
		PickupInteraction.AddInteractionCondition(this, FInteractionCondition(this, n"CheckCanUse"));

		ThrowInteraction.Disable(n"NeedPickUp");
		ThrowInteraction.DetachFromParent(true);
		ThrowInteraction.OnOneShotBlendingOut.AddUFunction(this, n"OnThrown");
	}

	UFUNCTION()
	private EInteractionConditionResult CheckCanUse(const UInteractionComponent InteractionComponent,
	                                                AHazePlayerCharacter Player)
	{
		// Don't allow picking up if we already picked up something else
		UMeltdownUnderwaterThrowablePlayerComponent ThrowableComp = UMeltdownUnderwaterThrowablePlayerComponent::GetOrCreate(Player);
		if (ThrowableComp.PickedUp == nullptr)
			return EInteractionConditionResult::Enabled;
		else
			return EInteractionConditionResult::Disabled;
	}

	UFUNCTION()
	private void OnPickedUp(AHazePlayerCharacter Player, UOneShotInteractionComponent InteractionComponent)
	{
		UMeltdownUnderwaterThrowablePlayerComponent ThrowableComp = UMeltdownUnderwaterThrowablePlayerComponent::GetOrCreate(Player);
		ThrowableComp.PickedUp = this;
		bPickedUp = true;

		ThrowInteraction.Enable(n"NeedPickUp");
		AttachToComponent(Player.Mesh, n"LeftAttach");
	}

	UFUNCTION()
	private void OnThrown(AHazePlayerCharacter Player, UOneShotInteractionComponent Interaction)
	{
		ThrowInteraction.Disable(n"NeedPickUp");
		DetachRootComponentFromParent();

		UMeltdownUnderwaterThrowablePlayerComponent ThrowableComp = UMeltdownUnderwaterThrowablePlayerComponent::GetOrCreate(Player);
		ThrowableComp.PickedUp = nullptr;

		bThrown = true;
		bPickedUp = false;

		FVector2D ZoeScreenUV;
		SceneView::ProjectWorldToScreenPosition(Game::Zoe, Game::Zoe.ActorLocation, ZoeScreenUV);

		FVector2D ThrowScreenUV;
		ThrowScreenUV.X = ZoeScreenUV.X;
		ThrowScreenUV.Y = 0.01;

		FVector RayOrigin;
		FVector RayDirection;
		SceneView::DeprojectScreenToWorld_Relative(Game::Mio, ThrowScreenUV, RayOrigin, RayDirection);

		auto Intersection = Math::GetLineSegmentSphereIntersectionPoints(
			RayOrigin, RayOrigin + RayDirection * 100000.0,
			Game::Mio.ActorLocation, SpawnForwardOffset
		);

		FVector SpawnLocation = Intersection.MinIntersection;

		/*FVector SpawnLocation = Math::LinePlaneIntersection(
			RayOrigin, RayOrigin + RayDirection * 100.0,
			Game::Mio.ActorLocation, Game::Mio.ViewRotation.ForwardVector
		);*/

		//SpawnLocation += RayDirection * SpawnForwardOffset;
		SpawnLocation.Z -= SpawnDownwardOffset;

		SpawnActor(SpawnObject, SpawnLocation);
		DestroyActor();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bPickedUp)
		{
			FVector2D ZoeScreenUV;
			SceneView::ProjectWorldToScreenPosition(Game::Zoe, Game::Zoe.ActorLocation, ZoeScreenUV);

			FVector2D ThrowScreenUV;
			ThrowScreenUV.X = ZoeScreenUV.X;
			ThrowScreenUV.Y = 0.99;

			FVector RayOrigin;
			FVector RayDirection;
			SceneView::DeprojectScreenToWorld_Relative(Game::Zoe, ThrowScreenUV, RayOrigin, RayDirection);

			FVector InteractionLocation = Math::LinePlaneIntersection(
				RayOrigin, RayOrigin + RayDirection * 100.0,
				Game::Zoe.ActorLocation, Game::Zoe.ViewRotation.ForwardVector
			);

			ThrowInteraction.SetWorldLocation(InteractionLocation);
		}
		else
		{
			Offset.AccelerateTo(0.0, 1.0, DeltaSeconds);
			ActorLocation = OriginalPosition.Location + FVector::UpVector * Offset.Value;
		}
	}
};