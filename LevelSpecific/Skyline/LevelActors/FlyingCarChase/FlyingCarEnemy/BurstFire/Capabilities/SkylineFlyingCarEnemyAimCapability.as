class USkylineFlyingCarEnemyAimCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Local;

	default CapabilityTags.Add(CapabilityTags::GameplayAction);		

	default TickGroup = EHazeTickGroup::BeforeGameplay;

	ASkylineFlyingCarEnemyShip CarEnemy;

	FRotator AccRotation;

	FHazeAcceleratedVector AccAimAheadAmount;
	USkylineFlyingCarEnemyShipSettings Settings;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		CarEnemy = Cast<ASkylineFlyingCarEnemyShip>(Owner);
		Settings = USkylineFlyingCarEnemyShipSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(CarEnemy.HealthComponent.IsDead())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(CarEnemy.HealthComponent.IsDead())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		AccAimAheadAmount.SnapTo(FVector::ZeroVector);
		AccRotation = FRotator::ZeroRotator;
		ApplyRotation();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		AccAimAheadAmount.AccelerateTo(SkylineFlyingCarEnemy::GetPlayerFlyingCar().ActorVelocity * Settings.AimAheadTime, Settings.AimAheadDuration, DeltaTime);
		const FVector TargetLocation = GetTargetLocation();
		const FVector RelativeTargetLocation = CarEnemy.CannonPivot.WorldTransform.InverseTransformPositionNoScale(TargetLocation);
		FRotator RelativeTargetRotation = FRotator::MakeFromXZ(RelativeTargetLocation.GetSafeNormal(), FVector::UpVector);

		//RelativeTargetRotation.Roll = 0;
		AccRotation = Math::RInterpConstantTo(AccRotation, RelativeTargetRotation, DeltaTime, 10);

		ApplyRotation();
	}

	void ApplyRotation()
	{
		AccRotation.Pitch = Math::Clamp(AccRotation.Pitch, Settings.MinPitch, Settings.MaxPitch);
		
		CarEnemy.CannonPivot.SetRelativeRotation(FRotator(AccRotation.Pitch, AccRotation.Yaw, 0));
	}

	
	FVector GetTargetLocation() const
	{
		FVector TargetLocation = SkylineFlyingCarEnemy::GetDriverPlayer().ActorLocation;
		TargetLocation += AccAimAheadAmount.Value;
		
		return TargetLocation;
	}
};