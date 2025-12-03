class USummitFruitPressDragonStatueWingsCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	ASummitFruitPressDragonStatue Statue;
	
	FRotator StartRightRotation;
	FRotator StartLeftRotation;

	float AlphaRight;
	float AlphaLeft;

	float WingRotateDuration = 6.0;

	bool bFinished = false;

	bool bLeftWingReachedMax;
	bool bRightWingReachedMax;
	bool bWingsReachedMax;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Statue = Cast<ASummitFruitPressDragonStatue>(Owner);
		StartRightRotation = Statue.RightWingRoot.RelativeRotation; 
		StartLeftRotation = Statue.LeftWingRoot.RelativeRotation; 
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Statue.bCompletedRotation)
			return false;

		if (bWingsReachedMax)
			return false;

		if (Statue.WeightCounter < 2)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (bWingsReachedMax)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		USummitFruitPressDragonStatueEffectHandler::Trigger_OnWingsStartMoving(Statue, FSummitFruitPressDragonStatueParams(Statue.ActorLocation));
		
		for (AHazePlayerCharacter Player : Game::Players)
		{
			Player.PlayWorldCameraShake(Statue.WingsCameraShake, this, Statue.ActorLocation, 7000.0, 35000.0);
			Player.PlayForceFeedback(Statue.WingRumble, true, true, this, 0.5);
		}
		Statue.StartLoopingCameraShake(0.4);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		for (AHazePlayerCharacter Player : Game::Players)
		{
			Player.PlayWorldCameraShake(Statue.WingsCameraShake, this, Statue.ActorLocation, 7000.0, 30000.0, Scale = 0.6);
			Player.StopForceFeedback(this);
			Player.PlayForceFeedback(Statue.WingRumbleOneShot, false, true, this);
		}				
		Statue.AlterWheels(ESummitFruitPressStatueWheelType::Left, false);
		Statue.AlterWheels(ESummitFruitPressStatueWheelType::Right, false);
		Statue.StopLoopingCameraShake();
		Statue.CompetedPuzzle();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		AlphaRight = Math::Saturate(AlphaRight + (DeltaTime / WingRotateDuration));
		float TrueAlpha = 1.0 - Statue.RotateWingCurve.GetFloatValue(AlphaRight);
		Statue.RightWingRoot.RelativeRotation = FRotator(StartRightRotation.Pitch, StartRightRotation.Yaw, StartRightRotation.Roll * TrueAlpha);
		Statue.LeftWingRoot.RelativeRotation = FRotator(StartLeftRotation.Pitch, StartLeftRotation.Yaw, StartLeftRotation.Roll * TrueAlpha);

		if (TrueAlpha < 0.0 && !bWingsReachedMax)
		{
			bWingsReachedMax = true;
			Statue.bCompletedWings = true;
			USummitFruitPressDragonStatueEffectHandler::Trigger_OnWingsStoppedMoving(Statue, FSummitFruitPressDragonStatueParams(Statue.ActorLocation));
		}
	}
};