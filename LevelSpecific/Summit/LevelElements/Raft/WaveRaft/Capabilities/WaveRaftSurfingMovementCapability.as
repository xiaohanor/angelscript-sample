class UWaveRaftSurfingMovementCapability : UHazeCapability
{
	default CapabilityTags.Add(SummitRaftTags::WaveRaft);
	default TickGroup = EHazeTickGroup::BeforeMovement;
	default DebugCategory = SummitRaftDebug::SummitRaft;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	AWaveRaft WaveRaft;

	UWaveRaftMovementComponent MoveComp;
	USummitWaveRaftMovementData Movement;

	UWaveRaftSettings RaftSettings;

	TPerPlayer<UWaveRaftPlayerComponent> RaftComps;

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

		if (!WaveRaft.bRaftIsOnWave)
			return false;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if (!WaveRaft.bRaftIsOnWave)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		for (auto Player : Game::Players)
			RaftComps[Player] = UWaveRaftPlayerComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
	// 	if (MoveComp.PrepareMove(Movement))
	// 	{
	// 		FSplinePosition SplinePos = WaveRaft.SplineComp.GetClosestSplinePositionToWorldLocation(WaveRaft.ActorLocation);
	// 		WaveRaft.SplinePos = SplinePos;

	// 		if (HasControl())
	// 		{
	// 			Movement.SetRotation(WaveRaft.AccWaveRaftRotation.Value);

	// 			WaveRaft.AccCurrentRaftSpeed.AccelerateTo(RaftSettings.RaftForwardTargetSpeed, RaftSettings.RaftForwardAccelerationDuration, DeltaTime);
	// 			Movement.AddVelocity(WaveRaft.AccWaveRaftRotation.Value.ForwardVector * WaveRaft.AccCurrentRaftSpeed.Value);

	// 			FVector TargetHeightLocation = SplinePos.WorldLocation + WaveRaft.ActorUpVector * RaftSettings.RaftSplineUpOffset;
	// 			Movement.AddDelta(TargetHeightLocation - WaveRaft.ActorLocation, EMovementDeltaType::VerticalExclusive);

	// 			FRotator VehicleRotation = WaveRaft.AccWaveRaftRotation.Value;
	// 			VehicleRotation.Pitch = 0.0;
	// 			VehicleRotation.Roll += Math::Sin(ActiveDuration * RaftSettings.RockFrequency) * RaftSettings.RockMagnitude;

	// 			FVector VehicleLocation = FVector::ZeroVector;
	// 			VehicleLocation.Z += Math::Sin(ActiveDuration * RaftSettings.UpwardsBobbingFrequency) * RaftSettings.UpwardsBobbingMagnitude;
	// 			WaveRaft.VehicleOffsetRoot.SetRelativeLocation(VehicleLocation);
	// 			WaveRaft.VehicleOffsetRoot.SetWorldRotation(VehicleRotation);

	// 			TEMPORAL_LOG(WaveRaft)
	// 				.Sphere("Vehicle Location", VehicleLocation, 50, FLinearColor::Red)
	// 				.Sphere("Spline Location", WaveRaft.SplinePos.WorldLocation, 100, FLinearColor::DPink, 5);
	// 				//.Sphere("AutoSteering Location", NewSplinePosition.WorldLocation, 100, FLinearColor::Yellow, 5);
	// 		}
	// 		else
	// 		{
	// 			Movement.ApplyCrumbSyncedAirMovement();
	// 		}

	// 		MoveComp.ApplyMove(Movement);
	// 	}
	}
};