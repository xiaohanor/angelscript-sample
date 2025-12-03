class USummitFruitPressDragonStatueRotateCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	ASummitFruitPressDragonStatue Statue;

	FRotator StartBaseRotation;
	FHazeAcceleratedRotator AccelRot;

	float TargetYawRotation = -90.0;
	float StartingYawRotation;

	float Duration = 6.0;
	float Alpha;

	bool bReachedMaxAlpha;
	bool bPlayedFirstStop;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Statue = Cast<ASummitFruitPressDragonStatue>(Owner);
		StartingYawRotation = Statue.BaseRotationRoot.RelativeRotation.Yaw;
		StartBaseRotation = Statue.BaseRotationRoot.RelativeRotation;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Statue.bCompletedRotation)
			return false;

		if (Statue.WeightCounter < 1)
			return false;
		
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Statue.bCompletedRotation)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		USummitFruitPressDragonStatueEffectHandler::Trigger_OnStatueStartRotating(Statue);
		Statue.StartLoopingCameraShake();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Statue.StopLoopingCameraShake();
		Statue.AlterWheels(ESummitFruitPressStatueWheelType::Left, false);
		Statue.AlterWheels(ESummitFruitPressStatueWheelType::Right, false);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (Statue.WeightCounter == 0)
			return;

		Alpha = Math::Clamp(Alpha + (DeltaTime / Duration), 0.0, 1.0);
		float TrueAlpha = Statue.RotateBaseCurve.GetFloatValue(Alpha);
		FRotator TargetRotation = FRotator(0,TargetYawRotation * TrueAlpha,0);
		AccelRot.AccelerateTo(TargetRotation, 0.75, DeltaTime);
		FRotator LastRotation = Statue.BaseRotationRoot.RelativeRotation;
		Statue.BaseRotationRoot.RelativeRotation = AccelRot.Value;
		float RotationDiff = Math::Abs(Statue.BaseRotationRoot.RelativeRotation.Yaw - LastRotation.Yaw);
		float Force = Math::Saturate(RotationDiff);

		for (AHazePlayerCharacter Player : Game::Players)
		{
			FHazeFrameForceFeedback ForceFeedback;
			ForceFeedback.LeftMotor = Force;
			ForceFeedback.RightMotor = Force;
			Player.SetFrameForceFeedback(ForceFeedback);
		}

		if (TrueAlpha >= 1.0)
		{
			bReachedMaxAlpha = true;
			Statue.bCompletedRotation = true;
			USummitFruitPressDragonStatueEffectHandler::Trigger_OnStatueStopRotating(Statue);

			for (AHazePlayerCharacter Player : Game::Players)
			{
				Player.PlayWorldCameraShake(Statue.StatueCameraShakeFinish, this, Statue.ActorLocation, 8000.0, 35000.0);
				Player.PlayForceFeedback(Statue.StatueRumbleOneShot, false, true, this);
				Player.StopCameraShakeByInstigator(Player);
				Player.StopForceFeedback(Player);
			}
		}
	}
};