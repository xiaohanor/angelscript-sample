class UMedallionPlayerSidescrollerCameraFocusCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(MedallionTags::MedallionTag);
	default TickGroup = EHazeTickGroup::Gameplay;

	UMedallionPlayerMergeHighfiveJumpComponent HighfiveComp;
	UMedallionPlayerComponent PlayerMedallionComp;
	UMedallionPlayerComponent MioMedallionComp;
	UMedallionPlayerComponent ZoeMedallionComp;
	UMedallionPlayerReferencesComponent RefsComp;
	AMedallionPlayerSidescrollerCameraFocus SidescrollingFocusActor;
	FHazeAcceleratedVector AcceleratedHorizontalOffset;
	FHazeAcceleratedFloat AcceleratedHighfiveZoom;
	FHazeAcceleratedFloat AcceleratedMergeHeight;
	FVector BackupHorizontalOffset;
	FVector HorizontalOffset;

	private bool bCameraFocusMerged = false;
	private bool bLastFrameCameraFocusMerged = false;
	private float ProjectionMergedTime;

	AHazePlayerCharacter Mio;
	AHazePlayerCharacter Zoe;

	UPlayerRespawnComponent PlayerRespawnComp;
	UCameraUserComponent CamUser;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		HighfiveComp = UMedallionPlayerMergeHighfiveJumpComponent::GetOrCreate(Player);
		PlayerMedallionComp = UMedallionPlayerComponent::GetOrCreate(Player);
		RefsComp = UMedallionPlayerReferencesComponent::GetOrCreate(Player);
		PlayerRespawnComp = UPlayerRespawnComponent::GetOrCreate(Player);
		PlayerRespawnComp.OnPlayerRespawned.AddUFunction(this, n"PlayerRespawned");
		CamUser = UCameraUserComponent::GetOrCreate(Player);

		Mio = Game::Mio;
		Zoe = Game::Zoe;

		MioMedallionComp = UMedallionPlayerComponent::GetOrCreate(Mio);
		ZoeMedallionComp = UMedallionPlayerComponent::GetOrCreate(Zoe);
	}

	UFUNCTION()
	private void PlayerRespawned(AHazePlayerCharacter RespawnedPlayer)
	{
		if (!IsActive())
			return;
		if (PlayerMedallionComp.IsMedallionCoopFlying())
			return;
		UpdateDynamicFocus(0.0, true);
		// FVector Derpiderp;
		// CamUser.SnapCamera(Derpiderp);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (RefsComp.Refs == nullptr)
			return false;
		if (RefsComp.Refs.SideScrollerSplineLocker == nullptr)
			return false;
		if (RefsComp.Refs.MioSidescrollerCameraFocus == nullptr)
			return false;
		if (RefsComp.Refs.ZoeSidescrollerCameraFocus == nullptr)
			return false;
		if (HighfiveComp.IsInHighfiveFail())
			return false;
		if (RefsComp.Refs.HydraAttackManager.Phase >= EMedallionPhase::GloryKill3)
			return false;
		if (Player.IsAnyCapabilityActive(n"GameOver"))
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (RefsComp.Refs.HydraAttackManager.Phase >= EMedallionPhase::GloryKill3)
			return true;
		if (HighfiveComp.IsInHighfiveFail())
			return true;
		if (Player.IsAnyCapabilityActive(n"GameOver"))
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		if (SidescrollingFocusActor == nullptr)
		{
			if (Player.IsMio())
				SidescrollingFocusActor = RefsComp.Refs.MioSidescrollerCameraFocus;
			else
				SidescrollingFocusActor = RefsComp.Refs.ZoeSidescrollerCameraFocus;
		}
		AcceleratedHorizontalOffset.SnapTo(FVector());
		FHitResult Unused;
		if (SidescrollingFocusActor != nullptr)
			SidescrollingFocusActor.SetActorLocation(AcceleratedHorizontalOffset.Value, false, Unused, true);

		AcceleratedHighfiveZoom.SnapTo(0.0);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		PlayerMedallionComp.bHasMergedFocus = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (PlayerMedallionComp.IsMedallionCoopFlying())
			UpdateLandingFocus(DeltaTime);
		else
			UpdateDynamicFocus(DeltaTime, false);
	}

	void UpdateLandingFocus(float DeltaTime)
	{
		float VerticalOffset = GetVerticalTargetLocation(DeltaTime, Mio.ActorCenterLocation, Zoe.ActorCenterLocation, false);

		// horizontal offset
		FVector LandingLocation = Player.IsMio() ? RefsComp.Refs.GloryKillExitLocationMio.ActorLocation : RefsComp.Refs.GloryKillExitLocationZoe.ActorLocation;
		float LandingClosestDistance = RefsComp.Refs.SideScrollerSplineLocker.Spline.GetClosestSplineDistanceToWorldLocation(LandingLocation);
		float Signwards = Player.IsMio() ? 1.0 : -1.0;
		float AddedHorizontalDist = PlayerMedallionComp.ProjectionOffsetAlpha * MedallionConstants::ReturnAndLand::CameraAddedHorizontalDist;
		FVector FutureLocation = RefsComp.Refs.SideScrollerSplineLocker.Spline.GetWorldLocationAtSplineDistance(LandingClosestDistance + Signwards * (MedallionConstants::SideScrollerCamera::HorizontalDist + AddedHorizontalDist));
		HorizontalOffset = FutureLocation - LandingLocation;

		bCameraFocusMerged = false;
		PlayerMedallionComp.bCameraFocusFullyMerged = false;

		AcceleratedHighfiveZoom.AccelerateTo(0.0, 1.0, DeltaTime);
		AcceleratedHorizontalOffset.AccelerateTo(HorizontalOffset, MedallionConstants::SideScrollerCamera::InterpHorizontalDuration, DeltaTime);

		FHitResult Unused;
		FVector NewLocation = LandingLocation + AcceleratedHorizontalOffset.Value;
		VerticalOffset += AcceleratedHighfiveZoom.Value * MedallionConstants::Highfive::HighfiveCameraOffsetUpwards;
		NewLocation.Z = VerticalOffset;

		FVector InwardsDirection = -RefsComp.Refs.SideScrollerSplineLocker.Spline.GetWorldRotationAtSplineDistance(LandingClosestDistance).RightVector;
		NewLocation += InwardsDirection * AcceleratedHighfiveZoom.Value * MedallionConstants::Highfive::HighfiveCameraOffsetInwards;
		SidescrollingFocusActor.SetActorLocation(NewLocation, false, Unused, true);

		if (SanctuaryMedallionHydraDevToggles::Draw::Camera.IsEnabled())
		{
			Debug::DrawDebugSphere(NewLocation, 30.0, 12, ColorDebug::Yellow, bDrawInForeground = true);
			Debug::DrawDebugString(NewLocation + FVector::UpVector * 70, "Focus Point", ColorDebug::Yellow);

			Debug::DrawDebugSphere(LandingLocation, 30.0, 12, Player.GetPlayerUIColor(), bDrawInForeground = true);
			Debug::DrawDebugString(LandingLocation + FVector::UpVector * 70, Player.GetName() + " Landing Point", ColorDebug::Yellow);
			RefsComp.Refs.SideScrollerSplineLocker.Spline.DrawDebug();
		}
	}

	void UpdateDynamicFocus(float DeltaTime, bool bRespawnSnap)
	{
		FVector MioLocation = MioMedallionComp.GetPlayerLerpedRespawnLocation(DeltaTime);
		FVector ZoeLocation = ZoeMedallionComp.GetPlayerLerpedRespawnLocation(DeltaTime);
		float VerticalOffset = GetVerticalTargetLocation(DeltaTime, MioLocation, ZoeLocation, bRespawnSnap);

		// horizontal offset
		float PlayerClosestDistance = RefsComp.Refs.SideScrollerSplineLocker.Spline.GetClosestSplineDistanceToWorldLocation(Player.ActorLocation);
		float Signwards = Player.IsMio() ? 1.0 : -1.0;
		float AddedHorizontalDist = PlayerMedallionComp.ProjectionOffsetAlpha * MedallionConstants::SideScrollerCamera::OffsetProjectionAddedHorizontalDist;
		FVector FutureLocation = RefsComp.Refs.SideScrollerSplineLocker.Spline.GetWorldLocationAtSplineDistance(PlayerClosestDistance + Signwards * (MedallionConstants::SideScrollerCamera::HorizontalDist + AddedHorizontalDist));
		HorizontalOffset = FutureLocation - Player.ActorLocation;
		
		// set horizontal offset between players if close enough
		float MioProgress = RefsComp.Refs.SideScrollerSplineLocker.Spline.GetClosestSplineDistanceToWorldLocation(MioLocation);
		float ZoeProgress = RefsComp.Refs.SideScrollerSplineLocker.Spline.GetClosestSplineDistanceToWorldLocation(ZoeLocation);

		float MioTargetActorProgress = MioProgress +  1.0 * (MedallionConstants::SideScrollerCamera::HorizontalDist + AddedHorizontalDist);
		float ZoeTargetActorProgress = ZoeProgress +  -1.0 * (MedallionConstants::SideScrollerCamera::HorizontalDist + AddedHorizontalDist);
		
		float DeltaDist = ZoeProgress - MioProgress;
		float AverageDist = MioProgress + DeltaDist * 0.5;

		bCameraFocusMerged = MioTargetActorProgress > ZoeTargetActorProgress;
		if (bCameraFocusMerged || PlayerMedallionComp.bHasMergedFocus)
		{
			PlayerMedallionComp.bHasMergedFocus = true;
			FVector AverageLocation = RefsComp.Refs.SideScrollerSplineLocker.Spline.GetWorldLocationAtSplineDistance(AverageDist);
			HorizontalOffset = AverageLocation - Player.ActorLocation;
		}
		if (!IsInMerge())
			PlayerMedallionComp.bHasMergedFocus = false;

		bool bWasMerged = PlayerMedallionComp.bCameraFocusFullyMerged;
		PlayerMedallionComp.bCameraFocusFullyMerged = HasCameraFocusSettled();
		if (!bWasMerged && PlayerMedallionComp.bCameraFocusFullyMerged)
		{
			PlayerMedallionComp.OnFocusFullyMerged.Broadcast();
		}

		// inwards offset
 		if (HighfiveComp.IsHighfiveJumping())
			AcceleratedHighfiveZoom.AccelerateTo(1.0, 0.9, DeltaTime);
		else
			AcceleratedHighfiveZoom.AccelerateTo(0.0, 1.0, DeltaTime);

		if (bRespawnSnap)
			AcceleratedHorizontalOffset.SnapTo(HorizontalOffset);
		else
			AcceleratedHorizontalOffset.AccelerateTo(HorizontalOffset, MedallionConstants::SideScrollerCamera::InterpHorizontalDuration, DeltaTime);

		FHitResult Unused;
		FVector NewLocation = Owner.ActorCenterLocation + AcceleratedHorizontalOffset.Value;
		VerticalOffset += AcceleratedHighfiveZoom.Value * MedallionConstants::Highfive::HighfiveCameraOffsetUpwards;
		NewLocation.Z = VerticalOffset;

		FVector InwardsDirection = -RefsComp.Refs.SideScrollerSplineLocker.Spline.GetWorldRotationAtSplineDistance(AverageDist).RightVector;
		NewLocation += InwardsDirection * AcceleratedHighfiveZoom.Value * MedallionConstants::Highfive::HighfiveCameraOffsetInwards;
		if (bRespawnSnap)
			SidescrollingFocusActor.TeleportActor(NewLocation, SidescrollingFocusActor.ActorRotation, this, true);
		else
			SidescrollingFocusActor.SetActorLocation(NewLocation, false, Unused, true);

		if (SanctuaryMedallionHydraDevToggles::Draw::Camera.IsEnabled())
		{
			Debug::DrawDebugSphere(NewLocation, 10.0, 12, Math::Lerp(Player.GetPlayerUIColor(), ColorDebug::White, 0.5), bDrawInForeground = true);
			Debug::DrawDebugString(NewLocation + FVector::UpVector * 10, "Focus Point", Player.GetPlayerUIColor());
			FVector ClosestLoc = RefsComp.Refs.SideScrollerSplineLocker.Spline.GetWorldLocationAtSplineDistance(AverageDist);
			Debug::DrawDebugSphere(ClosestLoc, 3.0, 12, Player.GetPlayerUIColor(), bDrawInForeground = true);
			Debug::DrawDebugLine(NewLocation, NewLocation + FVector::UpVector * 1000);
		}
	}

	bool IsInMerge()
	{
		if (RefsComp.Refs.HydraAttackManager.Phase == EMedallionPhase::Merge1)
			return true;
		if (RefsComp.Refs.HydraAttackManager.Phase == EMedallionPhase::Merge2)
			return true;
		if (RefsComp.Refs.HydraAttackManager.Phase == EMedallionPhase::Merge3)
			return true;
		return false;
	}

	bool HasCameraFocusSettled()
	{
		if (bCameraFocusMerged && !bLastFrameCameraFocusMerged)
			ProjectionMergedTime = Time::GameTimeSeconds;

		bLastFrameCameraFocusMerged = bCameraFocusMerged;

		if (bCameraFocusMerged && Time::GameTimeSeconds > ProjectionMergedTime + MedallionConstants::SideScrollerCamera::MergeScreenSettleDuration)
			return true;
		else
			return false;
	}

	float GetVerticalTargetLocation(float DeltaTime, FVector UsedMioLocation, FVector UsedZoeLocation, bool bRespawnSnap)
	{
		float VerticalTarget = 0.0;
		{
			FVector OurLocation = Player.IsMio() ? UsedMioLocation : UsedZoeLocation;
			FVector OtherPlayerLocation = Player.IsMio() ? UsedZoeLocation : UsedMioLocation;
			float PlayerZ = OurLocation.Z;
			if (bCameraFocusMerged)
				PlayerZ = (PlayerZ + OtherPlayerLocation.Z) * 0.5;

			float TargetHeight = PlayerZ; //RefsComp.Refs.SideScrollerSplineLocker.ActorLocation.Z - PlayerZ;

			float HeightFactor = Math::Lerp(MedallionConstants::SideScrollerCamera::LerpSplineHeightFactor, 1.0, PlayerMedallionComp.ProjectionOffsetAlpha);
			HeightFactor = HeightFactor * PlayerMedallionComp.HighfiveZoomAlpha;
			
			VerticalTarget = Math::Lerp(TargetHeight, RefsComp.Refs.SideScrollerSplineLocker.ActorLocation.Z, HeightFactor);
			if (bRespawnSnap)
			{
				AcceleratedMergeHeight.SnapTo(VerticalTarget);
			}
			if (HighfiveComp.IsHighfiveJumping())
			{
				VerticalTarget = (PlayerZ + OtherPlayerLocation.Z) * 0.5;
				AcceleratedMergeHeight.SnapTo(VerticalTarget + 50.0);
			}
			else if (Math::IsNearlyEqual(AcceleratedMergeHeight.Value, 0.0, KINDA_SMALL_NUMBER))
				AcceleratedMergeHeight.SnapTo(VerticalTarget);
			else
				AcceleratedMergeHeight.AccelerateTo(VerticalTarget, 0.7, DeltaTime);

			if (SanctuaryMedallionHydraDevToggles::Draw::Camera.IsEnabled())
			{
				FVector WithOffset = Owner.ActorCenterLocation;
				WithOffset.Z += VerticalTarget;
				Debug::DrawDebugSphere(WithOffset, 30.0, 12, ColorDebug::Ultramarine, bDrawInForeground = true);
				FVector CameraSplineDebugPos = Owner.ActorCenterLocation;
				CameraSplineDebugPos.Z = RefsComp.Refs.SideScrollerSplineLocker.ActorLocation.Z;

				Debug::DrawDebugString(WithOffset, "Height Lerp Factor: " + MedallionConstants::SideScrollerCamera::LerpSplineHeightFactor, ColorDebug::Lapis);
				Debug::DrawDebugLine(CameraSplineDebugPos + Owner.ActorForwardVector * 300.0, CameraSplineDebugPos - Owner.ActorForwardVector * 300.0, ColorDebug::Cyan, bDrawInForeground = true);
				Debug::DrawDebugLine(WithOffset, CameraSplineDebugPos, ColorDebug::Ultramarine, bDrawInForeground = true);
				Debug::DrawDebugLine(WithOffset, Owner.ActorCenterLocation, ColorDebug::Lapis, 10.0, bDrawInForeground = true);
				Debug::DrawDebugString(CameraSplineDebugPos, "Camera Spline Height", ColorDebug::Cyan);
			}
		}

		return AcceleratedMergeHeight.Value;
	}
};