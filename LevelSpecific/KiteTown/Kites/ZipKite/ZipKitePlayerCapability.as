class UZipKitePlayerCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(KiteTags::Kite);
	default CapabilityTags.Add(KiteTags::ZipKite);

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 4;
	default TickGroupSubPlacement = 8;

	UPlayerMovementComponent MoveComp;
	UPlayerTargetablesComponent TargetablesComp;
	UPlayerGrappleComponent GrappleComp;

	USweepingMovementData MoveData;

	UZipKitePlayerComponent ZipKitePlayerComp;
	AZipKite Kite;
	UZipKitePointComponent ZipComp;
	UHazeCrumbSyncedFloatComponent ZipSyncComp;

	bool bZipping = false;
	float CurrentZipDistance = 800.0;
	float ZipSpeed = 800.0;
	FHazeAcceleratedFloat AccZipSpeed;

	bool bSwingingUp = false;
	float SwingUpDuration = 1.125;
	float CurrentSwingUpTime = 0.0;

	bool bReachedTop = false;

	FVector SwingUpStartPoint = FVector::ZeroVector;

	bool bButtonMashActive = false;

	float AdditiveFov = 0.0;

	AZipKiteFocusActor FocusActor;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		ZipKitePlayerComp = UZipKitePlayerComponent::Get(Player);
		TargetablesComp = UPlayerTargetablesComponent::GetOrCreate(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
		GrappleComp = UPlayerGrappleComponent::GetOrCreate(Player);

		MoveData = MoveComp.SetupSweepingMovementData();

		FocusActor = SpawnActor(AZipKiteFocusActor, bDeferredSpawn = true);
		FocusActor.MakeNetworked(this, n"FocusActor");
		FinishSpawningActor(FocusActor);

		ZipSyncComp = UHazeCrumbSyncedFloatComponent::GetOrCreate(Player, n"ZipSync");
		ZipSyncComp.OverrideSyncRate(EHazeCrumbSyncRate::PlayerSynced);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FZipKiteActivationParams& ActivationParams) const
	{
		if (MoveComp.HasMovedThisFrame())
        	return false;

		if (ZipKitePlayerComp.ZipKiteToForceActivate != nullptr)
		{
			ActivationParams.ZipPoint = ZipKitePlayerComp.ZipKiteToForceActivate;
			return true;
		}

		if (GrappleComp.Data.CurrentGrapplePoint == nullptr)
			return false;

		if (!GrappleComp.Data.bEnterFinished || GrappleComp.Data.CurrentGrapplePoint.GrappleType != EGrapplePointVariations::KiteTown_ZipPoint)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ZipKitePlayerComp.CurrentKite == nullptr)
			return true;

		if (bReachedTop)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FZipKiteActivationParams ActivationParams)
	{
		if (ActivationParams.ZipPoint != nullptr)
			ZipComp = ActivationParams.ZipPoint;
		else
			ZipComp = Cast<UZipKitePointComponent>(GrappleComp.Data.CurrentGrapplePoint);

		ZipKitePlayerComp.ZipKiteToForceActivate = nullptr;

		Kite = Cast<AZipKite>(ZipComp.Owner);
		ZipKitePlayerComp.CurrentKite = Kite;
		ZipKitePlayerComp.CurrentMashSpeedMultiplier = 0.0;

		bZipping = true;
		bReachedTop = false;
		bSwingingUp = false;
		CurrentSwingUpTime = 0.0;

		ZipSyncComp.SetValue(0.0);

		Player.ResetAirJumpUsage();
		Player.ResetAirDashUsage();

		ZipSpeed = Kite.ZipSpeed;
		AccZipSpeed.SnapTo(0.0);
		CurrentZipDistance = Kite.ZipPointHeight;

		Player.BlockCapabilities(CapabilityTags::Movement, this);
		Player.BlockCapabilities(CapabilityTags::GameplayAction, this);
		Player.BlockCapabilities(n"ContextualMoves", this);
		
		if (Kite.bApplyPointOfInterest)
		{
			FHazePointOfInterestFocusTargetInfo FocusTargetInfo;
			FocusTargetInfo.SetFocusToActor(FocusActor);
			FocusTargetInfo.SetLocalOffset(Kite.PoiOffset);
			FApplyPointOfInterestSettings PoiSettings;
			Player.ApplyPointOfInterest(this, FocusTargetInfo, PoiSettings, 0.5);
		}

		SpeedEffect::RequestSpeedEffect(Player, 1.0, this, EInstigatePriority::High);

		Player.PlayCameraShake(ZipKitePlayerComp.ConstantCamShake, this);

		Player.PlaySlotAnimation(Animation = ZipKitePlayerComp.EnterAnim, BlendTime = 0.1);
		Timer::SetTimer(this, n"ActivateBlendSpace", 0.3);

		UHazeCameraSpringArmSettingsDataAsset CamSettings = Kite.CamSettingsOverride == nullptr ? ZipKitePlayerComp.CamSettings : Kite.CamSettingsOverride;
		Player.ApplyCameraSettings(CamSettings, 0.5, this);

		Kite.OnPlayerAttached.Broadcast(Player);

		FButtonMashSettings MashSettings;
		MashSettings.WidgetAttachComponent = FocusActor.RootComponent;
		MashSettings.bBlockOtherGameplay = false;
		MashSettings.ProgressionMode = EButtonMashProgressionMode::MashRateOnly;
		Player.StartButtonMash(MashSettings, this);
		Player.SetButtonMashAllowCompletion(this, false);
		bButtonMashActive = true;
		
		AdditiveFov = 0.0;

		UZipKitePlayerEffectEventHandler::Trigger_StartZipping(Player);
		UKiteTownVOEffectEventHandler::Trigger_ZipStarted(Game::Mio, KiteTown::GetVOEffectEventParams(Player));
	}

	UFUNCTION()
	void ActivateBlendSpace()
	{
		Player.PlayBlendSpace(ZipKitePlayerComp.BlendSpace, 0.2, EHazeBlendType::BlendType_Crossfade, StartPosition = -0.75);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(CapabilityTags::Movement, this);
		Player.UnblockCapabilities(CapabilityTags::GameplayAction, this);
		Player.UnblockCapabilities(n"ContextualMoves", this);
		
		SpeedEffect::ClearSpeedEffect(Player, this);

		Player.StopCameraShakeByInstigator(this);
		Player.ClearPointOfInterestByInstigator(this);

		Player.StopBlendSpace();
		Player.StopSlotAnimation();

		Player.ClearCameraSettingsByInstigator(this, 1.0);

		Player.ResetMovement(true);

		Kite.OnPlayerDetached.Broadcast(Player);
		Kite.OnPlayerLanded.Broadcast(Player);

		DisableButtonMash();

		UZipKitePlayerEffectEventHandler::Trigger_Landed(Player);
		UKiteTownVOEffectEventHandler::Trigger_ZipLanded(Game::Mio, KiteTown::GetVOEffectEventParams(Player));
	}

	void DisableButtonMash()
	{
		if (!bButtonMashActive)
			return;

		bButtonMashActive = false;
		Player.StopButtonMash(this);

		UCameraSettings::GetSettings(Player).FOV.Clear(this, 1.0);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!MoveComp.PrepareMove(MoveData))
			return;

		if (bZipping)
		{
			if (HasControl())
			{
				float MashRate = 0.0;
				bool bMashRateSufficient = false;
				Player.GetButtonMashCurrentRate(this, MashRate, bMashRateSufficient);
				float MashSpeedMultiplier = Math::GetMappedRangeValueClamped(FVector2D(0.0, 8.0), FVector2D(0.0, 1.0), MashRate);
				ZipKitePlayerComp.CurrentMashSpeedMultiplier = MashSpeedMultiplier;
				float TargetZipSpeed = Math::Lerp(ZipSpeed, Kite.ZipMashMaxSpeed, MashSpeedMultiplier);
				AccZipSpeed.AccelerateTo(TargetZipSpeed, 0.5, DeltaTime);

				float TargetFov = Math::Lerp(0.0, 12.0, MashSpeedMultiplier);
				AdditiveFov = Math::FInterpTo(AdditiveFov, TargetFov, DeltaTime, 0.3);
				UCameraSettings::GetSettings(Player).FOV.ApplyAsAdditive(AdditiveFov, this, 0.0, EHazeCameraPriority::VeryHigh);

				CurrentZipDistance += AccZipSpeed.Value * DeltaTime;
				ZipSyncComp.SetValue(CurrentZipDistance);
			
				FVector TargetLoc = GetRopeAttachLocation() + (GetRopeAttachRotation().ForwardVector * Kite.ZipOffset.X) + (GetRopeAttachRotation().RightVector * Kite.ZipOffset.Y) + (FVector::UpVector * Kite.ZipOffset.Z) + (FVector::UpVector * MashSpeedMultiplier * 150.0);
				FVector Loc = Math::VInterpTo(Player.ActorLocation, TargetLoc, DeltaTime, Kite.ZipInterpLocSpeed);
				MoveData.AddDeltaFromMoveTo(Loc);

				FRotator Rot = Math::RInterpTo(Player.ActorRotation, GetRopeAttachRotation() + Kite.RotationOffset, DeltaTime, Kite.ZipInterpRotSpeed);
				MoveData.SetRotation(Rot);

				float BSValue = (Math::Sin(Time::GameTimeSeconds * 4.0));
				Player.SetBlendSpaceValues(0.0, BSValue);

				if (CurrentZipDistance >= Kite.RuntimeSplineRope.Length - 800.0)
					CrumbStartSwingingUp();

				float FFFrequency = 30.0;
				float FFIntensity = 0.4;

				FHazeFrameForceFeedback FF;
				FF.LeftMotor = Math::Sin(ActiveDuration * FFFrequency) * FFIntensity;
				FF.RightMotor = Math::Sin(-ActiveDuration * FFFrequency) * FFIntensity;
				Player.SetFrameForceFeedback(FF);
			}
			else
			{
				MoveData.ApplyCrumbSyncedGroundMovement();
			}
		}

		if (bSwingingUp)
		{
			USceneComponent KiteRoot = Kite.KiteHoverRoot;

			FHazeRuntimeSpline SwingUpSpline;
			FVector ZipStartPoint = Kite.RuntimeSplineRope.GetLocationAtDistance(Kite.RuntimeSplineRope.Length - 800.0);
			FRotator RopeAttachRot = Kite.RuntimeSplineRope.GetRotationAtDistance(CurrentZipDistance);
			RopeAttachRot.Roll = 0.0;
			RopeAttachRot.Pitch = 0.0;
			ZipStartPoint += RopeAttachRot.RightVector * Kite.ZipOffset.Y;
			SwingUpSpline.AddPoint(SwingUpStartPoint);

			FVector MidLoc = (KiteRoot.WorldLocation + ZipStartPoint)/2.0;
			FVector DirStartToEnd = (KiteRoot.WorldLocation - ZipStartPoint).GetSafeNormal();
			FVector MidLocOffsetDir = DirStartToEnd.CrossProduct(KiteRoot.RightVector);
			MidLoc += MidLocOffsetDir * 300.0;
			MidLoc -= KiteRoot.RightVector * 30.0;
			SwingUpSpline.AddPoint(MidLoc);

			FVector TopPoint2 = Kite.PlayerLandingPointComp.WorldLocation + (Kite.PlayerLandingPointComp.UpVector * 200.0);
			TopPoint2 -= KiteRoot.ForwardVector * 400.0;
			TopPoint2 -= KiteRoot.RightVector * 25.0;
			SwingUpSpline.AddPoint(TopPoint2);

			FVector TopPoint = Kite.PlayerLandingPointComp.WorldLocation + (Kite.PlayerLandingPointComp.UpVector * 200.0);
			TopPoint -= KiteRoot.ForwardVector * 150.0;

			SwingUpSpline.AddPoint(TopPoint);
			SwingUpSpline.AddPoint(Kite.PlayerLandingPointComp.WorldLocation);
			SwingUpSpline.SetCustomCurvature(0.5);

			// SwingUpSpline.DrawDebugSpline();

			CurrentSwingUpTime = Math::Clamp(CurrentSwingUpTime + DeltaTime, 0.0, SwingUpDuration);
			float SwingUpAlpha = CurrentSwingUpTime/SwingUpDuration;
			FVector Loc = SwingUpSpline.GetLocation(SwingUpAlpha);
			MoveData.AddDeltaFromMoveTo(Loc);

			FRotator Rot = Math::RInterpShortestPathTo(Player.ActorRotation, Kite.KiteHoverRoot.ForwardVector.Rotation(), DeltaTime, 2.0);
			MoveData.SetRotation(Rot);

			float PoIOffset = Math::Lerp(0.0, 2000.0, SwingUpAlpha);
			FVector PoILoc = Kite.KiteRoot.WorldLocation + (Kite.KiteRoot.ForwardVector * PoIOffset);
			FocusActor.SetActorLocation(PoILoc);

			float CameraFraction = Math::Lerp(0.0, 1.0, ZipKitePlayerComp.CameraFractionCurve.GetFloatValue(SwingUpAlpha));
			Player.ApplyManualFractionToCameraSettings(CameraFraction, this);

			if (SwingUpAlpha >= 1.0)
				bReachedTop = true;

			if (SwingUpAlpha <= 0.1)
				DebugDrawTether(Kite.RuntimeSplineRope.GetLocationAtDistance(CurrentZipDistance));

			float LeftFFIntensity = Math::Lerp(0.2, 0.0, SwingUpAlpha);
			float RightFFIntensity = Math::Lerp(0.0, 0.2, SwingUpAlpha);
			Player.SetFrameForceFeedback(LeftFFIntensity, RightFFIntensity, 0.0, 0.0);
		}

		if (bZipping)
		{
			FocusActor.SetActorLocationAndRotation(GetRopeAttachLocation(), GetRopeAttachRotation());
			DebugDrawTether(GetRopeAttachLocation());
		}

		MoveComp.ApplyMove(MoveData);
	}

	UFUNCTION(CrumbFunction)
	void CrumbStartSwingingUp()
	{
		SwingUpStartPoint = Player.ActorLocation;

		bZipping = false;
		bSwingingUp = true;

		Player.StopBlendSpace();
		Player.PlaySlotAnimation(Animation = ZipKitePlayerComp.SwingUpAnim, PlayRate = 0.75, StartTime = 0.0);

		Player.ApplyCameraSettings(ZipKitePlayerComp.SwingUpCamSettings, 0.4, this, EHazeCameraPriority::High);

		// Player.SmoothTeleportActor(Kite.KiteHoverRoot.WorldLocation - (FVector::UpVector * 600.0), Player.ActorRotation, this, 0.5);

		Player.StopCameraShakeByInstigator(this);

		SpeedEffect::ClearSpeedEffect(Player, this);

		DisableButtonMash();

		UZipKitePlayerEffectEventHandler::Trigger_LaunchUp(Player);
		UKiteTownVOEffectEventHandler::Trigger_ZipLaunchUp(Game::Mio, KiteTown::GetVOEffectEventParams(Player));
	}

	void DebugDrawTether(FVector AttachLoc)
	{
		FLinearColor TetherColor = FLinearColor(0.15, 0.10, 0.10);
		Debug::DrawDebugLine(AttachLoc, Player.Mesh.GetSocketLocation(n"LeftAttach"), TetherColor, 3.0);		
		Debug::DrawDebugLine(Player.Mesh.GetSocketLocation(n"LeftAttach"), Player.Mesh.GetSocketLocation(n"RightAttach"), TetherColor, 3.0);		
		Debug::DrawDebugLine(Player.Mesh.GetSocketLocation(n"RightAttach"), Player.Mesh.GetSocketLocation(n"Hips"), TetherColor, 3.0);	
	}

	FVector GetRopeAttachLocation()
	{
		return Kite.RuntimeSplineRope.GetLocationAtDistance(ZipSyncComp.Value);
	}

	FRotator GetRopeAttachRotation()
	{
		FRotator RopeAttachRot = Kite.RuntimeSplineRope.GetRotationAtDistance(ZipSyncComp.Value);
		RopeAttachRot.Roll = 0.0;
		RopeAttachRot.Pitch = 0.0;

		return RopeAttachRot;
	}
}

struct FZipKiteActivationParams
{
	UZipKitePointComponent ZipPoint;
}

class AZipKiteFocusActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;
}