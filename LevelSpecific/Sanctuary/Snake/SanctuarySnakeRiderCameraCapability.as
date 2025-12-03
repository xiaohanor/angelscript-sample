class USanctuarySnakeRiderCameraCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(n"SanctuarySnake");

	default TickGroup = EHazeTickGroup::AfterPhysics; // Movement world up doesnt change until physics so we cant do lastmovement
	default TickGroupOrder = MovementInput::CapabilityTickGroupOrder;

	ASanctuarySnake Snake;

	UCameraUserComponent CameraUserComponent;

	USanctuarySnakeComponent SanctuarySnakeComponent;

	FVector YawAxis;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		CameraUserComponent = UCameraUserComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		auto SnakeRiderComponent = USanctuarySnakeRiderComponent::Get(Player);
		Snake = SnakeRiderComponent.Snake;

		SanctuarySnakeComponent = USanctuarySnakeComponent::Get(Snake);
		YawAxis = SanctuarySnakeComponent.WorldUp;
		CameraUserComponent.SetYawAxis(YawAxis, this);

		Player.ActivateCamera(Snake.RiderCamera, 1.0, this);
//		Player.ActivateCamera(Snake.Camera, 1.0, this);
		Player.ApplyViewSizeOverride(this, EHazeViewPointSize::Fullscreen);

		Player.OtherPlayer.ApplyAiming2DPlaneConstraint(FVector::UpVector, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.DeactivateCameraByInstigator(this);
		Player.ClearViewSizeOverride(this);

		Player.OtherPlayer.ClearAiming2DConstraint(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		YawAxis = YawAxis.SlerpTowards(Snake.Pivot.UpVector, 3.0 * DeltaTime);
//		YawAxis = YawAxis.SlerpTowards(SanctuarySnakeComponent.WorldUp, 3.0 * DeltaTime);

		CameraUserComponent.SetYawAxis(YawAxis, this);

//		CameraUserComponent.SetYawAxis(Snake.Pivot.UpVector);
/*
		if (Player.CurrentlyUsedCamera == Snake.RiderCamera)
			CameraUserComponent.SetYawAxis(Snake.Pivot.UpVector);
		else
			CameraUserComponent.SetYawAxis(CameraUserComponent.ViewRotation.UpVector);
*/

//		Debug::DrawDebugLine(Snake.ActorLocation, Snake.ActorLocation + YawAxis * 800.0, FLinearColor::Blue, 50.0, 0.0);

	}
};