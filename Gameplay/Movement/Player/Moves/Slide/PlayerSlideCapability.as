class UPlayerSlideCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(PlayerMovementTags::CoreMovement);
	default CapabilityTags.Add(PlayerMovementTags::Slide);	
	default CapabilityTags.Add(PlayerSlideTags::SlideMovement);

	default DebugCategory = n"Movement";
	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 100;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UPlayerSlideComponent SlideComp;
	UPlayerAirMotionComponent AirMotionComp;
	UPlayerAirDashComponent AirDashComp;

	float WantedSlideVelocity = 0.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SlideComp = UPlayerSlideComponent::GetOrCreate(Player);
		AirMotionComp = UPlayerAirMotionComponent::GetOrCreate(Player);
		AirDashComp = UPlayerAirDashComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (SlideComp.IsSlideActive())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!SlideComp.IsSlideActive())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilities(CapabilityTags::FindOtherPlayer, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(CapabilityTags::FindOtherPlayer, this);

		AirMotionComp.VelocityConstraint.Clear(this);
		AirDashComp.DirectionConstraint.Clear(this);

		//Safety clear incase we snap clamps via respawn and somehow bypass the Safety checks in SlideComp/SlidePitchClamp deactivation
		UCameraSettings::GetSettings(Player).Clamps.Clear(FInstigator(SlideComp, n"SlideClampConstraint"));
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FActiveSlideInstance SlideInstance = SlideComp.GetSlideInstance();
		FSlideParameters SlideParams = SlideComp.GetSlideParameters();

		if (!SlideInstance.bIsTemporarySlide
			&& SlideParams.SlideType != ESlideType::Freeform
			&& SlideComp.Settings.bKeepSlideVelocityInAir
			&& SlideComp.bHasSlidOnGround
			&& HasControl())
		{
			// Constrain the velocity in air motion so it follows the slide
			FSlideSlopeData SlopeData = SlideComp.GetSlideSlopeData();

			if (!AirDashComp.IsAirDashing())
			{
				float CurrentSlideVelocity = Player.ActorVelocity.DotProduct(SlopeData.FacingForward);

				WantedSlideVelocity = SlideComp.Settings.SlideTargetSpeed * SlideComp.Settings.AirMotionTargetSpeedMultiplier * SlopeData.RubberBandMultiplier;
				if (!SlideComp.Settings.bSlowdownToTargetSpeedInAir && !AirDashComp.IsAirDashing())
					WantedSlideVelocity = Math::Max(WantedSlideVelocity, CurrentSlideVelocity);
				WantedSlideVelocity = Math::Clamp(WantedSlideVelocity, SlideComp.Settings.SlideMinimumSpeed * SlopeData.RubberBandMultiplier, SlideComp.Settings.SlideMaximumSpeed * SlopeData.RubberBandMultiplier);

				CurrentSlideVelocity = Math::FInterpConstantTo(
					CurrentSlideVelocity, WantedSlideVelocity,
					DeltaTime, SlideComp.Settings.TargetInterpAcceleration
				);

				FAirMotionVelocityConstraint AirMotionConstraint;
				AirMotionConstraint.BaseVelocity = SlopeData.FacingForward * CurrentSlideVelocity;

				if (SlideComp.Settings.bUseSidewaysMovementSpeedInAir)
				{
					AirMotionConstraint.bOverrideLateralSpeed = true;
					AirMotionConstraint.LateralSpeed = SlideComp.Settings.SidewaysSpeed * SlideComp.Settings.AirMotionSildewaysMovementSpeedMultiplier;
					AirMotionConstraint.LateralAcceleration = SlideComp.Settings.SidewaysAcceleration * SlideComp.Settings.AirMotionSildewaysMovementSpeedMultiplier;
				}

				AirMotionComp.VelocityConstraint.Apply(AirMotionConstraint, this);
			}

			FAirDashDirectionConstraint AirDashConstraint;
			AirDashConstraint.Direction = SlopeData.FacingForward;
			AirDashConstraint.MaxAngleRadians = Math::DegreesToRadians(SlideComp.Settings.AirDashMaximumForwardDeviationAngle);

			AirDashComp.DirectionConstraint.Apply(AirDashConstraint, this);

			Player.SetMovementFacingDirection(SlopeData.FacingForward);
		}
		else
		{
			// Should not have a velocity constraint in freeform or temporary slides
			AirMotionComp.VelocityConstraint.Clear(this);
			AirDashComp.DirectionConstraint.Clear(this);
		}
	}
};
