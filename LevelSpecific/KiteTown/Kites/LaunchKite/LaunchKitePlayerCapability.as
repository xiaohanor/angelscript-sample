class ULaunchKitePlayerCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(KiteTags::Kite);
	default CapabilityTags.Add(KiteTags::LaunchKite);

	default TickGroup = EHazeTickGroup::BeforeMovement;

	UPlayerTargetablesComponent TargetablesComp;

	ULaunchKitePlayerComponent KitePlayerComp;
	ALaunchKite Kite;
	ULaunchKitePointComponent CurrentLaunchPointComp;

	bool bTubeEntered = false;
	bool bTubeExited = false;

	float EnterTubeThreshold = 800.0;
	float ExitTubeThreshold = 1600.0;

	float PlayerPitch = 0.0;

	bool bLaunchFFPlayed = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		KitePlayerComp = ULaunchKitePlayerComponent::Get(Player);
		TargetablesComp = UPlayerTargetablesComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FLaunchKiteActivationParams& ActivationParams) const
	{
		if (KitePlayerComp.bLaunched)
			return false;

		ULaunchKitePointComponent PointComp = KitePlayerComp.LaunchKitePointComp;
		if (PointComp == nullptr)
			return false;

		ActivationParams.LaunchPointComp = PointComp;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (bTubeExited)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FLaunchKiteActivationParams ActivationParams)
	{
		CurrentLaunchPointComp = ActivationParams.LaunchPointComp;
		Kite = Cast<ALaunchKite>(CurrentLaunchPointComp.Owner);

		Player.ResetAirJumpUsage();
		Player.ResetAirDashUsage();

		bTubeEntered = false;
		bTubeExited = false;
		PlayerPitch = 0.0;

		bLaunchFFPlayed = false;

		Player.BlockCapabilities(PlayerMovementTags::AirDash, this);
		Player.BlockCapabilities(PlayerMovementTags::AirJump, this);
		Player.BlockCapabilitiesExcluding(CapabilityTags::GameplayAction, PlayerMovementExclusionTags::ExcludeGrapple, this);

		SpeedEffect::RequestSpeedEffect(Player, 2.0, this, EInstigatePriority::High);

		Player.ApplyCameraSettings(KitePlayerComp.CamSettings, 1.0, this, EHazeCameraPriority::VeryHigh);

		FHazePointOfInterestFocusTargetInfo PoIFocus;
		PoIFocus.SetFocusToComponent(Kite.LaunchPointComp);
		PoIFocus.LocalOffset = FVector(5000.0, 0.0, 0.0);

		FApplyPointOfInterestSettings PoiSettings;
		PoiSettings.Duration = Kite.PoiBlendTime;
		Player.ApplyPointOfInterest(this, PoIFocus, PoiSettings);

		UMovementGravitySettings::SetGravityScale(Player, 0.0, this);

		Kite.OnGrappleStarted.Broadcast(Player);
		ULaunchKiteEffectEventHandler::Trigger_GrappleStarted(Kite);
		ULaunchKitePlayerEffectEventHandler::Trigger_GrappleStarted(Kite);

		UKiteTownVOEffectEventHandler::Trigger_LaunchGrappleStarted(Game::Mio, KiteTown::GetVOEffectEventParams(Player));
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(PlayerMovementTags::AirDash, this);
		Player.UnblockCapabilities(PlayerMovementTags::AirJump, this);
		Player.UnblockCapabilities(CapabilityTags::GameplayAction,this);
		
		SpeedEffect::ClearSpeedEffect(Player, this);

		Player.StopCameraShakeByInstigator(this, false);
		Player.ClearPointOfInterestByInstigator(this);

		Player.ClearCameraSettingsByInstigator(this, 2.0);

		UMovementGravitySettings::ClearGravityScale(Player, this);

		Player.MeshOffsetComponent.ResetOffsetWithLerp(this, 0.2);

		// Player.StopSlotAnimation(BlendTime = 0.2);

		Kite.OnPlayerExit.Broadcast(Player);
		ULaunchKiteEffectEventHandler::Trigger_PlayerExit(Kite);
		ULaunchKitePlayerEffectEventHandler::Trigger_ExitTunnel(Player);
		UKiteTownVOEffectEventHandler::Trigger_LaunchExitTunnel(Game::Mio, KiteTown::GetVOEffectEventParams(Player));

		Player.ClearMovementInput(this);

		if (Kite.bTriggerFlight)
		{
			KitePlayerComp.LaunchKitePointComp = CurrentLaunchPointComp;
			KitePlayerComp.bLaunched = true;
		}
		else
		{
			KitePlayerComp.LaunchKitePointComp = nullptr;
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Player.ApplyMovementInput(FVector::ZeroVector, this, EInstigatePriority::High);

		float DistanceToPlayer = Player.ActorLocation.Distance(Kite.LaunchPointComp.WorldLocation);

		if (DistanceToPlayer <= EnterTubeThreshold)
			EnterTube();

		float TargetPitch = Kite.bFlipDirection ? -Kite.Pitch : Kite.Pitch;
		PlayerPitch = Math::FInterpTo(PlayerPitch, TargetPitch, DeltaTime, 10.0);

		Player.MeshOffsetComponent.SnapToRotation(this, FQuat(FRotator(PlayerPitch, Player.ActorRotation.Yaw, 0.0)));

		FVector DirToPlayer = (Player.ActorLocation - Kite.LaunchPointComp.WorldLocation).GetSafeNormal();
		float Dot = Kite.LaunchPointComp.ForwardVector.DotProduct(DirToPlayer);

		if (DistanceToPlayer >= ExitTubeThreshold && Dot > 0.0)
			bTubeExited = true;

		Player.SetFrameForceFeedback(0.1, 0.1, 0.0, 0.0);

		if (bTubeEntered)
		{
			if (DistanceToPlayer >= 1000.0)
			{
				bLaunchFFPlayed = true;
				Player.PlayForceFeedback(KitePlayerComp.LaunchFF, false, true, this);
			}
		}
	}

	void EnterTube()
	{
		if (bTubeEntered)
			return;

		bTubeEntered = true;
		Player.PlaySlotAnimation(Animation = KitePlayerComp.LaunchAnim, BlendOutTime = 0.2, PlayRate = 1.0, StartTime = 0.0);

		Kite.OnPlayerEnter.Broadcast(Player);
		ULaunchKiteEffectEventHandler::Trigger_PlayerEnter(Kite);
		ULaunchKitePlayerEffectEventHandler::Trigger_EnterTunnel(Player);
		UKiteTownVOEffectEventHandler::Trigger_LaunchEnterTunnel(Game::Mio, KiteTown::GetVOEffectEventParams(Player));
	}
}

struct FLaunchKiteActivationParams
{
	ULaunchKitePointComponent LaunchPointComp;
}