class UWaveRaftMovementCapability : UHazeCapability
{
	default CapabilityTags.Add(SummitRaftTags::WaveRaft);
	default TickGroup = EHazeTickGroup::Movement;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	AWaveRaft WaveRaft;

	UWaveRaftMovementComponent MoveComp;
	USummitWaveRaftMovementData Movement;

	UWaveRaftSettings RaftSettings;

	FHazeAcceleratedFloat AccHeight;
	FHazeAcceleratedVector AccUp;

	TPerPlayer<UWaveRaftPlayerComponent> RaftComps;

	bool bWasFalling = false;

	const float InWaterUpRotationStiffness = 12.0;
	const float OnGroundUpRotationDuration = 0.2;

	FVector Velocity;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		WaveRaft = Cast<AWaveRaft>(Owner);

		MoveComp = UWaveRaftMovementComponent::Get(Owner);
		Movement = MoveComp.SetupMovementData(USummitWaveRaftMovementData);

		RaftSettings = UWaveRaftSettings::GetSettings(WaveRaft);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if (!WaveRaft.SplinePos.IsValid())
			return false;

		// if (WaveRaft.bRaftIsOnWave)
		// 	return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		// if (WaveRaft.bRaftIsOnWave)
		// 	return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		for (auto Player : Game::Players)
			RaftComps[Player] = UWaveRaftPlayerComponent::Get(Player);

		AccHeight.SnapTo(WaveRaft.ActorLocation.Z);
		Velocity = WaveRaft.ActorVelocity;

		// AccFrontHeight.SnapTo(WaveRaft.SampleComponents[0].WorldLocation.Z);
		// AccBackHeight.SnapTo(WaveRaft.SampleComponents[3].WorldLocation.Z);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!WaveRaft.bIsFalling && bWasFalling)
			LandInWater();
		else if (WaveRaft.bIsFalling && !bWasFalling)
			StartFalling();

		float AverageHeight = WaveRaft.GetAverageWaterHeight();
		bWasFalling = WaveRaft.bIsFalling;

		if (MoveComp.PrepareMove(Movement))
		{
			FSplinePosition SplinePos = WaveRaft.SplineComp.GetClosestSplinePositionToWorldLocation(WaveRaft.ActorLocation);
			WaveRaft.SplinePos = SplinePos;
			FVector MovementDelta = FVector::ZeroVector;
			if (HasControl())
			{
				InterpBackOffset(DeltaTime);

				if (!WaveRaft.bIsFalling || RaftSettings.bUseAutoSteering)
				{
					WaveRaft.AccCurrentRaftSpeed.AccelerateTo(RaftSettings.RaftForwardTargetSpeed, RaftSettings.RaftForwardAccelerationDuration, DeltaTime);
					Velocity = WaveRaft.AccWaveRaftRotation.Value.ForwardVector * WaveRaft.AccCurrentRaftSpeed.Value;

					Movement.SetRotation(WaveRaft.AccWaveRaftRotation.Value);
					float DeltaToWater = WaveRaft.ActorLocation.Z - AverageHeight;
					//Print(f"{DeltaToWater=}", 1);
					
					AccHeight.SpringTo(AverageHeight, Math::Abs(DeltaToWater) * RaftSettings.BuoyancyPerUnitUnderwater, 0.4, DeltaTime);
					FVector TargetLocation = WaveRaft.ActorLocation;
					// if (RaftSettings.bUseAutoSteering)
					// {
					// 	TargetLocation.Z = SplinePos.WorldLocation.Z;
					// }
					// else
					TargetLocation.Z = AccHeight.Value;
					Movement.AddDelta(TargetLocation - WaveRaft.ActorLocation, EMovementDeltaType::VerticalExclusive);


					TEMPORAL_LOG(WaveRaft)
						.Status("In Water", FLinearColor::Blue);
					WaveRaft.bRaftIsInWater = true;
				}
				else
				{
					FWaveRaftAirborneEventParams AirborneParams;
					AirborneParams.WaveRaftLocation = WaveRaft.ActorLocation;
					UWaveRaftEventHandler::Trigger_WhileAirborne(WaveRaft, AirborneParams);
					if (!RaftSettings.bUseAutoSteering)
					{
						Acceleration::ApplyAccelerationToVelocity(Velocity, FVector::DownVector * RaftSettings.GravityForce, DeltaTime, MovementDelta);
					}
					InterpBackOffset(DeltaTime);

					TEMPORAL_LOG(WaveRaft)
						.Status("In Air", FLinearColor::White);
					WaveRaft.bRaftIsInWater = false;
				}

				TEMPORAL_LOG(WaveRaft).Value("Velocity", Velocity);

				MovementDelta += Velocity * DeltaTime;
				Movement.AddDeltaWithCustomVelocity(MovementDelta, Velocity);
			}
			else
			{
				if (!WaveRaft.bIsFalling)
					Movement.ApplyCrumbSyncedGroundMovement();
				else
					Movement.ApplyCrumbSyncedAirMovement();
			}
			Bob();
			MoveComp.ApplyMove(Movement);
		}
		Game::Mio.SetActorVelocity(MoveComp.Velocity);
		Game::Zoe.SetActorVelocity(MoveComp.Velocity);
	}

	private void LandInWater()
	{
		FWaveRaftWaterLandingEventParams Params;
		Params.WaveRaftLocation = WaveRaft.ActorLocation;
		UWaveRaftEventHandler::Trigger_OnWaterLanding(WaveRaft, Params);

		// WaveRaft.ActorVerticalVelocity *= RaftSettings.LandingInWaterVerticalSpeedMultiplier;
		AccHeight.SnapTo(WaveRaft.ActorLocation.Z - 50);
		WaveRaft.bRaftIsInWater = true;

		if (WaveRaft.bHasQueuedBigJumpLanding)
		{
			for (auto Player : Game::Players)
			{
				Player.PlayForceFeedback(WaveRaft.BigJumpFF, this);
				Player.PlayCameraShake(WaveRaft.BigJumpCamShake, this);
			}

			WaveRaft.bHasQueuedBigJumpLanding = false;
		}
		else if (WaveRaft.bHasQueuedSmallJumpLanding)
		{
			for (auto Player : Game::Players)
			{
				Player.PlayForceFeedback(WaveRaft.SmallJumpFF, this);
				Player.PlayCameraShake(WaveRaft.SmallJumpCamShake, this);
			}
			
			WaveRaft.bHasQueuedSmallJumpLanding = false;
		}
	}

	private void StartFalling()
	{
		// WaveRaft.ActorVerticalVelocity = MoveComp.WorldUp * AccHeight.Velocity;
		WaveRaft.bRaftIsInWater = false;
	}

	void Bob()
	{
		FRotator VehicleRotation;
		if (HasControl())
			VehicleRotation = WaveRaft.AccWaveRaftRotation.Value;
		else
			VehicleRotation = WaveRaft.ActorRotation;
		// VehicleRotation.Pitch = 0.0;
		VehicleRotation.Roll += Math::Sin(ActiveDuration * RaftSettings.RockFrequency) * RaftSettings.RockMagnitude;

		FVector VehicleLocation = FVector::ZeroVector;
		VehicleLocation.Z += (Math::Sin(ActiveDuration * RaftSettings.UpwardsBobbingFrequency) - 0.7) * 0.5 * RaftSettings.UpwardsBobbingMagnitude;
		WaveRaft.VehicleOffsetRoot.SetRelativeLocation(VehicleLocation);
		WaveRaft.VehicleOffsetRoot.SetWorldRotation(VehicleRotation);
	}

	void InterpBackOffset(float DeltaTime)
	{
		FRotator VehicleRotation = Math::RInterpTo(WaveRaft.VehicleOffsetRoot.RelativeRotation, FRotator::ZeroRotator, DeltaTime, 20);
		WaveRaft.VehicleOffsetRoot.SetRelativeRotation(VehicleRotation);

		FVector VehicleLocation = Math::VInterpTo(WaveRaft.VehicleOffsetRoot.RelativeLocation, FVector::ZeroVector, DeltaTime, 2);
		WaveRaft.VehicleOffsetRoot.SetRelativeLocation(VehicleLocation);
	}
};