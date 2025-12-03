struct FCoastBossAeronauticMoveTo2DPlanePlayerActivationParams
{
}

asset AeronauticEnterCurve of UCurveFloat
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

class UCoastBossAeronauticMoveTo2DPlanePlayerCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CoastBossTags::CoastBossTag);
	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 90; // before UCoastBossAeronauticMovementPlayerCapability

	ACoastBossActorReferences References;

	UPlayerMovementComponent MoveComp;
	USimpleMovementData MoveData;
	UCoastBossAeronauticComponent AirMoveDataComp;
	UPlayerHealthComponent HealthComp;

	FHazeAcceleratedFloat AccVisualPitch;
	const float PitchFeedbackDegrees = 2.0;

	FHazeAcceleratedFloat AccVisualRoll;
	const float RollFeedbackDegrees = 25.0;

	FHazeAcceleratedRotator AccRotator;
	FHazeRuntimeSpline Spline;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		TListedActors<ACoastBossActorReferences> LevelReferencesActor;
		References = LevelReferencesActor.Single;
		AirMoveDataComp = UCoastBossAeronauticComponent::GetOrCreate(Owner);
		MoveComp = UPlayerMovementComponent::GetOrCreate(Owner);
		MoveData = MoveComp.SetupSimpleMovementData();
		HealthComp = UPlayerHealthComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FCoastBossAeronauticMoveTo2DPlanePlayerActivationParams& OutParams) const
	{
		if(!AirMoveDataComp.bShouldPlayerEnter)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!AirMoveDataComp.bShouldPlayerEnter)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCoastBossAeronauticMoveTo2DPlanePlayerActivationParams Params)
	{
		HealthComp.AddDamageInvulnerability(this, -1.0);
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

		Player.BlockCapabilities(CoastBossTags::CoastBossPlayerShootTag, this);

		ACoastTrainDriver MainDriver = CoastTrain::GetMainTrainDriver();

		UCoastTrainInheritMovementComponent InheritMoveComp = MainDriver.GetClosestInheritMovementComponentToPoint(Player.ActorLocation);

		Spline = FHazeRuntimeSpline();
		const float StraightUpHeight = 500.0;
		const float CurveLength = 700.0;
		FVector Offset = FVector::UpVector * (Player.IsMio() ? 200.0 : -200.0);

		FVector StartPosRelativeToPlane = References.CoastBossPlane2D.ActorTransform.InverseTransformPositionNoScale(Player.ActorLocation);
		Spline.AddPoint(StartPosRelativeToPlane);
		FVector LocalForwardVector = References.CoastBossPlane2D.ActorTransform.InverseTransformVectorNoScale(InheritMoveComp.ForwardVector);
		Spline.AddPoint(StartPosRelativeToPlane + FVector::UpVector * StraightUpHeight + LocalForwardVector * CurveLength + Offset);
		FVector RelativeRespawnPointLocation = References.CoastBossPlane2D.ActorTransform.InverseTransformPositionNoScale(References.PlaneRespawnPoint.ActorLocation);
		RelativeRespawnPointLocation.Z += Player.IsMio() ? CoastBossConstants::Player::MioVerticalEnterOffset : 0.0;
		//Spline.AddPoint(RelativeRespawnPointLocation - LocalForwardVector * CurveLength + Offset);
		Spline.AddPoint(RelativeRespawnPointLocation);

		References.EnterCamera.AttachToActor(References.CoastBossPlane2D);
		References.EnterCamera.ActorTransform = References.CoastBossPlane2D.ActorTransform;
		UHazeSplineComponent CamSpline = References.EnterCamera.CameraSpline;

		CamSpline.SplinePoints.Reset();
		FVector AverageLocBetweenPlayers = (Player.ActorLocation + Player.OtherPlayer.ActorLocation) * 0.5;
		FVector AverageLocRelativeToPlane = References.CoastBossPlane2D.ActorTransform.InverseTransformPositionNoScale(AverageLocBetweenPlayers);
		FVector FirstPoint = AverageLocRelativeToPlane - LocalForwardVector * 1200.0 + FVector::UpVector * 200.0;
		FVector LastPoint = RelativeRespawnPointLocation - LocalForwardVector * CurveLength - LocalForwardVector * 1500.0 + FVector::UpVector * 400.0;
		FVector MidPoint = FirstPoint + (LastPoint - FirstPoint).GetSafeNormal2D() * 1500.0 + FVector::UpVector * 800.0;
		CamSpline.SplinePoints.Add(FHazeSplinePoint(FirstPoint));
		//CamSpline.SplinePoints.Add(FHazeSplinePoint(MidPoint));
		CamSpline.SplinePoints.Add(FHazeSplinePoint(LastPoint));
		CamSpline.UpdateSpline();

		Player.ActivateCameraCustomBlend(References.EnterCamera, CoastBossAeronauticKeepVelocityBlend, 1.0, this);
		Player.BlockCapabilities(CameraTags::CameraAlignWithWorldUp, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		HealthComp.RemoveDamageInvulnerability(this);
		AirMoveDataComp.bCameraShouldBlendInFromEnter = false;
		AirMoveDataComp.bShouldPlayerEnter = false;
		Player.StopSlotAnimation();

		Player.DeactivateCamera(References.EnterCamera);
		Player.UnblockCapabilities(CameraTags::CameraAlignWithWorldUp, this);
		Player.UnblockCapabilities(CoastBossTags::CoastBossPlayerShootTag, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (References == nullptr)
			return;

		float Alpha = Math::Clamp(ActiveDuration / AirMoveDataComp.PlayerEnterDuration, 0.0, 1.0);
		if(Alpha >= 1.0)
		{
			Alpha = 1.0;
			AirMoveDataComp.bShouldPlayerEnter = false;
		}
		if(Alpha > 0.5)
			AirMoveDataComp.bCameraShouldBlendInFromEnter = true;

		Alpha = AeronauticEnterCurve.GetFloatValue(Alpha);
		
		FVector Location;
		FQuat Quat;

		Spline.GetLocationAndQuatAtDistance(Alpha * Spline.Length, Location, Quat);
		Location = References.CoastBossPlane2D.ActorTransform.TransformPositionNoScale(Location);
		Quat = References.PlaneRespawnPoint.ActorQuat;
		// Quat = References.CoastBossPlane2D.ActorTransform.TransformRotation(Quat);
		// if(Alpha > 0.9)
		// 	Quat = FQuat::MakeFromXZ(FVector::RightVector, FVector::UpVector) * References.PlaneRespawnPoint.ActorQuat;
		// else
		// 	Quat = FQuat::MakeFromZX(FVector::UpVector, Quat.ForwardVector);
		
		if(IsDebugActive())
		{
			References.EnterCamera.CameraSpline.DrawDebug();
			Spline.DrawDebugSplineRelativeTo(References.CoastBossPlane2D.ActorTransform);
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
};