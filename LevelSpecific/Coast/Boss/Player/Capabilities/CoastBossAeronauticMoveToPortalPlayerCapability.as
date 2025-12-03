asset AeronauticExitCurve of UCurveFloat
{
	/*
	    ------------------------------------------------------------------
	1.0 |                                                      ..··''''''|
	    |                                                  .·''          |
	    |                                              .·''              |
	    |                                           .·'                  |
	    |                                        .·'                     |
	    |                                     .·'                        |
	    |                                   .'                           |
	    |                                .·'                             |
	    |                             .·'                                |
	    |                           .'                                   |
	    |                        .·'                                     |
	    |                     .·'                                        |
	    |                  .·'                                           |
	    |              ..·'                                              |
	    |          ..·'                                                  |
	0.0 |......··''                                                      |
	    ------------------------------------------------------------------
	    0.0                                                            1.0
	*/
	AddAutoCurveKey(0.0, 0.0);
	AddAutoCurveKey(1.0, 1.0);
}

class UCoastBossAeronauticMoveToPortalPlayerCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CoastBossTags::CoastBossTag);
	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 90; // before UCoastBossAeronauticMovementPlayerCapability

	ACoastBossActorReferences References;

	FHazeAcceleratedVector2D AccLocation;
	UPlayerMovementComponent MoveComp;
	USimpleMovementData MoveData;
	UCoastBossAeronauticComponent AirMoveDataComp;
	UCameraUserComponent CameraUser;
	FVector2D StartRelativeLocation;

	FHazeAcceleratedFloat AccVisualPitch;
	const float PitchFeedbackDegrees = 2.0;

	FHazeAcceleratedFloat AccVisualRoll;
	const float RollFeedbackDegrees = 25.0;

	const float ToCenterDuration = 4.0;
	const float ToPortalDuration = 7.0;

	AHazeActor ExitPortal;
	float Alpha = 0.0;
	float PortalRadius = 500.0;

	FHazeAcceleratedRotator AccRotator;
	FHazeAcceleratedFloat AccBackwardsSplineOffset;
	FHazeAcceleratedFloat AccFocalDistance;
	FHazeRuntimeSpline Spline;

	FPostProcessSettings DepthOfFieldSettings;

	const float ExitDuration = 6.0;
	bool bMoveDone = false;
	bool bHasAppliedBlackFade = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		TListedActors<ACoastBossActorReferences> LevelReferencesActor;
		References = LevelReferencesActor.Single;
		AirMoveDataComp = UCoastBossAeronauticComponent::GetOrCreate(Player);
		MoveComp = UPlayerMovementComponent::GetOrCreate(Player);
		CameraUser = UCameraUserComponent::Get(Player);
		MoveData = MoveComp.SetupSimpleMovementData();
		AccBackwardsSplineOffset.SnapTo(2000.0);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (References == nullptr)
			return false;
		if (!AirMoveDataComp.bAttached)
			return false;
		if (!References.Boss.bFullyDead)
			return false;
		if(AirMoveDataComp.RightMostPlayer == nullptr)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (References == nullptr)
			return true;
		if (!AirMoveDataComp.bAttached)
			return true;
		if (bMoveDone)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		AccFocalDistance.SnapTo(5000.0);
		SceneView::ApplyPlayerLetterbox(Player, this, EHazeViewPointBlendSpeed::Normal);
		Player.AddDamageInvulnerability(this);
		bHasAppliedBlackFade = false;
		bMoveDone = false;
		CacheExitPortal();
		AccRotator.SnapTo(Player.ActorRotation);
		FHazePlaySlotAnimationParams AnimParams;

		if(Player.IsMio())
		{
			AnimParams.Animation = AirMoveDataComp.RideDroneAnimation;
		}
		else
		{
			AnimParams.Animation = AirMoveDataComp.ZoeRideDroneAnimation;
		}
		
		AnimParams.bLoop = true;
		Player.PlaySlotAnimation(AnimParams);

		Spline = FHazeRuntimeSpline();
		FVector WorldLocation = References.CoastBossPlane2D.GetLocationInWorld(FVector2D(AirMoveDataComp.Forwards, AirMoveDataComp.Upwards));
		FVector StartPosRelativeToPlane = ExitPortal.ActorTransform.InverseTransformPositionNoScale(WorldLocation);
		Spline.AddPoint(StartPosRelativeToPlane);
		FVector RelativeExitPortalLocation = ExitPortal.ActorTransform.InverseTransformPositionNoScale(ExitPortal.ActorLocation);
		RelativeExitPortalLocation.Z += 570.0;
		FVector RelativeExitLocationForCamera = RelativeExitPortalLocation;

		FVector PlayerPosRelativeToPlane = References.CoastBossPlane2D.ActorTransform.InverseTransformPositionNoScale(Player.ActorLocation);
		FVector OtherPlayerPosRelativeToPlane = References.CoastBossPlane2D.ActorTransform.InverseTransformPositionNoScale(Player.OtherPlayer.ActorLocation);

		RelativeExitPortalLocation.X += CoastBossConstants::Player::MioHorizontalExitOffset * (Player == AirMoveDataComp.RightMostPlayer ? 1.0 : -1.0);
		Spline.AddPoint(RelativeExitPortalLocation);

		References.ExitCamera.AttachToActor(ExitPortal);
		References.ExitCamera.ActorTransform = ExitPortal.ActorTransform;
		UHazeSplineComponent CamSpline = References.ExitCamera.CameraSpline;

		CamSpline.SplinePoints.Reset();
		FVector AveragePlayerStartLocation = (StartPosRelativeToPlane + OtherPlayerPosRelativeToPlane) * 0.5;
		FVector SplineOffset = FVector::UpVector * 500.0;
		FVector Point1 = AveragePlayerStartLocation + SplineOffset;
		FVector Point2 = RelativeExitLocationForCamera;
		// Make camera spline extend further back so we can add spline offset on the camera.
		CamSpline.SplinePoints.Add(FHazeSplinePoint(Point1 + (Point1 - Point2).GetSafeNormal() * 10000.0));
		CamSpline.SplinePoints.Add(FHazeSplinePoint(Point2 + (Point2 - Point1).GetSafeNormal() * 10000.0));
		CamSpline.UpdateSpline();

		Player.ActivateCameraCustomBlend(References.ExitCamera, CoastBossAeronauticKeepVelocityBlend, 4.0, this, EHazeCameraPriority::High);
		Player.BlockCapabilities(CameraTags::CameraAlignWithWorldUp, this);

		if(Player.IsMio())
			References.OnMoveToPortal.Broadcast();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		SceneView::ClearPlayerLetterbox(Player, this);
		References.Boss.PlayerEnteredPortal();
		Player.RemoveDamageInvulnerability(this);
		Player.StopSlotAnimation();
		Player.DeactivateCamera(References.ExitCamera);
		Player.UnblockCapabilities(CameraTags::CameraAlignWithWorldUp, this);
		Player.StopSlotAnimation();
		PostProcessing::ClearOverExposure(Player);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (References == nullptr)
			return;

		Alpha = Math::Clamp(ActiveDuration / ExitDuration, 0.0, 1.0);
		if(Alpha >= 1.0)
		{
			Alpha = 1.0;
			bMoveDone = true;
		}

		float TargetDistance = Player.ViewLocation.Distance(Player.ActorLocation);

		FVector PortalFocusLocation = ExitPortal.ActorLocation + FVector::UpVector * 570.0;
		if(Alpha > 0.6)
		{
			TargetDistance = Player.ViewLocation.Distance(PortalFocusLocation);
			AccBackwardsSplineOffset.AccelerateTo(-500.0, 3.5, DeltaTime);
		}

		AccFocalDistance.AccelerateTo(TargetDistance, 1.0, DeltaTime);
		DepthOfFieldSettings.DepthOfFieldFocalDistance = AccFocalDistance.Value;
		DepthOfFieldSettings.DepthOfFieldSensorWidth = 200.0;
		DepthOfFieldSettings.DepthOfFieldFstop = 0.5;
		DepthOfFieldSettings.DepthOfFieldMinFstop = 0.5;
		Player.AddCustomPostProcessSettings(DepthOfFieldSettings, 1.f, References.Boss.GetLevelScriptActor());

		References.ExitCamera.RuntimeSettingsComponent.ApplyLocationSplineBackwardsOffsetOverride(Player, AccBackwardsSplineOffset.Value, this);

		// FVector PortalLocation = ExitPortal.ActorLocation + FVector::UpVector * 570.0;
		// Debug::DrawDebugPoint(CameraUser.ActiveCameraLocation, 15.f, FLinearColor::Red);
		// Debug::DrawDebugPoint(PortalLocation, 100.f, FLinearColor::Green);
		// float Distance = CameraUser.ActiveCameraLocation.Distance(PortalLocation);
		// PrintToScreen(f"{Distance=}");
		if(Alpha > 0.85 && !bHasAppliedBlackFade)
		{
			bHasAppliedBlackFade = true;
			PostProcessing::OverExposeToWhite(Player, 0.5);
			FadeFullscreenToColor(this, FLinearColor::White, -1, 0.5, 0.5);
		}

		Alpha = AeronauticExitCurve.GetFloatValue(Alpha);
		
		FVector Location;
		FQuat Quat;

		Spline.GetLocationAndQuatAtDistance(Alpha * Spline.Length, Location, Quat);
		Location = ExitPortal.ActorTransform.TransformPositionNoScale(Location);
		Quat = ExitPortal.ActorTransform.TransformRotation(Quat);
		
		if(IsDebugActive())
		{
			References.EnterCamera.CameraSpline.DrawDebug();
			Spline.DrawDebugSplineRelativeTo(ExitPortal.ActorTransform);
		}

		FRotator Rotation = AccRotator.AccelerateTo(Quat.Rotator(), 1.0, DeltaTime);
		ApplyMove(Location, Rotation);
	}

	void ApplyMove(FVector NewLocation, FRotator NewRotation)
	{
		if (!MoveComp.PrepareMove(MoveData, NewRotation.UpVector))
			return;

		FVector Delta = NewLocation - Player.ActorLocation;
		MoveData.AddDelta(Delta);
		MoveData.SetRotation(NewRotation);
		MoveComp.ApplyMove(MoveData);

		if (CoastBossDevToggles::Draw::DrawDebugPlayers.IsEnabled())
		{
			const float PlaneLength = 320.0;
			Debug::DrawDebugBox(NewLocation - NewRotation.ForwardVector * 40.0, FVector(PlaneLength, 90.0, 70.0) * 1.1, NewRotation, Player.GetPlayerUIColor(), 10.0, 0.0, true);
			Debug::DrawDebugBox(NewLocation - NewRotation.ForwardVector * PlaneLength, FVector(30.0, 20.0, 130.0) * 1.1, NewRotation, Player.GetPlayerUIColor(), 30.0, 0.0, true);
			Debug::DrawDebugBox(NewLocation, FVector(50.0, 270.0, 20.0), NewRotation, Player.GetPlayerUIColor(), 30.0, 0.0, true);
		}
	}

	void CacheExitPortal()
	{
		ACoastTrainDriver MainDriver = CoastTrain::GetMainTrainDriver();
		ExitPortal = MainDriver.NextCart;
	}
}