class UPlayerGrappleEnterCameraCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(PlayerMovementTags::ContextualMovement);
	default CapabilityTags.Add(PlayerMovementTags::Grapple);

	default TickGroup = EHazeTickGroup::LastMovement;
	default TickGroupOrder = 180;

	default DebugCategory = n"Movement";

	UPlayerMovementComponent MoveComp;
	UPlayerMovementPerspectiveModeComponent PerspectiveModeComp;
	UPlayerGrappleComponent GrappleComp;
	UCameraUserComponent CameraUserComp;

	float ViewToGrappleDot;

	FVector InititalPivotOffset;

	FRotator DesiredViewRotationOffset = FRotator::ZeroRotator;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		CameraUserComp = UCameraUserComponent::Get(Owner);
		PerspectiveModeComp = UPlayerMovementPerspectiveModeComponent::Get(Player);
		GrappleComp = UPlayerGrappleComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!PerspectiveModeComp.IsCameraBehaviorEnabled())
			return false;

		if (GrappleComp.Data.GrappleState != EPlayerGrappleStates::GrappleEnter)
			return false;
		
		auto GrapplePoint = Cast<UGrapplePointBaseComponent>(GrappleComp.Data.CurrentGrapplePoint);
		if(GrapplePoint == nullptr)
			return false;

		if (GrapplePoint.bBlockCameraEffectsForPoint)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!PerspectiveModeComp.IsCameraBehaviorEnabled())
			return true;

		if (GrappleComp.Data.GrappleState != EPlayerGrappleStates::GrappleEnter)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilities(CameraTags::CameraChaseAssistance, this);
		
		//Calculate directional dot product to determine which direction to offset the camera
		FVector ViewToGrapplePoint = GrappleComp.Data.CurrentGrapplePoint.WorldLocation - Player.ViewLocation;
		FVector ViewToPlayer = Player.ActorLocation - Player.ViewLocation;
		float GrappleToPlayerDot = ViewToGrapplePoint.GetSafeNormal().DotProduct(ViewToPlayer.Rotation().RightVector);
		ViewToGrappleDot = GrappleToPlayerDot;

		InititalPivotOffset = UCameraSettings::GetSettings(Player).PivotOffset.GetValue();
		Player.ApplyBlendToCurrentView(GrappleComp.Settings.GrappleEnterDuration * GrappleComp.Settings.EnterCameraBlendInTimeMultiplier, PlayerGrappleEnterCameraBlendIn);

		UCameraSettings::GetSettings(Player).PivotLagMax.Apply(FVector(0,0,0), this);

		if(ViewToGrappleDot >= 0)
			GrappleComp.AnimData.EnterSide = ELeftRight::Right;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(CameraTags::CameraChaseAssistance, this);

		//Camera stuff
		Player.ApplyBlendToCurrentView(1, PlayerGrappleEnterCameraBlendOut);
		DesiredViewRotationOffset = FRotator::ZeroRotator;
		Player.ClearCameraSettingsByInstigator(this, 0.25);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		UpdatePivotOffset(DeltaTime);
		UpdateDesiredRotation(DeltaTime);
		UpdateIdealDistance(DeltaTime);
	}
	
	void UpdatePivotOffset(float DeltaTime)
	{
 		float TargetPivotOffset;

		if(ViewToGrappleDot >= 0)
			TargetPivotOffset = InititalPivotOffset.Y + GrappleComp.Settings.HorizontalPivotOffset;
		else
			TargetPivotOffset = InititalPivotOffset.Y - GrappleComp.Settings.HorizontalPivotOffset;

		UCameraSettings::GetSettings(Player).PivotOffset.Apply(FVector(InititalPivotOffset.X, TargetPivotOffset, GrappleComp.Settings.VerticalPivotOffset), this, 0, SubPriority = 20);
	}

	void UpdateDesiredRotation(float DeltaTime)
	{
		FVector WorldLocation = GrappleComp.Data.CurrentGrapplePoint.WorldLocation;
		FVector Direction = WorldLocation - Player.ViewLocation;

		FRotator Rotation = Direction.Rotation();
		Rotation.Pitch = CameraUserComp.GetDesiredRotation().Pitch;
		
		// NB: Disabled, don't think we need this and it's more smooth without
		// CameraUserComp.SetDesiredRotation(Rotation, this);
	}

	void UpdateIdealDistance(float DeltaTime)
	{
		float InitialIdealDistance = UCameraSettings::GetSettings(Player).IdealDistance.GetValue();
		float TargetIdealDistance = Math::Min(InitialIdealDistance, GrappleComp.Settings.MinEnterIdealDistance);

		UCameraSettings::GetSettings(Player).IdealDistance.Apply(TargetIdealDistance, this);
	}
};

asset PlayerGrappleEnterCameraBlendIn of UCameraDefaultBlend
{
	AlphaType = ECameraBlendAlphaType::Accelerated;
	bIncludeLocationVelocity = true;
	LocationVelocityCustomBlendType = ECameraDefaultBlendVelocityAlphaType::Accelerated;
}

asset PlayerGrappleEnterCameraBlendOut of UCameraDefaultBlend
{
	AlphaType = ECameraBlendAlphaType::Accelerated;
	bIncludeLocationVelocity = true;
	LocationVelocityCustomBlendType = ECameraDefaultBlendVelocityAlphaType::Accelerated;
}