class USkylineConstrainToScreenMovementResolver : USteppingMovementResolver
{
	const float HeightConstraint = 0.05;
	const FVector2D ScreenSpaceHeightRange = FVector2D(HeightConstraint, 1.0 - HeightConstraint);
	const float WidthConstraint = 0.05;
	const FVector2D ScreenSpaceWidthRange = FVector2D(WidthConstraint, 1.0 - WidthConstraint);

	AHazePlayerCharacter Player;
	USkylineConstrainToScreenPlayerComponent ConstrainComp;
	UPlayerMovementComponent MoveComp;
	bool bIsConstrainedX = false;
	bool bIsConstrainedY = false;
	
	void PrepareResolver(const UBaseMovementData Movement) override
	{
		Super::PrepareResolver(Movement);
		Player = Cast<AHazePlayerCharacter>(Owner);
		ConstrainComp = USkylineConstrainToScreenPlayerComponent::GetOrCreate(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
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

#if !RELEASE
		TEMPORAL_LOG(Owner, "Constrain to Screen Resolver")
			.Value("Constrained X", bIsConstrainedX)
			.Value("Constrained Y", bIsConstrainedY)
			.Sphere("Target Location", TargetLocation, 50, FLinearColor::Black, 10)
		;
#endif
		bIsConstrainedX = false;
		bIsConstrainedY = false;

		if(SceneView::IsInView(Player, TargetLocation, ScreenSpaceWidthRange, ScreenSpaceHeightRange))
			return;

		if (MoveComp.IsFalling())
		{
			if (ConstrainComp.GetKillPlayerWhenFallingOut() && MoveComp.Velocity.DotProduct(MoveComp.GravityDirection) > 0.0 )
			{
				if (!ConstrainComp.GetRequestedKillPlayer())
					Timer::SetTimer(this, n"DelayedRequestKillPlayer", 1.0);
			}
			return;
		}

		if(Player.IsPlayerDead() || Player.IsPlayerRespawning())
			return;

		// Other player might try to drag camera & us along with it. 
		// Then we can end up inside all sorts of whacky states.
		// Make sure we don't move if we're not trying to.
		if (MoveComp.Velocity.Size() < KINDA_SMALL_NUMBER)
			return;

		SceneView::ProjectWorldToViewpointRelativePosition(Player, TargetLocation, ViewPortRelativeTargetLocation);
		FVector2D PlayerScreenLocation;
		SceneView::ProjectWorldToViewpointRelativePosition(Player, Player.ActorLocation, PlayerScreenLocation);

		FVector2D FromPlayerToCenter = FVector2D(0.5, 0.5) - PlayerScreenLocation;
		FVector2D FromPlayerToTarget = ViewPortRelativeTargetLocation - PlayerScreenLocation;
		if (FromPlayerToCenter.DotProduct(FromPlayerToTarget) > 0.0)
			return; // Allow players to go normally towards center of screen, even if out of allowed bounds.

		if (ConstrainComp.GetIsConstrainedHorizontal())
		{
			ViewPortRelativeTargetLocation.X = Math::Clamp(ViewPortRelativeTargetLocation.X, ScreenSpaceWidthRange.X, ScreenSpaceWidthRange.Y);
			bIsConstrainedX = true;
		}
		if (ConstrainComp.GetIsConstrainedVertical())
		{
			ViewPortRelativeTargetLocation.Y = Math::Clamp(ViewPortRelativeTargetLocation.Y, ScreenSpaceHeightRange.X, ScreenSpaceHeightRange.Y);
			bIsConstrainedY = true;
		}

		FVector TargetLocationOrigin, TargetLocationDirection;
		FVector CenterLocationOrigin, CenterLocationDirection;

		SceneView::DeprojectScreenToWorld_Relative(Player, ViewPortRelativeTargetLocation, TargetLocationOrigin, TargetLocationDirection);
		SceneView::DeprojectScreenToWorld_Relative(Player, ViewPortRelativeTargetLocation, CenterLocationOrigin, CenterLocationDirection);

		FPlane PlayerCameraPlane = FPlane(TargetLocation, -CenterLocationDirection);

		FVector ConstrainedTargetLocation = Math::RayPlaneIntersection(TargetLocationOrigin, TargetLocationDirection, PlayerCameraPlane);
		FVector DeltaToRemove = TargetLocation - ConstrainedTargetLocation;

		IterationState.DeltaToTrace -= DeltaToRemove;

#if !RELEASE
		TEMPORAL_LOG(Owner, "Constrain to Screen Resolver")
			.Value("Viewport Relative Location", ViewPortRelativeTargetLocation)
			.Box("Player Camera Plane", IterationState.CurrentLocation, FVector(10, 2000, 2000), PlayerCameraPlane.Normal.ToOrientationRotator(), FLinearColor::Red, 50)
			.Sphere("Constrained Target Location", ConstrainedTargetLocation, 50, FLinearColor::White, 10)
			.DirectionalArrow("Delta to Remove", IterationState.CurrentLocation, DeltaToRemove, 20, 80, FLinearColor::Purple)
		;
#endif
	}

	UFUNCTION()
	private void DelayedRequestKillPlayer()
	{
		if (MoveComp.IsFalling() && ConstrainComp.GetKillPlayerWhenFallingOut() && MoveComp.Velocity.DotProduct(MoveComp.GravityDirection) > 0.0 )
			ConstrainComp.SetRequestedKillPlayer(true);
	}
}