class USummitDominoCatapultFireCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Movement;

	ASummitDominoCatapult Catapult;

	UMovementGravitySettings ZoeGravitySettings;
	
	bool bHasLaunched = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Catapult = Cast<ASummitDominoCatapult>(Owner);

		ZoeGravitySettings = UMovementGravitySettings::GetSettings(Game::Zoe);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		// if(!Catapult.bAcidActivated)
		// 	return false;

		if(!Catapult.bStatueIsHoldingCatapult)
			return false;

		if(!Catapult.Statue.bIsUp)
			return false;

		if(Catapult.Statue.HandsCountAsGrabbing())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(ActiveDuration >= Catapult.ShootRotateDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Catapult.bIsFiring = true;
		Catapult.bStatueIsHoldingCatapult = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Catapult.bAcidActivated = false;
		Catapult.TimeLastFired = Time::GameTimeSeconds;
		Catapult.bIsPrimed = false;
		Catapult.bIsFiring = false;
		Catapult.TimeLastHitByWindUpRoll = -MAX_flt;
		Catapult.TimeLastStoppedWindingUp = -MAX_flt;

		Catapult.CatapultRotatePivot.RelativeRotation = Catapult.FireTargetQuat.Rotator();

		Catapult.CurrentWindUpDegrees = 0;
		Catapult.WindUpRotateRoot.RelativeRotation = FRotator(0.0, 0.0, -Catapult.CurrentWindUpDegrees);

		if(!bHasLaunched)
			LaunchPlayerInVolume();

		bHasLaunched = false; // DB change: catapult wasn't able to launch zoe multiple times
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float ShootAlpha = ActiveDuration / Catapult.ShootRotateDuration;
		float ShootRotateAlpha = Catapult.ShootRotationCurve.GetFloatValue(ShootAlpha);

		if(ShootAlpha > 0.9
		&& !bHasLaunched)
			LaunchPlayerInVolume();

		Catapult.CatapultRotatePivot.RelativeRotation = FQuat::Slerp(FQuat::Identity, Catapult.FireTargetQuat, ShootRotateAlpha).Rotator();	

		Catapult.CurrentWindUpDegrees = Math::Lerp(Catapult.MaxWindUpDegrees, 0.0, ShootRotateAlpha);
		Catapult.WindUpRotateRoot.RelativeRotation = FRotator(0.0, 0.0, -Catapult.CurrentWindUpDegrees);
		Catapult.TargetWindUpDegrees = 0.0;
	}

	void LaunchPlayerInVolume()
	{
		if(!Catapult.ZoeInVolume.IsSet())
			return;

		auto Player = Catapult.ZoeInVolume.Value;
		
		// FVector EstimatedLaunchVelocity = Trajectory::CalculateVelocityForPathWithHorizontalSpeed(
		// 	Catapult.EstimatedLaunchLocation, Catapult.TargetLocation, Catapult.LaunchGravityAmount, Catapult.LaunchHorizontalSpeed);
		// float UpSpeed = EstimatedLaunchVelocity.DotProduct(FVector::UpVector);
		// FVector NotUpVelocity = EstimatedLaunchVelocity - (FVector::UpVector * UpSpeed);
		// float HorizontalSpeed = NotUpVelocity.Size();
		
		// FVector Impulse = FVector::UpVector * UpSpeed
		// 	+ Catapult.YawRotationPivot.RightVector * HorizontalSpeed;

		FVector Impulse = Trajectory::CalculateVelocityForPathWithHorizontalSpeed(
				Player.ActorLocation, Catapult.TargetLocation + FVector::DownVector * Player.CapsuleComponent.CapsuleRadius, Catapult.LaunchGravityAmount, Catapult.LaunchHorizontalSpeed);

		auto CatapultComp = UTeenDragonDominoCatapultComponent::GetOrCreate(Player);
		CatapultComp.LaunchImpulse.Set(Impulse);
		CatapultComp.LaunchingCatapult = Catapult;

		TEMPORAL_LOG(Catapult)
			.DirectionalArrow("Launch Impulse", Player.ActorLocation, Impulse, 10, 40, FLinearColor::Purple)
		;

		bHasLaunched = true;
	}
};