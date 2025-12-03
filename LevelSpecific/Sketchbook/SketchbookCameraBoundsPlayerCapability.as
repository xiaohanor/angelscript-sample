class USketchbookCameraBoundsPlayerCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);

	default DebugCategory = n"Movement";

	default TickGroup = EHazeTickGroup::LastMovement;
	default TickGroupOrder = 100;

	float BlockMargin = 0.1;

	UPlayerMovementComponent MoveComp;
	USteppingMovementData Movement;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!ShouldBeBlocked())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!ShouldBeBlocked())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		FCameraFrustumBoundarySettings Settings;
		Settings.MinimumDistanceFromFrustum = 20;
		Boundary::ApplyMovementConstrainToCameraFrustum(Player, Settings, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Boundary::ClearMovementConstrainToCameraFrustum(Player, this);
	}

	bool ShouldBeBlocked() const
	{
		auto Cam = Game::Zoe.GetCurrentlyUsedCamera();
		if(Cast<AStaticCameraActor>(Cam.Owner) == nullptr)
			return false;

		FVector2D ScreenRelativePos;
		SceneView::ProjectWorldToViewpointRelativePosition(Player, Player.ActorLocation, ScreenRelativePos);

		if(ScreenRelativePos.X < 0 + BlockMargin && MoveComp.Velocity.X > 0)
			return true;
		
		if(ScreenRelativePos.X > 1 - BlockMargin && MoveComp.Velocity.X < 0)
			return true;

		return false;
	}
};