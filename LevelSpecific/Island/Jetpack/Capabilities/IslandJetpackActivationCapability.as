struct FIslandJetpackActivationDeactivationParams
{
	bool bRanOutOfFuel;
}

class UIslandJetpackActivationCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(PlayerMovementTags::Jump);
	default CapabilityTags.Add(PlayerMovementTags::AirJump);
	default CapabilityTags.Add(BlockedWhileIn::WallScramble);
	default CapabilityTags.Add(BlockedWhileIn::WallRun);
	default CapabilityTags.Add(BlockedWhileIn::Swimming);
	default CapabilityTags.Add(BlockedWhileIn::Grapple);
	default CapabilityTags.Add(BlockedWhileIn::Ladder);
	default CapabilityTags.Add(BlockedWhileIn::PoleClimb);
	default CapabilityTags.Add(BlockedWhileIn::Perch);
	default CapabilityTags.Add(BlockedWhileIn::LedgeGrab);
	default CapabilityTags.Add(BlockedWhileIn::Swing);
	default CapabilityTags.Add(BlockedWhileIn::Vault);
	default CapabilityTags.Add(BlockedWhileIn::LedgeMantle);
	default CapabilityTags.Add(IslandJetpack::Jetpack);

	default BlockExclusionTags.Add(n"ExcludeAirJumpAndDash");

	default DebugCategory = IslandJetpack::Jetpack;

	default TickGroup = EHazeTickGroup::Input;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	AIslandJetpack Jetpack;

	UIslandJetpackComponent JetpackComp;
	UCameraUserComponent CameraUserComp;
	UPlayerJumpComponent JumpComp;
	UPlayerSlideComponent SlideComp;

	UPlayerMovementComponent MoveComp;

	FHazeAcceleratedQuat AccMeshRotation;

	UIslandJetpackSettings JetpackSettings;

	bool bHasHeldJumpSinceJump = false;
	bool bIsShowingCancelPrompt = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		JetpackComp = UIslandJetpackComponent::Get(Player);
		Jetpack = JetpackComp.Jetpack;

		CameraUserComp = UCameraUserComponent::Get(Player);
		JumpComp = UPlayerJumpComponent::Get(Player);
		SlideComp = UPlayerSlideComponent::Get(Player);
		JumpComp.OnJump.AddUFunction(this, n"OnPlayerJumped");

		MoveComp = UPlayerMovementComponent::Get(Player);

		JetpackSettings = UIslandJetpackSettings::GetSettings(Player);
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnPlayerJumped(AHazePlayerCharacter InPlayer)
	{
		bHasHeldJumpSinceJump = true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(MoveComp.IsOnWalkableGround()
		|| SlideComp.bIsSliding)
			return false;

		if(!JetpackComp.IsOn())
			return false;

		// If jetpack isn't currently active and we have activated externally from a dash then we ignore to check the charge because we always want to do the dash if we have tiny sliver of charge left.
		bool bActivateRequestFromDash = (JetpackComp.bActivatedExternally && JetpackComp.bDashing);
		if(!bActivateRequestFromDash && JetpackComp.HasEmptyCharge())
			return false;

		if(WasActionStarted(ActionNames::MovementJump))
			return true;

		if(bHasHeldJumpSinceJump
		&& MoveComp.VerticalSpeed < 0)
			return true;

		if(JetpackComp.bActivatedExternally)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FIslandJetpackActivationDeactivationParams& Params) const
	{
		if(!JetpackComp.IsOn())
		{
			Params.bRanOutOfFuel = false;
			return true;
		}

		if(WasActionStarted(ActionNames::Cancel) && !JetpackComp.InPhasableWallSpline())
		{
			Params.bRanOutOfFuel = false;
			return true;
		}

		if(!JetpackComp.bDashing && JetpackComp.HasEmptyCharge())
		{
			Params.bRanOutOfFuel = true;
			return true;
		}

		if(MoveComp.IsOnAnyGround())
		{
			Params.bRanOutOfFuel = false;
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.ConsumeAirJumpUsage();

		JetpackComp.ChangeChargeLevel(-JetpackSettings.BoostActivationDepletion, false);
		Player.BlockCapabilities(PlayerMovementTags::AirDash, this);
		Player.BlockCapabilities(PlayerMovementTags::Perch, this);

		AccMeshRotation.SnapTo(Player.MeshOffsetComponent.ComponentQuat);

		bHasHeldJumpSinceJump = false;

		UIslandJetpackEventHandler::Trigger_JetpackActivated(Jetpack);

		if(!SceneView::IsFullScreen())
		{
			Player.ShowCancelPrompt(this);
			bIsShowingCancelPrompt = true;
		}

		if(JetpackComp.bActivatedExternally)
		{
			JetpackComp.bHasInitialBoost = false;
			JetpackComp.bActivatedExternally = false;
		}
		JetpackComp.bThrusterIsOn = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FIslandJetpackActivationDeactivationParams Params)
	{
		Player.StopForceFeedback(this);
		Player.UnblockCapabilities(PlayerMovementTags::AirDash, this);
		Player.UnblockCapabilities(PlayerMovementTags::Perch, this);

		Player.MeshOffsetComponent.FreezeRotationAndLerpBackToParent(this, 0.5, EInstigatePriority::Normal);

		UIslandJetpackEventHandler::Trigger_JetpackDeactivated(Jetpack);

		//UIslandJetpackEventHandler::Trigger_ThrusterCancel(Jetpack);

		if(!SceneView::IsFullScreen())
			Player.RemoveCancelPromptByInstigator(this);

		if(Params.bRanOutOfFuel)
		{
			if(JetpackSettings.bReplenishAirJumpAfterRunningOutOfFuel)
				Player.ResetAirJumpUsage();
			if(JetpackSettings.bReplenishAirDashAfterRunningOutOfFuel)
				Player.ResetAirDashUsage();
		}

		JetpackComp.bThrusterIsOn = false;
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if(bHasHeldJumpSinceJump)
		{
			if(!IsActioning(ActionNames::MovementJump))
				bHasHeldJumpSinceJump = false;
		}
		else
		{
			if(Player.IsAnyCapabilityActive(PlayerSlideTags::SlideJump)
			|| Player.IsAnyCapabilityActive(PlayerWallRunTags::WallRunJump)
			|| Player.IsAnyCapabilityActive(PlayerGrappleTags::GrappleLaunch))
			{
				if(IsActioning(ActionNames::MovementJump))
					bHasHeldJumpSinceJump = true;
			}
		}

		TEMPORAL_LOG(Player, "Jetpack")
			.Value("Has Held Jump Since Jump", bHasHeldJumpSinceJump)
			.Value("Is On", JetpackComp.IsOn())
		;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!JetpackComp.InPhasableWallSpline())
		{
			if(!SceneView::IsFullScreen() && !bIsShowingCancelPrompt)
			{
				Player.ShowCancelPrompt(this);
				bIsShowingCancelPrompt = true;
			}
		}
		else if (bIsShowingCancelPrompt)
		{
			bIsShowingCancelPrompt = false;
			Player.RemoveCancelPromptByInstigator(this);
		}
		// FVector2D RawInput = GetAttributeVector2D(AttributeVectorNames::MovementRaw);

		// FRotator TargetRotation = FRotator(-RawInput.X * JetpackSettings.TiltMax, 0, RawInput.Y * JetpackSettings.TiltMax);
		// TargetRotation = Player.ActorTransform.TransformRotation(TargetRotation);
		// AccMeshRotation.AccelerateTo(TargetRotation.Quaternion(), JetpackSettings.TiltTowardsInputSpeed, DeltaTime);
		// Player.MeshOffsetComponent.SnapToRotation(this, AccMeshRotation.Value, EInstigatePriority::Normal);
	}
};