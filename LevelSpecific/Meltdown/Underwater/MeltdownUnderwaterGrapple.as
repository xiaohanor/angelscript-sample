class AMeltdownUnderwaterGrapple : AGrappleLaunchPoint
{
	default PrimaryActorTick.TickGroup = ETickingGroup::TG_PostPhysics;

	default GrappleLaunchPoint.bStartDisabled = true;

	UPROPERTY(EditAnywhere)
	float ForwardOffset = 3000.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (GrappleLaunchPoint.bIsPlayerGrapplingToPoint[0] || GrappleLaunchPoint.bIsPlayerGrapplingToPoint[1])
			return;

		// Get the position of the player on the screen
		FVector2D PlayerScreenPos;
		SceneView::ProjectWorldToViewpointRelativePosition(
			Game::Zoe, Game::Zoe.ActorLocation, PlayerScreenPos
		);

		{
			FVector2D InteractionOriginScreenPos = PlayerScreenPos;
			InteractionOriginScreenPos.Y = 0.1;

			FVector Origin;
			FVector Direction;
			SceneView::DeprojectScreenToWorld_Relative(
				Game::Mio,
				InteractionOriginScreenPos,
				Origin, Direction
			);

			FVector InteractionWorldPos = Math::LinePlaneIntersection(
					Origin, Origin + Direction,
					Game::Mio.ActorLocation + Game::Mio.ViewRotation.ForwardVector.GetSafeNormal2D() * ForwardOffset,
					Game::Mio.ViewRotation.ForwardVector.GetSafeNormal2D());

			SetActorLocation(InteractionWorldPos);
		}
	}
}