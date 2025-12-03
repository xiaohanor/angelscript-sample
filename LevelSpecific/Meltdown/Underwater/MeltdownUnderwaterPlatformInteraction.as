class AMeltdownUnderwaterPlatformInteraction : AOneShotInteractionActor
{
	UPROPERTY()
	TSubclassOf<AMeltdownUnderwaterIcePlatform> PlatformClass;
	UPROPERTY()
	float Cooldown = 2.0;
	FVector OriginalPosition;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		Interaction.OnInteractionStarted.AddUFunction(this, n"OnStartInteraction");
		OriginalPosition = ActorLocation;
	}

	UFUNCTION()
	private void OnStartInteraction(UInteractionComponent InteractionComponent,
	                                AHazePlayerCharacter Player)
	{
		FVector2D PlatformScreenPos;
		SceneView::ProjectWorldToViewpointRelativePosition(
			Player, Player.ActorCenterLocation, PlatformScreenPos
		);
		PlatformScreenPos.X = 1.0;

		FVector RayOrigin;
		FVector RayDirection;
		SceneView::DeprojectScreenToWorld_Relative(
			Player.OtherPlayer, PlatformScreenPos,
			RayOrigin, RayDirection,
		);

		FVector PlatformLocation = Math::LinePlaneIntersection(
			RayOrigin, RayOrigin + RayDirection,
			OriginalPosition,
			FVector::UpVector
		);

		FRotator PlatformRotation = FRotator::MakeFromX(-Player.OtherPlayer.ViewRotation.RightVector);

		SpawnActor(
			PlatformClass,
			PlatformLocation,
			PlatformRotation
		);

		Interaction.Disable(n"Cooldown");
		Timer::SetTimer(this, n"EnableInteraction", Cooldown);
	}

	UFUNCTION()
	private void EnableInteraction()
	{
		Interaction.Enable(n"Cooldown");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		auto Player = Game::Zoe;
		
		// Get the position of the player on the screen
		FVector2D PlayerScreenPos;
		SceneView::ProjectWorldToViewpointRelativePosition(
			Player, Player.ActorLocation, PlayerScreenPos
		);

		{
			FVector2D InteractionOriginScreenPos = PlayerScreenPos;
			InteractionOriginScreenPos.X = 0.0;

			FVector Origin;
			FVector Direction;
			SceneView::DeprojectScreenToWorld_Relative(
				Player,
				InteractionOriginScreenPos,
				Origin, Direction
			);

			FVector InteractionWorldPos = Math::LinePlaneIntersection(
					Origin, Origin + Direction,
					Player.ActorLocation, Player.ViewRotation.ForwardVector);
			InteractionWorldPos += Player.ViewRotation.RightVector * 50.0;

			SetActorLocationAndRotation(InteractionWorldPos,
				FRotator::MakeFromX(-Player.ViewRotation.RightVector));
		}

		{
			FVector2D InteractionWidgetScreenPos = PlayerScreenPos;
			InteractionWidgetScreenPos.X = 0.05;

			FVector Origin;
			FVector Direction;
			SceneView::DeprojectScreenToWorld_Relative(
				Player,
				InteractionWidgetScreenPos,
				Origin, Direction
			);

			FVector InteractionWidgetPos = Math::LinePlaneIntersection(
					Origin, Origin + Direction,
					Player.ActorLocation, Player.ViewRotation.ForwardVector);
			InteractionWidgetPos.Z += 80.0;

			Interaction.WidgetVisualOffset = Interaction.WorldTransform.InverseTransformVector(
				InteractionWidgetPos - ActorLocation);
		}

	}
};