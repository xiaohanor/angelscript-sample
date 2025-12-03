class UPlayerSlideCameraAssistCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Camera);
	default CapabilityTags.Add(PlayerMovementTags::CoreMovement);
	default CapabilityTags.Add(PlayerMovementTags::Slide);
	default CapabilityTags.Add(PlayerSlideTags::SlideCamera);
	default CapabilityTags.Add(PlayerSlideTags::SlideCameraAssist);

	default DebugCategory = n"Movement";

	default TickGroup = EHazeTickGroup::LastMovement;
	default TickGroupOrder = 149;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UPlayerMovementComponent MoveComp;
	UPlayerMovementPerspectiveModeComponent PerspectiveModeComp;
	UCameraUserComponent CameraUserComp;
	UPlayerSlideComponent SlideComp;
	UPlayerGrappleComponent GrappleComp;

	float PostInputTimer = 0;
	bool bRecentInputDetected = false;

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
		if (Player.HasAnyActivePointOfInterest())
			return false;

		if(!SlideComp.IsSlideActive() && GrappleComp.Data.SlideGrappleVariant != ESlideGrappleVariants::Grounded)
			return false;

		if (!MoveComp.IsOnAnyGround())
			return false;
			
		if (!PerspectiveModeComp.IsCameraBehaviorEnabled())
			return false;

		if (!CameraUserComp.IsUsingDefaultCamera())
			return false;

		if (Player.IsPlayerDead())
			return false;

		if (PostInputTimer < SlideComp.Settings.ASSIST_INPUT_COOLDOWN)
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
		
		if (!PerspectiveModeComp.IsCameraBehaviorEnabled())
			return true;

		if (Player.IsPlayerDead())
			return true;

		if (!CameraUserComp.IsUsingDefaultCamera())
			return true;

		if (!GetAttributeVector2D(AttributeVectorNames::CameraDirection).IsNearlyZero())
			return true;

		if (!MoveComp.IsOnAnyGround())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if(IsActive() || !SlideComp.IsSlideActive())
			return;

		if ((!bRecentInputDetected || (bRecentInputDetected && PostInputTimer <= SlideComp.Settings.ASSIST_INPUT_COOLDOWN))
				 && !GetAttributeVector2D(AttributeVectorNames::CameraDirection).IsNearlyZero())
		{
			bRecentInputDetected = true;
			PostInputTimer = 0;
		}
		else if (MoveComp.IsOnAnyGround())
			PostInputTimer += DeltaTime;
		else
			PostInputTimer = 0;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		SlideComp.AcceleratedDesiredRotation.SnapTo(CameraUserComp.ControlRotation, FRotator::ZeroRotator);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		PostInputTimer = 0;
		bRecentInputDetected = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		SlideComp.AcceleratedDesiredRotation.AccelerateTo(SlideComp.CalculateVelocityBasedSlopeDesiredRotation(), SlideComp.Settings.ROTATION_ACCELERATION_DURATION, DeltaTime);
		CameraUserComp.SetDesiredRotation(SlideComp.AcceleratedDesiredRotation.Value, this);
	}
};