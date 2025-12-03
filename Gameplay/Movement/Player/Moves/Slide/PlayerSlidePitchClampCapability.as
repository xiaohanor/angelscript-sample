class UPlayerSlidePitchClampCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Camera);
	default CapabilityTags.Add(PlayerMovementTags::CoreMovement);
	default CapabilityTags.Add(PlayerMovementTags::Slide);
	default CapabilityTags.Add(PlayerSlideTags::SlideCamera);
	default CapabilityTags.Add(PlayerSlideTags::SlideCameraPitchConstraint);

	default DebugCategory = n"Movement";

	default TickGroup = EHazeTickGroup::LastMovement;
	default TickGroupOrder = 148;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UPlayerMovementPerspectiveModeComponent PerspectiveModeComp;
	UCameraUserComponent CameraUserComp;
	UPlayerSlideComponent SlideComp;
	UPlayerGrappleComponent GrappleComp;
	UPlayerMovementComponent MoveComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		GrappleComp = UPlayerGrappleComponent::Get(Player);
		PerspectiveModeComp = UPlayerMovementPerspectiveModeComponent::Get(Player);
		SlideComp = UPlayerSlideComponent::Get(Player);
		CameraUserComp = UCameraUserComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!SlideComp.IsSlideActive() && GrappleComp.Data.SlideGrappleVariant != ESlideGrappleVariants::Grounded)
			return false;

		if (Player.HasAnyActivePointOfInterest())
			return false;

		if (!MoveComp.IsOnAnyGround())
			return false;
			
		if (!PerspectiveModeComp.IsCameraBehaviorEnabled())
			return false;

		if (!CameraUserComp.IsUsingDefaultCamera())
			return false;

		if (Player.IsPlayerDead())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!SlideComp.IsSlideActive() && GrappleComp.Data.SlideGrappleVariant != ESlideGrappleVariants::Grounded)
			return true;

		if (Player.HasAnyActivePointOfInterest())
			return true;
		
		if (!MoveComp.IsOnAnyGround())
			return true;

		if (!PerspectiveModeComp.IsCameraBehaviorEnabled())
			return true;

		if (!CameraUserComp.IsUsingDefaultCamera())
			return true;

		if (Player.IsPlayerDead())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		SlideComp.AcceleratedLowerPitchClamp.SnapTo(0, 0);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		UCameraSettings::GetSettings(Player).Clamps.Clear(FInstigator(SlideComp, n"SlideClampConstraint"));
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		SlideComp.CalculateAndClampPitch(DeltaTime);
	}
};