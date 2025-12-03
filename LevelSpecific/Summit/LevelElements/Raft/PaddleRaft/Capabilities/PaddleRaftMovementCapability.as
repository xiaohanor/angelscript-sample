class UPaddleRaftMovementCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(SummitRaftTags::PaddleRaft);
	default TickGroup = EHazeTickGroup::BeforeMovement;
	default DebugCategory = SummitRaftDebug::SummitRaft;

	APaddleRaft PaddleRaft;
	UHazeMovementComponent MoveComp;
	USummitPaddleRaftMovementData Movement;
	TPerPlayer<UPaddleRaftPlayerComponent> RaftComps;

	APaddleRaftWaterSpline WaterSpline;

	UPaddleRaftSettings RaftSettings;

	FVector StartVehicleLocation;

	bool bWasInWater = false;
	bool bWasInAir = false;

	FHazeAcceleratedFloat AccHeight;
	FHazeAcceleratedFloat AccBackHeight;
	FHazeAcceleratedFloat AccFrontHeight;
	FHazeAcceleratedVector AccWaterNormal;

	float CurrentDesiredRotationSpeed;
	float CurrentForwardSpeed;

	float CurrentRotationFrac = 0;
	float CurrentForwardFrac = 0;

	bool bBothPlayersPaddlingSameSide = false;
	bool bPlayersWantToGoForward = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PaddleRaft = Cast<APaddleRaft>(Owner);

		MoveComp = UHazeMovementComponent::Get(Owner);
		Movement = MoveComp.SetupMovementData(USummitPaddleRaftMovementData);

		TListedActors<APaddleRaftWaterSpline> WaterSplines;
		WaterSpline = WaterSplines.GetSingle();

		RaftSettings = UPaddleRaftSettings::GetSettings(PaddleRaft);

		StartVehicleLocation = PaddleRaft.VehicleOffsetRoot.RelativeLocation;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!PaddleRaft.bHasStarted)
			return false;

		if (PaddleRaft.IsActorDisabled())
			return false;

		if (SceneView::FullScreenPlayer == nullptr)
			return false;

		// if (SceneView::FullScreenPlayer.bIsParticipatingInCutscene)
		// 	return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!PaddleRaft.bHasStarted)
			return true;

		if (PaddleRaft.IsActorDisabled())
			return true;

		if (SceneView::FullScreenPlayer == nullptr)
			return true;

		// if (SceneView::FullScreenPlayer.bIsParticipatingInCutscene)
		// 	return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		for (auto Player : Game::Players)
			RaftComps[Player] = UPaddleRaftPlayerComponent::Get(Player);

		AccHeight.SnapTo(PaddleRaft.ActorLocation.Z);
		PaddleRaft.AccRoll.SnapTo(0.0);

		// Snap to water surface

		FVector RaftLocation = PaddleRaft.ActorLocation;
		RaftLocation.Z = PaddleRaft.GetAverageWaterHeight();
		PaddleRaft.ActorLocation = RaftLocation;
		AccFrontHeight.SnapTo(PaddleRaft.SampleComponents[0].WorldLocation.Z);
		AccBackHeight.SnapTo(PaddleRaft.SampleComponents[2].WorldLocation.Z);
		AccWaterNormal.SnapTo(FVector::UpVector);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnLogState(FTemporalLog TemporalLog)
	{
		TemporalLog.Sphere("SplinePos", PaddleRaft.SplinePos.WorldLocation, 100);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float AverageHeight = PaddleRaft.GetAverageWaterHeight();
		bool bIsInWater = PaddleRaft.HasWaterBellow();
		bool bIsInAir = !bIsInWater;

		if (bIsInWater && !bWasInWater)
			LandInWater();
		else if (bIsInAir && !bWasInAir)
			StartFalling();

		bWasInWater = bIsInWater;
		bWasInAir = bIsInAir;

		if (MoveComp.PrepareMove(Movement))
		{
			if (HasControl())
			{
				PaddleRaft.SplinePos = WaterSpline.Spline.GetClosestSplinePositionToWorldLocation(PaddleRaft.ActorLocation);

				auto Settings = WaterSpline.GetSettingsAtLength(PaddleRaft.SplinePos.CurrentSplineDistance);
				PaddleRaft.ClearSettingsByInstigator(this);
				if (Settings != nullptr)
				{
					PaddleRaft.ApplySettings(Settings, this, EHazeSettingsPriority::Override);
				}

				bBothPlayersPaddlingSameSide = PaddleRaft.CheckPlayersPaddlingSameSide();

				bool bBothPlayersPaddling = PaddleRaft.IsPlayerPaddling(Game::Mio) && PaddleRaft.IsPlayerPaddling(Game::Zoe);
				bPlayersWantToGoForward = bBothPlayersPaddling && !bBothPlayersPaddlingSameSide;

				UpdateYawSpeed(DeltaTime);

				FRotator CurrentRotation = PaddleRaft.ActorRotation;
				CurrentRotation += FRotator(0, PaddleRaft.YawSpeed * DeltaTime, 0);

				FRotator Rotation = CurrentRotation;
				FVector FrontLeft = PaddleRaft.SampleComponents[0].GetWaterLocation(PaddleRaft.WaterSplineActor.Spline);
				FVector FrontRight = PaddleRaft.SampleComponents[1].GetWaterLocation(PaddleRaft.WaterSplineActor.Spline);
				FVector BackLeft = PaddleRaft.SampleComponents[2].GetWaterLocation(PaddleRaft.WaterSplineActor.Spline);
				FVector BackRight = PaddleRaft.SampleComponents[3].GetWaterLocation(PaddleRaft.WaterSplineActor.Spline);

				FVector FrontMiddle = (FrontLeft + FrontRight) * 0.5;
				FVector BackMiddle = (BackLeft + BackRight) * 0.5;
				AccFrontHeight.AccelerateTo(FrontMiddle.Z, 0.5, DeltaTime);
				AccBackHeight.AccelerateTo(BackMiddle.Z, 0.25, DeltaTime);

				FrontMiddle.Z = AccFrontHeight.Value;
				BackMiddle.Z = AccBackHeight.Value;
				FVector Forward = (FrontMiddle - BackMiddle).GetSafeNormal();
				FVector Right = PaddleRaft.ActorRightVector;
				FVector Up = Forward.CrossProduct(Right).GetSafeNormal();

				// abs it so we never have the normal from underneath the water downwards
				Up.Z = Math::Abs(Up.Z);
				// Debug::DrawDebugDirectionArrow(PaddleRaft.ActorLocation, Up, 1000, 20, FLinearColor::LucBlue, 5, 100);

				AccWaterNormal.AccelerateTo(Up, 0.2, DeltaTime);
				Rotation = FRotator::MakeFromXZ(CurrentRotation.ForwardVector.VectorPlaneProject(AccWaterNormal.Value), AccWaterNormal.Value);
				Movement.WaterUp = AccWaterNormal.Value;

				Movement.SetRotation(Rotation);
				FRotator MeshRollRotation = PaddleRaft.MeshOffsetComp.RelativeRotation;
				PaddleRaft.AccRoll.SpringTo(0, 5, 0.2, DeltaTime);
				MeshRollRotation.Roll = PaddleRaft.AccRoll.Value;
				PaddleRaft.MeshOffsetComp.RelativeRotation = MeshRollRotation;
				FVector VelocityAlignmentUp = AccWaterNormal.Value;

				FVector Velocity = MoveComp.Velocity.VectorPlaneProject(VelocityAlignmentUp);

				UpdateForwardSpeed(Velocity, DeltaTime);
				// NB: Changed the clamp to be on forwardspeed instead of velocity, so we can add impact impulses without them being clamped to irrelevancy //David

				float ForwardSpeed = Velocity.DotProduct(Rotation.ForwardVector);
				ForwardSpeed = Math::Clamp(ForwardSpeed, -RaftSettings.MaxRaftSpeed, RaftSettings.MaxRaftSpeed);
				ForwardSpeed = Math::FInterpTo(ForwardSpeed, 0.0, DeltaTime, RaftSettings.ForwardDeceleration);
				float RightSpeed = Velocity.DotProduct(Rotation.RightVector);
				RightSpeed = Math::FInterpTo(RightSpeed, 0.0, DeltaTime, RaftSettings.SidewaysDeceleration);

				FVector CurrentVelocity = (Rotation.ForwardVector * ForwardSpeed) + (Rotation.RightVector * RightSpeed);

				FVector WaterCurrentAcceleration = GetWaterCurrentAcceleration(DeltaTime);
				FVector PushingForce = PaddleRaft.GetPushingVolumeForce() * DeltaTime;

				CurrentVelocity += WaterCurrentAcceleration + PushingForce;
				CurrentVelocity = CurrentVelocity.VectorPlaneProject(VelocityAlignmentUp);

				Movement.AddVelocity(CurrentVelocity);

				FVector WaterUp = PaddleRaft.SplinePos.WorldUpVector;
				FVector RaftForwardOnWater = PaddleRaft.ActorForwardVector.VectorPlaneProject(WaterUp);

				TEMPORAL_LOG(PaddleRaft)
					.DirectionalArrow("Forward", PaddleRaft.ActorLocation, Rotation.ForwardVector * 500, 5, 40, FLinearColor::Red)
					.DirectionalArrow("MoveComp Velocity", PaddleRaft.ActorLocation, MoveComp.Velocity, 5, 40, FLinearColor::White)
					.DirectionalArrow("CurrentVelocity", PaddleRaft.ActorLocation, CurrentVelocity, 5, 40, FLinearColor::White)
					.DirectionalArrow("Water Current Acceleration", PaddleRaft.ActorLocation, WaterCurrentAcceleration, 5, 40, FLinearColor::LucBlue)
					.DirectionalArrow("AccWaterNormal", PaddleRaft.ActorLocation, AccWaterNormal.Value * 500, 5, 40, FLinearColor::Blue)
					.Sphere("Front Middle", FrontMiddle, 50, FLinearColor::DPink, 3)
					.Sphere("Back Middle", BackMiddle, 50, FLinearColor::LucBlue, 3)
					.Value("Is In water", bIsInWater)
					.Value("Is In air", bIsInAir)
					.Value("Yaw Speed", PaddleRaft.YawSpeed)
					.Value("ForwardSpeed", ForwardSpeed)
					.Value("Acc Roll", PaddleRaft.AccRoll.Value)
					.Value("RapidsDeviationAlpha", GetRapidsDeviationAlpha(RaftForwardOnWater))
					.Value("RapidsAlignmentSpeed", GetRapidsReAlignmentSpeed())
					.DirectionalArrow("RaftForwardOnWater", PaddleRaft.ActorLocation, RaftForwardOnWater * 500, 5, 40, FLinearColor(1.00, 0.42, 0.42))
					.DirectionalArrow("WaterForward", PaddleRaft.ActorLocation, PaddleRaft.SplinePos.WorldForwardVector * 500, 5, 40, FLinearColor(0.36, 0.76, 1.00));
				// Make sure we're always going down to the plane of the water if we've been bumped upward
				if (bIsInWater)
				{
					float WaterHeight = PaddleRaft.SplinePos.WorldLocation.Z;
					float DeltaToWater = PaddleRaft.ActorLocation.Z + PaddleRaft.CollisionCapsule.BoundsExtent.Z - WaterHeight;
					float Stiffness = Math::Abs(DeltaToWater) * RaftSettings.BuoyancyPerUnitUnderwater;

					AccHeight.AccelerateTo(WaterHeight, 0.2, DeltaTime);

					TEMPORAL_LOG(PaddleRaft)
						.Value("Delta To Water", DeltaToWater)
						.Value("Height Spring Stiffness", Stiffness)
						.Value("AccHeight", AccHeight.Value);

					FVector TargetLocation = PaddleRaft.SplinePos.WorldLocation;
					Movement.AddDelta(TargetLocation - PaddleRaft.ActorLocation, EMovementDeltaType::VerticalExclusive);
				}
				else if (bIsInAir)
				{
					Movement.AddOwnerVerticalVelocity();
					Movement.AddGravityAcceleration();
				}
			}
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}

			MoveComp.ApplyMove(Movement);
			Bob(PaddleRaft.YawSpeed);
		}

		// FVector MoveDir = MoveComp.Velocity.GetSafeNormal();
		// float BushWobbleSpeed = Math::Clamp(MoveComp.Velocity.Size() * 500, 300000, 500000);
		Game::Mio.SetActorVelocity(MoveComp.Velocity);
		Game::Zoe.SetActorVelocity(MoveComp.Velocity);
	}

	void LandInWater()
	{
		// PaddleRaft.ActorVerticalVelocity *= RaftSettings.LandingInWaterVerticalSpeedMultiplier;
		AccHeight.SnapTo(PaddleRaft.ActorLocation.Z, MoveComp.VerticalSpeed);
	}

	void StartFalling()
	{
		PaddleRaft.ActorVerticalVelocity = MoveComp.WorldUp * AccHeight.Velocity;
	}

	FVector GetWaterCurrentAcceleration(float DeltaTime)
	{
		return PaddleRaft.SplinePos.WorldForwardVector * RaftSettings.RapidsAcceleration * DeltaTime;
	}

	/**
	 * How much the raft forward deviates from the Rapids direction
	 */
	float GetRapidsDeviationAlpha(FVector RaftForwardOnWater, float AlphaOffset = 0) const
	{
		float RapidsForwardDot = RaftForwardOnWater.DotProduct(PaddleRaft.SplinePos.WorldForwardVector);
		float DeviationAlpha = Math::Saturate(Math::Abs(1 - RapidsForwardDot) - AlphaOffset);
		return DeviationAlpha;
	}

	float GetRapidsReAlignmentSpeed() const
	{
		FVector WaterUp = PaddleRaft.SplinePos.WorldUpVector;
		FVector RaftForwardOnWater = PaddleRaft.ActorForwardVector.VectorPlaneProject(WaterUp);
		float RapidsRightDot = RaftForwardOnWater.DotProduct(PaddleRaft.SplinePos.WorldRightVector);
		float YawDirection = -Math::Sign(RapidsRightDot);
		float DeviationAlpha = GetRapidsDeviationAlpha(RaftForwardOnWater, RaftSettings.RapidsReAlignmentAlphaOffset);
		float AlignmentSpeed = DeviationAlpha * YawDirection * RaftSettings.RapidsRotationAlignmentMaxSpeed;
		return AlignmentSpeed;
	}

	void UpdateForwardSpeed(FVector& CurrentVelocity, float DeltaTime)
	{
		FVector Acceleration = PaddleRaft.ActorForwardVector * PaddleRaft.GetTotalForwardPaddleSpeed() * DeltaTime;
		if (bPlayersWantToGoForward)
			Acceleration += PaddleRaft.ActorForwardVector * RaftSettings.SameSideBonusRotationSpeed * DeltaTime;

		CurrentVelocity += Acceleration;
	}

	void UpdateYawSpeed(float DeltaTime)
	{
		float DesiredRotationSpeed = PaddleRaft.GetTotalPaddleRotationSpeed();
		if (bPlayersWantToGoForward)
			DesiredRotationSpeed = 0;
		else if (bBothPlayersPaddlingSameSide)
			DesiredRotationSpeed += Math::Sign(DesiredRotationSpeed) * RaftSettings.SameSideBonusRotationSpeed;

		DesiredRotationSpeed = Math::Clamp(DesiredRotationSpeed, -RaftSettings.RaftMaxRotationSpeed, RaftSettings.RaftMaxRotationSpeed);

		if (!Math::IsNearlyZero(DesiredRotationSpeed))
			CurrentDesiredRotationSpeed = Math::FInterpConstantTo(CurrentDesiredRotationSpeed, DesiredRotationSpeed, DeltaTime, 100);
		else
			CurrentDesiredRotationSpeed = 0;
		
		PaddleRaft.YawSpeed += CurrentDesiredRotationSpeed * DeltaTime;

		// Add yawspeed depending on alignment with watercurrent so that it becomes harder to turn against the stream
		PaddleRaft.YawSpeed = Math::FInterpTo(PaddleRaft.YawSpeed, 0, DeltaTime, 0.6);
		PaddleRaft.YawSpeed += GetRapidsReAlignmentSpeed();
		PaddleRaft.YawSpeed = Math::Clamp(PaddleRaft.YawSpeed, -RaftSettings.RaftMaxRotationSpeed, RaftSettings.RaftMaxRotationSpeed);
	}

	void Bob(float RotationSpeed)
	{
		// Apply some bobbing to the raft
		FRotator VehicleRotation;
		VehicleRotation.Roll = Math::Sin(ActiveDuration * 3.17);
		//VehicleRotation.Pitch = Math::Sin(ActiveDuration * 2.334);

		VehicleRotation.Roll += Math::Clamp(RotationSpeed * 2.5 / 180.0, -15.0, 15.0);

		FVector VehicleLocation = StartVehicleLocation;
		PaddleRaft.VehicleOffsetRoot.SetRelativeLocationAndRotation(VehicleLocation, VehicleRotation);
	}
};