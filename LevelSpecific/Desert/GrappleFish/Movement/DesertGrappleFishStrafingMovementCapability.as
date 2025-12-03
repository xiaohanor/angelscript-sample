class UDesertGrappleFishStrafingMovementCapability : UHazeCapability
{
	// default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	// default CapabilityTags.Add(CapabilityTags::Movement);

	// default TickGroup = EHazeTickGroup::Movement;
	// default TickGroupOrder = 90;

	// ADesertGrappleFish GrappleFish;
	// UHazeMovementComponent MoveComp;
	// USimpleMovementData Movement;

	// // Speed in spline forward when rubberband should slow us down
	// const float RubberBandSpeedMin = 800;

	// // Default forward speed with no rubberbanding
	// const float SpeedNoRubberBand = 2800;

	// // Forward speed when we try to catch up to other shark
	// const float RubberBandSpeedMax = 3200;

	// // Distance cap for when full max/min rubberband will be used
	// const float RubberBandDistMax = 9000;

	// // Horizontal speed, in right vector of spline
	// const float TargetHorizontalMoveSpeed = 1000;

	// // How quickly we reach max horizontal speed with player input
	// float HorizontalAccelerationDuration = 1.0;
	
	// // How quickly our horizontal speed goes back to 0 with no player input
	// float HorizontalDecelerationDuration = 2.0;

	// // How much the shark rolls towards input direction
	// float MaxRollAmount = 25;
	// // How quickly the shark rolls
	// float RollInterpSpeed = 0.6;

	// // How much the shark yaws towards input direction
	// float MaxYawAmount = 15;
	// // How quickly the shark yaws
	// float YawInterpSpeed = 0.6;

	// // Animation turning blend cap, 1.0 will make the shark turn close to 90 degrees
	// float MaxBlendFrac = 0.65;
	// // How quickly the shark reaches max blend
	// float BlendInterpSpeed = 2.0;

	// // How quickly the shark accelerates in Z to the height of landscape, lower values will make shark stick to ground but makes small bumps noticable
	// float LandscapeHeightAccelerationDuration = 0.15;

	// // How quickly the shark turns, when not facing opposite direction of input
	// float TurnAccelerationDuration = 0.15;
	// // How quickly the shark turns back when we stop giving input
	// float NoInputTurnAccelerationDuration = 0.5;
	// // How quickly the shark turns when the direction changes, ie. we input right when shark is currently going left
	// float ChangeDirectionTurnAccelerationDuration = 0.5;

	// // When auto piloting the shark will maintain its previous horizontal spline offset, this controls the tolerance for when it's considered close enough
	// float AutoPilotHorizontalStopDistance = 10.0;

	// float AutoPilotTurnBackAccelerationDuration = 0.15;

	// float CurrentRoll;
	// float CurrentYaw;
	// float CurrentBlend;
	// FHazeAcceleratedFloat AccHorizontalSpeed;
	// FHazeAcceleratedFloat AccLandscapeHeight;
	// FHazeAcceleratedFloat AccTurningDirection;

	// bool bHadMountedPlayer = false;

	// float MountedRightOffset = 0;

	// AHazePlayerCharacter MountedPlayer;

	// UFUNCTION(BlueprintOverride)
	// void Setup()
	// {
	// 	GrappleFish = Cast<ADesertGrappleFish>(Owner);
	// 	MoveComp = UHazeMovementComponent::Get(Owner);
	// 	Movement = MoveComp.SetupMovementData(USimpleMovementData);
	// }

	// UFUNCTION(BlueprintOverride)
	// bool ShouldActivate() const
	// {
	// 	if (!GrappleFish.bIsMovingTowardsEnd)
	// 		return false;

	// 	if (!Desert::HasLandscapeForLevel(GrappleFish.LandscapeLevel))
	// 		return false;

	// 	if (Desert::GetRelevantLandscapeLevel() != GrappleFish.LandscapeLevel)
	// 		return false;

	// 	return true;
	// }

	// UFUNCTION(BlueprintOverride)
	// bool ShouldDeactivate() const
	// {
	// 	if (!GrappleFish.bIsMovingTowardsEnd)
	// 		return true;

	// 	if (!Desert::HasLandscapeForLevel(GrappleFish.LandscapeLevel))
	// 		return false;

	// 	if (Desert::GetRelevantLandscapeLevel() != GrappleFish.LandscapeLevel)
	// 		return false;

	// 	return false;
	// }

	// UFUNCTION(BlueprintOverride)
	// void OnActivated()
	// {
	// 	MountedPlayer = GrappleFish.MountedPlayer;
	// 	GrappleFish.State.Apply(EDesertGrappleFishState::Mounted, this, EInstigatePriority::High);
	// 	GrappleFish.AccSpeed.SnapTo(SpeedNoRubberBand);
	// 	UDesertGrappleFishEventHandler::Trigger_OnStartSwimming(Owner);
	// 	AccLandscapeHeight.SnapTo(Desert::GetLandscapeHeightByLevel(GrappleFish.SplinePosition.WorldLocation, GrappleFish.LandscapeLevel));
	// }

	// UFUNCTION(BlueprintOverride)
	// void OnDeactivated()
	// {
	// 	// MountedPlayer.ClearCameraSettingsByInstigator(this);
	// 	UDesertGrappleFishEventHandler::Trigger_OnStopSwimming(Owner);
	// }

	// UFUNCTION(BlueprintOverride)
	// void TickActive(float DeltaTime)
	// {
	// 	if (!MoveComp.PrepareMove(Movement))
	// 	{
	// 		return;
	// 	}

	// 	GrappleFish.SplinePosition = GrappleFish.SplineActor.Spline.GetClosestSplinePositionToWorldLocation(GrappleFish.ActorLocation);
	// 	GrappleFish.AutoPilotSplinePosition = GrappleFish.AutoPilotSpline.Spline.GetClosestSplinePositionToWorldLocation(GrappleFish.ActorLocation);
	// 	FSplinePosition AutoSplinePos = GrappleFish.AutoPilotSplinePosition;
	// 	if (HasControl())
	// 	{
	// 		float DesiredMoveSpeed = GetDesiredSpeed();
	// 		GrappleFish.AccSpeed.AccelerateTo(DesiredMoveSpeed, 1, DeltaTime);

	// 		bool bHasMountedPlayer = GrappleFish.MountedPlayer != nullptr && !GrappleFish.MountedPlayer.IsPlayerDead() && !GrappleFish.MountedPlayer.IsPlayerRespawning();

	// 		FSplinePosition MovementSplinePos = GrappleFish.SplinePosition;

	// 		float PlayerHorizontalInput = GrappleFish.InfluencedHorizontalDirection.Get();

	// 		FVector ClampedTargetLocation;
	// 		FRotator MovementRot;
	// 		if (bHasMountedPlayer)
	// 		{
	// 			FVector TargetLocation = GetMountedTargetLocation(PlayerHorizontalInput, MovementSplinePos, DeltaTime);
	// 			ClampedTargetLocation = GetClampedLocationWithinBoundary(TargetLocation, GrappleFish.SplineActor);
	// 			MovementRot = MovementSplinePos.WorldRotation.Rotator() + FRotator(0, CurrentYaw, CurrentRoll);

	// 			FVector ToAutoSpline = GrappleFish.AutoPilotSpline.Spline.GetClosestSplineWorldLocationToWorldLocation(GrappleFish.ActorLocation) - GrappleFish.ActorLocation;
	// 			MountedRightOffset = AutoSplinePos.WorldRightVector.DotProduct(ToAutoSpline);
	// 		}
	// 		else
	// 		{
	// 			FVector TargetLocation = GetUnmountedTargetLocation(AutoSplinePos, DeltaTime);
	// 			ClampedTargetLocation = GetClampedLocationWithinBoundary(TargetLocation, GrappleFish.AutoPilotSpline);
	// 			MovementRot = AutoSplinePos.WorldRotation.Rotator() + FRotator(0, CurrentYaw, CurrentRoll);
	// 		}

	// 		float LandscapeHeight = Desert::GetLandscapeHeightByLevel(ClampedTargetLocation, GrappleFish.LandscapeLevel);
	// 		AccLandscapeHeight.AccelerateTo(LandscapeHeight, LandscapeHeightAccelerationDuration, DeltaTime);

	// 		ClampedTargetLocation.Z = AccLandscapeHeight.Value;
	// 		FVector MoveDelta = ClampedTargetLocation - GrappleFish.ActorLocation;

	// 		CurrentBlend = Math::FInterpTo(CurrentBlend, AccTurningDirection.Value * MaxBlendFrac, DeltaTime, BlendInterpSpeed);
	// 		GrappleFish.AnimData.TurnBlend = CurrentBlend;

	// 		CurrentRoll = Math::FInterpTo(CurrentRoll, MaxRollAmount * AccTurningDirection.Value, DeltaTime, RollInterpSpeed);
	// 		CurrentYaw = Math::FInterpTo(CurrentYaw, MaxYawAmount * AccTurningDirection.Value, DeltaTime, YawInterpSpeed);

	// 		CurrentRoll = Math::FInterpTo(CurrentRoll, 0, DeltaTime, RollInterpSpeed);
	// 		CurrentYaw = Math::FInterpTo(CurrentYaw, 0, DeltaTime, YawInterpSpeed);

	// 		bHadMountedPlayer = bHasMountedPlayer;

	// 		GrappleFish.Velocity = MoveDelta / DeltaTime;
	// 		GrappleFish.Velocity.Z = 0;

	// 		Movement.AddDelta(MoveDelta);
	// 		Movement.SetRotation(MovementRot);

	// 		MoveComp.ApplyCrumbSyncedRelativePosition(this, GrappleFish.SplineActor.Root);

	// 		if (GrappleFish.MountedPlayer != nullptr)
	// 		{
	// 			bool bPlayerInputing = !Math::IsNearlyEqual(PlayerHorizontalInput, 0.0);
	// 			float FFFrequency = bPlayerInputing ? 25.0 : 10.0;
	// 			float FFIntensity = bPlayerInputing ? 0.1 : 0.025;
	// 			float LeftFF = Math::Sin(ActiveDuration * FFFrequency) * FFIntensity;
	// 			float RightFF = Math::Sin(-ActiveDuration * FFFrequency) * FFIntensity;
	// 			GrappleFish.MountedPlayer.SetFrameForceFeedback(LeftFF, RightFF, 0.0, 0.0);
	// 		}
	// 	}
	// 	else
	// 	{
	// 		Movement.ApplyCrumbSyncedAirMovement();
	// 	}
	// 	GrappleFish.CurrentSplineCameraSettingsComp = GrappleFish.SplineActor.GetCameraSettingsComponentAtDistanceAlongSpline(GrappleFish.SplinePosition.CurrentSplineDistance);

	// 	MoveComp.ApplyMove(Movement);
	// }

	// FVector GetMountedTargetLocation(float PlayerInput, FSplinePosition MovementSplinePos, float DeltaTime)
	// {
	// 	if (!Math::IsNearlyZero(PlayerInput))
	// 	{
	// 		// Less responsive when trying to quickly change directions
	// 		if (Math::Sign(AccTurningDirection.Value) != Math::Sign(PlayerInput))
	// 			AccTurningDirection.AccelerateTo(PlayerInput, ChangeDirectionTurnAccelerationDuration, DeltaTime);
	// 		else
	// 			AccTurningDirection.AccelerateTo(PlayerInput, TurnAccelerationDuration, DeltaTime);

	// 		AccHorizontalSpeed.AccelerateTo(TargetHorizontalMoveSpeed, HorizontalAccelerationDuration, DeltaTime);
	// 	}
	// 	else
	// 	{
	// 		AccTurningDirection.AccelerateTo(0, NoInputTurnAccelerationDuration, DeltaTime);
	// 		AccHorizontalSpeed.AccelerateTo(0, HorizontalDecelerationDuration, DeltaTime);
	// 	}

	// 	FVector PoILoc = GrappleFish.ActorLocation + (GrappleFish.ActorForwardVector * 2500.0);
	// 	PoILoc += GrappleFish.ActorRightVector * (AccTurningDirection.Value * 200.0);
	// 	GrappleFish.POITarget.SetWorldLocation(PoILoc);

	// 	FVector DesiredMoveDelta = (MovementSplinePos.WorldForwardVector * GrappleFish.AccSpeed.Value + (MovementSplinePos.WorldRightVector * AccTurningDirection.Value * AccHorizontalSpeed.Value)) * DeltaTime;
	// 	return GrappleFish.ActorLocation + DesiredMoveDelta;
	// }

	// FVector GetUnmountedTargetLocation(FSplinePosition AutoSplinePos, float DeltaTime)
	// {
	// 	FVector ToSpline = AutoSplinePos.WorldLocation - GrappleFish.ActorLocation;
	// 	float Offset = AutoSplinePos.WorldRightVector.DotProduct(ToSpline);
	// 	float TargetOffset = MountedRightOffset;
	// 	if (MountedPlayer.IsPlayerDead() || MountedPlayer.IsPlayerRespawning())
	// 	{
	// 		AccHorizontalSpeed.AccelerateTo(TargetHorizontalMoveSpeed, HorizontalAccelerationDuration, DeltaTime);
	// 		TargetOffset = 0;
	// 	}

	// 	float MoveDir = -1;
	// 	if (Offset > TargetOffset + AutoPilotHorizontalStopDistance)
	// 		MoveDir = 1;
	// 	else if (Math::Abs(Offset - TargetOffset) < AutoPilotHorizontalStopDistance)
	// 		MoveDir = 0;
	// 	AccTurningDirection.AccelerateTo(MoveDir, AutoPilotTurnBackAccelerationDuration, DeltaTime);
	// 	FVector ForwardDelta = AutoSplinePos.WorldForwardVector * GrappleFish.AccSpeed.Value * DeltaTime;
	// 	FVector HorizontalDelta = AutoSplinePos.WorldRightVector * AccHorizontalSpeed.Value * MoveDir * DeltaTime;
	// 	return GrappleFish.ActorLocation + ForwardDelta + HorizontalDelta;
	// }

	// float GetDesiredSpeed()
	// {
	// 	float SplineDist = GrappleFish.SplinePosition.CurrentSplineDistance;
	// 	float OtherSharkSplineDist = GrappleFish.SplinePosition.CurrentSpline.GetClosestSplineDistanceToWorldLocation(GrappleFish.OtherFish.ActorLocation);
	// 	float Distance = GrappleFish.GetHorizontalDistanceTo(GrappleFish.OtherFish);
	// 	float DesiredSpeed = SpeedNoRubberBand;
	// 	FVector2D RubberBandRange = FVector2D(0, RubberBandDistMax);

	// 	if (GrappleFish.bIsLeadFish)
	// 	{
	// 		if (OtherSharkSplineDist > SplineDist)
	// 		{
	// 			DesiredSpeed = Math::GetMappedRangeValueClamped(RubberBandRange, FVector2D(SpeedNoRubberBand, RubberBandSpeedMax), Distance);
	// 		}
	// 		else
	// 		{
	// 			if (Distance < GrappleFish.IdealDistanceToOtherShark)
	// 				DesiredSpeed = Math::GetMappedRangeValueClamped(RubberBandRange, FVector2D(SpeedNoRubberBand, RubberBandSpeedMax), Distance);
	// 			else
	// 				DesiredSpeed = Math::GetMappedRangeValueClamped(RubberBandRange, FVector2D(SpeedNoRubberBand, RubberBandSpeedMin), Distance);
	// 		}
	// 	}
	// 	else
	// 	{
	// 		if (OtherSharkSplineDist < SplineDist)
	// 		{
	// 			DesiredSpeed = Math::GetMappedRangeValueClamped(RubberBandRange, FVector2D(SpeedNoRubberBand, RubberBandSpeedMin), Distance);
	// 		}
	// 		else
	// 		{
	// 			if (Distance < GrappleFish.IdealDistanceToOtherShark)
	// 				DesiredSpeed = Math::GetMappedRangeValueClamped(RubberBandRange, FVector2D(SpeedNoRubberBand, RubberBandSpeedMin), Distance);
	// 			else
	// 				DesiredSpeed = Math::GetMappedRangeValueClamped(RubberBandRange, FVector2D(SpeedNoRubberBand, RubberBandSpeedMax), Distance);
	// 		}
	// 	}

	// 	return DesiredSpeed;
	// }

	// FVector GetClampedLocationWithinBoundary(FVector WorldLocation, ASandSharkSpline SplineActor) const
	// {
	// 	auto SplinePosition = SplineActor.Spline.GetClosestSplinePositionToWorldLocation(WorldLocation);

	// 	FVector SplineToWantedLocation = WorldLocation - SplinePosition.WorldLocation;
	// 	float SplineBounds = SplineActor.GetGrappleFishBoundsAtSplinePosition(SplinePosition);
	// 	//Print(f"{Spline.visualiz=}", 0);

	// 	float DistanceToRight = SplinePosition.WorldRightVector.DotProduct(SplineToWantedLocation);
	// 	DistanceToRight = Math::Clamp(DistanceToRight, -SplineBounds, SplineBounds);

	// 	float DistanceUpwards = SplinePosition.WorldUpVector.DotProduct(SplineToWantedLocation);

	// 	float DistanceForwards = SplinePosition.WorldForwardVector.DotProduct(SplineToWantedLocation);
	// 	FVector ClampedLocation = SplinePosition.WorldLocation + SplinePosition.WorldForwardVector * DistanceForwards + SplinePosition.WorldRightVector * DistanceToRight + SplinePosition.WorldUpVector * DistanceUpwards;

	// 	TEMPORAL_LOG(this)
	// 		.DirectionalArrow("Distance To Right", SplinePosition.WorldLocation, SplinePosition.WorldRightVector * DistanceToRight, 50, 80, FLinearColor::Green)
	// 		.DirectionalArrow("Distance Upwards", SplinePosition.WorldLocation, SplinePosition.WorldUpVector * DistanceUpwards, 50, 80, FLinearColor::Blue)
	// 		.Sphere("Target Location", ClampedLocation, 5000, FLinearColor::LucBlue, 20)
	// 		.Sphere("Spline Location", SplinePosition.WorldLocation, 5000, FLinearColor::Yellow, 20);

	// 	return ClampedLocation;
	// }
};