class UMoonMarketBouncyBallBlasterShootCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default TickGroup = EHazeTickGroup::Gameplay;

	UMoonMarketBouncyBallBlasterPotionComponent BallBlasterComp;
	UHazeMovementComponent MoveComp;

	float TimeScaledActiveDuration = 0;

	bool bHasShot = false;

	int BallId = 0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		BallBlasterComp = UMoonMarketBouncyBallBlasterPotionComponent::Get(Owner);
		MoveComp = UHazeMovementComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(BallBlasterComp.BallBlaster == nullptr)
			return false;

		if(!IsActioning(ActionNames::PrimaryLevelAbility))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(TimeScaledActiveDuration < BallBlasterComp.ShootCooldown)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		float Yaw = Player.GetCameraDesiredRotation().Yaw;
		BallBlasterComp.TargetRotation = FRotator(0, Yaw, 0.0);
 		bHasShot = false;
		TimeScaledActiveDuration = 0;
		BallBlasterComp.bIsShooting = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		BallBlasterComp.bIsShooting = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!bHasShot && HasControl())
		{
			if(Math::Abs(BallBlasterComp.TargetRotation.Yaw - BallBlasterComp.BallBlaster.ActorRotation.Yaw) < 1)
			{
				bHasShot = true;
				CrumbShoot();
			}
		}
		else
		{
			TimeScaledActiveDuration += DeltaTime;

			if(MoveComp.HorizontalVelocity.Size() < 100)
			{
				const float Alpha = Math::Saturate(TimeScaledActiveDuration / (BallBlasterComp.ShootCooldown));
				float ZScale = 1 + ((BallBlasterComp.ZScaleCurve.GetFloatValue(Alpha) - 1));

				const float HorizontalSquashMultiplier = 0.5;
				float XYScale = 1 - ((BallBlasterComp.ZScaleCurve.GetFloatValue(Alpha) - 1) * HorizontalSquashMultiplier);

				BallBlasterComp.BallBlaster.MeshScaler.SetWorldScale3D(FVector(XYScale, XYScale, ZScale));
			}
		}
	}

	UFUNCTION(CrumbFunction)
	void CrumbShoot()
	{
		UMoonMarketBouncyBallBlasterEventHandler::Trigger_OnShoot(BallBlasterComp.BallBlaster);
		FTransform SpawnPoint = BallBlasterComp.BallBlaster.BallSpawnPoint.WorldTransform;
		FRotator SpawnRotation = Player.GetCameraDesiredRotation();
		SpawnRotation += FRotator(20, 0, 0);
		SpawnRotation.Pitch = Math::Clamp(SpawnRotation.Pitch, 0, 50);
		SpawnPoint.SetRotation(SpawnRotation);
		AMoonMarketBouncyBall Ball = SpawnActor(BallBlasterComp.BallClass, SpawnPoint.Location, SpawnPoint.Rotation.Rotator(), bDeferredSpawn = true);
		Ball.MakeNetworked(this, BallId);
		Ball.SetActorControlSide(Owner);
		Ball.OwningPlayer = Player;

		Player.PlayForceFeedback(BallBlasterComp.ShootFeedback, false, false, this);
		
		Ball.AddMovementImpulse(Ball.ActorForwardVector * BallBlasterComp.LaunchVelocity);
		FinishSpawningActor(Ball);
		BallId++;
	}
};