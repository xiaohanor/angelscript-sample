struct FSkylineBossTankChaseActivateParams
{
	AHazeActor TargetToChangeTo;
	AHazeActor AttackTarget;
};

class USkylineBossTankChaseCapability : USkylineBossTankChildCapability
{
	default CapabilityTags.Add(SkylineBossTankTags::SkylineBossTankMovement);
	default CapabilityTags.Add(SkylineBossTankTags::SkylineBossTankChase);

	FHazeAcceleratedFloat Speed;
	FHazeAcceleratedFloat TurnSpeed;

	FHazeAcceleratedQuat AccQuat;

	AHazeActor Target;

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FSkylineBossTankChaseActivateParams& Params) const
	{
//		if (BossTank.State.Get() != ESkylineBossTankState::Chasing)
//			return false;

		if (!BossTank.HasAttackTarget())
			return false;

		Params.TargetToChangeTo = BossTank.GetBikeFromTarget(BossTank.GetAttackTarget()).GetDriver().OtherPlayer;
		Params.AttackTarget = BossTank.GetAttackTarget();

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
//		if (BossTank.State.Get() != ESkylineBossTankState::Chasing)
//			return true;

		if (!BossTank.HasAttackTarget())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FSkylineBossTankChaseActivateParams Params)
	{
		// Set target change timer
		BossTank.SetTargetChange(Params.TargetToChangeTo, 26.0);

		BossTank.OnChase.Broadcast();

		Speed.SnapTo(0.0, 0.0);
		TurnSpeed.SnapTo(0.0, 0.0);
		AccQuat.SnapTo(BossTank.ActorQuat, FVector::ZeroVector);

		Target = Params.AttackTarget;

//		UGravityBikeFreeSettings::SetMaxSpeedMultiplier(BossTank.GetBikeFromTarget(Target), BossTank.ChasedPlayerMaxSpeedMultiplier, this);
//		UGravityBikeFreeSettings::SetMaxSpeedMultiplier(BossTank.GetBikeFromTarget(Target).GetOtherBike(), BossTank.HunterPlayerMaxSpeedMultiplier, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Speed.SnapTo(0.0, 0.0);
		TurnSpeed.SnapTo(0.0, 0.0);
		AccQuat.SnapTo(BossTank.ActorQuat, FVector::ZeroVector);

		BossTank.GetBikeFromTarget(Target).ClearSettingsByInstigator(this);
		BossTank.GetBikeFromTarget(Target).GetDriver().ClearPointOfInterestByInstigator(this);

//		UGravityBikeFreeSettings::ClearMaxSpeedMultiplier(BossTank.GetBikeFromTarget(Target), this);
//		UGravityBikeFreeSettings::ClearMaxSpeedMultiplier(BossTank.GetBikeFromTarget(Target).GetOtherBike(), this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(HasControl())
			TickControl(DeltaTime);
		else
			TickRemote(DeltaTime);
	}

	void TickControl(float DeltaTime)
	{
		FVector ToTarget = (BossTank.GetAttackTarget().ActorLocation - BossTank.ActorLocation).ConstrainToPlane(FVector::UpVector);
		FVector Direction = ToTarget.SafeNormal;
		float Distance = ToTarget.Size();

		float DistanceBasedSpeed = Math::GetMappedRangeValueClamped(FVector2D(5000.0, 20000.0), FVector2D(BossTank.InstigatedSpeed.Get(), BossTank.InstigatedSpeed.Get() * 1.8), Distance);

//		DistanceBasedSpeed = BossTank.InstigatedSpeed.Get();

		Speed.AccelerateTo(DistanceBasedSpeed, 5.0, DeltaTime);
//		Speed.AccelerateTo(BossTank.InstigatedSpeed.Get(), 5.0, DeltaTime);

		PrintToScreen("DistanceBasedSpeed:" + DistanceBasedSpeed);

		float TurnRate = BossTank.MaxTurnRate * (1.0 - Math::Clamp(Math::NormalizeToRange(Distance, 4000.0, 20000.0), 0.0, 0.3));
		
		TurnSpeed.AccelerateTo(TurnRate, 3.0, DeltaTime);
		
		FVector NewDirection = BossTank.ActorQuat.ForwardVector.RotateVectorTowardsAroundAxis(Direction, FVector::UpVector, TurnSpeed.Value * 280.0 * DeltaTime);

		const FQuat TargetRotation = FQuat::MakeFromZX(FVector::UpVector, NewDirection);
		AccQuat.SpringTo(TargetRotation, 30.0, 0.35, DeltaTime);

		BossTank.ActorQuat = AccQuat.Value;
		BossTank.Velocity = BossTank.ActorForwardVector.VectorPlaneProject(FVector::UpVector) * Speed.Value;
	}

	void TickRemote(float DeltaTime)
	{
		const FHazeSyncedActorPosition& Position = BossTank.SyncedActorPositionComp.GetPosition();	
		BossTank.SetActorRotation(Position.WorldRotation);
		BossTank.SetActorVelocity(Position.WorldVelocity);
	}
}