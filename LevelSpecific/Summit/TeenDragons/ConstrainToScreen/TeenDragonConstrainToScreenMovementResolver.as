class UTeenDragonConstrainToScreenSteppingMovementResolver : USteppingMovementResolver
{
	const FVector2D ScreenSpaceHeightRange = FVector2D(0.0, 0.98);
	const FVector2D ScreenSpaceWidthRange = FVector2D(0.01, 0.99);

	AHazePlayerCharacter Player;
	
	void PrepareResolver(const UBaseMovementData Movement) override
	{
		Super::PrepareResolver(Movement);
		
		Player = Cast<AHazePlayerCharacter>(Owner);
	}


	void HandleIterationDeltaMovementImpact(FMovementHitResult& MovementHit) override
	{
		ConstrainDeltaToWithinScreen();
		Super::HandleIterationDeltaMovementImpact(MovementHit);
	}

	void HandleIterationDeltaMovementWithoutImpact() override
	{
		ConstrainDeltaToWithinScreen();
		Super::HandleIterationDeltaMovementWithoutImpact();
	}

	private void ConstrainDeltaToWithinScreen()
	{
		FVector TargetLocation = IterationState.CurrentLocation + IterationState.DeltaToTrace;

		FVector2D ViewPortRelativeTargetLocation;

		if(SceneView::IsInView(Player, TargetLocation, ScreenSpaceWidthRange, ScreenSpaceHeightRange))
			return;

		if(Player.IsPlayerDead()
		|| Player.IsPlayerRespawning())
			return;

		SceneView::ProjectWorldToViewpointRelativePosition(Player, TargetLocation, ViewPortRelativeTargetLocation);

		ViewPortRelativeTargetLocation.X = Math::Clamp(ViewPortRelativeTargetLocation.X, ScreenSpaceWidthRange.X, ScreenSpaceWidthRange.Y);
		ViewPortRelativeTargetLocation.Y = Math::Clamp(ViewPortRelativeTargetLocation.Y, ScreenSpaceHeightRange.X, ScreenSpaceHeightRange.Y);

		FVector TargetLocationOrigin, TargetLocationDirection;
		FVector CenterLocationOrigin, CenterLocationDirection;

		SceneView::DeprojectScreenToWorld_Relative(Player, ViewPortRelativeTargetLocation, TargetLocationOrigin, TargetLocationDirection);
		SceneView::DeprojectScreenToWorld_Relative(Player, ViewPortRelativeTargetLocation, CenterLocationOrigin, CenterLocationDirection);

		FPlane PlayerCameraPlane = FPlane(TargetLocation, -CenterLocationDirection);

		FVector ConstrainedTargetLocation = Math::RayPlaneIntersection(TargetLocationOrigin, TargetLocationDirection, PlayerCameraPlane);
		FVector DeltaToRemove = TargetLocation - ConstrainedTargetLocation;

		IterationState.DeltaToTrace -= DeltaToRemove;

		TEMPORAL_LOG(Owner, "Constrain to Screen Resolver")
			.Value("Viewport Relative Location", ViewPortRelativeTargetLocation)
			.Box("Player Camera Plane", IterationState.CurrentLocation, FVector(10, 2000, 2000), PlayerCameraPlane.Normal.ToOrientationRotator(), FLinearColor::Red, 50)
			.Sphere("Target Location", TargetLocation, 50, FLinearColor::Black, 10)
			.Sphere("Constrained Target Location", ConstrainedTargetLocation, 50, FLinearColor::White, 10)
			.DirectionalArrow("Delta to Remove", IterationState.CurrentLocation, DeltaToRemove, 20, 80, FLinearColor::Purple)
		;
	}
}