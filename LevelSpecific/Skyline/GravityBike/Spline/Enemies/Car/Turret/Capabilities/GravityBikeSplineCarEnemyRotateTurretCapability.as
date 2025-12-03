class UGravityBikeSplineCarEnemyRotateTurretCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Local;

	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(GravityBikeSpline::CarEnemy::Turret::CarEnemyTurretTag);

	default TickGroup = EHazeTickGroup::BeforeGameplay;

	AGravityBikeSplineCarEnemy CarEnemy;
	UGravityBikeSplineCarEnemyTurretComponent TurretComp;
	USceneComponent YawPivot;
	USceneComponent PitchPivot;

	FRotator AccRotation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		CarEnemy = Cast<AGravityBikeSplineCarEnemy>(Owner);
		TurretComp = CarEnemy.TurretComp;
		YawPivot = CarEnemy.TurretYawPivot;
		PitchPivot = CarEnemy.TurretPitchPivot;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(CarEnemy.HealthComp.IsDead() || CarEnemy.HealthComp.IsRespawning())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(CarEnemy.HealthComp.IsDead() || CarEnemy.HealthComp.IsRespawning())
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
		TurretComp.AccAimAheadAmount.AccelerateTo(GravityBikeSpline::GetGravityBike().ActorVelocity * TurretComp.RifleAimAheadTime, GravityBikeSpline::CarEnemy::Turret::AimAheadDuration, DeltaTime);
		const FVector TargetLocation = TurretComp.GetTargetLocation();
		const FVector RelativeTargetLocation = TurretComp.WorldTransform.InverseTransformPositionNoScale(TargetLocation);
		FRotator RelativeTargetRotation = FRotator::MakeFromXZ(RelativeTargetLocation, FVector::UpVector);

		RelativeTargetRotation.Roll = 0;
		AccRotation = Math::RInterpConstantTo(AccRotation, RelativeTargetRotation, DeltaTime, 100);

		ApplyRotation();
	}

	void ApplyRotation()
	{
		AccRotation.Pitch = Math::Clamp(AccRotation.Pitch, GravityBikeSpline::CarEnemy::Turret::MinPitch, GravityBikeSpline::CarEnemy::Turret::MaxPitch);
		
		YawPivot.SetRelativeRotation(FRotator(0, AccRotation.Yaw, 0));
		PitchPivot.SetRelativeRotation(FRotator(AccRotation.Pitch, 0, 0));
	}
};