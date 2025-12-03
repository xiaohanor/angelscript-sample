class USanctuaryBossHydraFireBallAttackCapability : USanctuaryBossHydraChildCapability
{
	FTransform StartTransform;
	FTransform TargetTransform;
	bool bTriggeredAnimation;

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ActiveDuration > Settings.FireBallAttackDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		bTriggeredAnimation = false;
		StartTransform = Head.HeadPivot.WorldTransform;
		TargetTransform = StartTransform;

		FQuat RotationOffset = FRotator(Settings.MouthPitch, 0.0, 0.0).Quaternion();
		TargetTransform.SetRotation(TargetTransform.Rotation * RotationOffset.Inverse());

		auto PointAttack = Cast<USanctuaryBossHydraPointAttackData>(GetAttackData());

		auto Projectile = Cast<ASanctuaryBossHydraProjectile>(
			SpawnActor(Settings.FireBallProjectileClass,
				Head.HeadPivot.WorldLocation,
				Head.HeadPivot.WorldRotation,
				bDeferredSpawn = true)
		);
		Projectile.OwningHead = Head;
		Projectile.TargetComponent = PointAttack.TargetComponent;
		FinishSpawningActor(Projectile);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if (Settings.IdleAnimation != nullptr && Settings.bUseAnimSequences)
		{
			FHazePlayFaceAnimationParams FaceParams;
			FaceParams.Animation = Settings.IdleAnimation;
			FaceParams.bLoop = true;
			Head.PlayFaceAnimation(FHazeAnimationDelegate(), FaceParams);
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float TimeRemaining = Math::Max(0.0, Settings.FireBallAttackDuration - ActiveDuration);
		FVector TargetDirection = (AttackData.WorldLocation - StartTransform.Location).GetSafeNormal();
		FVector TargetLocation = StartTransform.Location - TargetDirection * 500.0;

		Head.HeadPivot.SetWorldLocationAndRotation(
			Head.AcceleratedLocation.AccelerateTo(TargetLocation, TimeRemaining, DeltaTime),
			Head.AcceleratedQuat.AccelerateTo(TargetTransform.Rotation, TimeRemaining, DeltaTime)
		);

		if (Settings.OpenJawAnimation != nullptr && Settings.bUseAnimSequences)
		{
			if (!bTriggeredAnimation && ActiveDuration > Settings.FireBallAttackDuration - Settings.OpenJawAnimation.PlayLength)
			{
				FHazePlayFaceAnimationParams FaceParams;
				FaceParams.Animation = Settings.OpenJawAnimation;
				Head.PlayFaceAnimation(FHazeAnimationDelegate(), FaceParams);

				bTriggeredAnimation = true;
			}
		}
	}
}