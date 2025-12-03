class USkylineFlyingCarEnemyRotateCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Local;

	default CapabilityTags.Add(CapabilityTags::GameplayAction);	
	default CapabilityTags.Add(SkylineFlyingCarEnemy::Turret::SkylineCarEnemyTurretTag);

	default TickGroup = EHazeTickGroup::BeforeGameplay;

	ASkylineFlyingCarEnemyWithTurret CarEnemy;
	USkylineFlyingCarEnemyTurretComponent TurretComp;
	USceneComponent YawPivot;
	USceneComponent PitchPivot;

	FRotator AccRotation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		CarEnemy = Cast<ASkylineFlyingCarEnemyWithTurret>(Owner);
		TurretComp = CarEnemy.TurretComp;
		YawPivot = CarEnemy.TurretYawPivot;
		PitchPivot = CarEnemy.TurretPitchPivot;
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
		TurretComp.AccAimAheadAmount.SnapTo(FVector::ZeroVector);
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
		TurretComp.AccAimAheadAmount.AccelerateTo(SkylineFlyingCarEnemy::GetPlayerFlyingCar().ActorVelocity * TurretComp.RifleAimAheadTime, SkylineFlyingCarEnemy::Turret::AimAheadDuration, DeltaTime);
		const FVector TargetLocation = TurretComp.GetTargetLocation();
		const FVector RelativeTargetLocation = TurretComp.WorldTransform.InverseTransformPositionNoScale(TargetLocation);
		FRotator RelativeTargetRotation = FRotator::MakeFromXZ(RelativeTargetLocation, FVector::UpVector);

		RelativeTargetRotation.Roll = 0;
		AccRotation = Math::RInterpConstantTo(AccRotation, RelativeTargetRotation, DeltaTime, 100);

		ApplyRotation();
	}

	void ApplyRotation()
	{
		AccRotation.Pitch = Math::Clamp(AccRotation.Pitch, SkylineFlyingCarEnemy::Turret::MinPitch, SkylineFlyingCarEnemy::Turret::MaxPitch);
		
		YawPivot.SetRelativeRotation(FRotator(0, AccRotation.Yaw, 0));
		PitchPivot.SetRelativeRotation(FRotator(AccRotation.Pitch, 0, 0));
	}
};