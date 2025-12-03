class UCoastBossDeathCapability : UHazeCapability
{
	default CapabilityTags.Add(CoastBossTags::CoastBossTag);
	default TickGroup = EHazeTickGroup::Movement;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	ACoastBoss Boss;
	bool bMoveDone = false;
	FVector2D OGRelativeLocation;
	ACoastBoss2DPlane ConstrainPlane;

	const float DelayBeforeLerpingDown = 1.0;
	const float LerpDownDuration = 3.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Boss = Cast<ACoastBoss>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Boss.bDead)
			return false;
		if(Boss.bFullyDead)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(bMoveDone)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Boss.DeathVFX.Activate();
		Boss.AttackActionQueue.Empty();
		Boss.PowerUpActionQueue.Empty();
		OGRelativeLocation = Boss.ManualRelativeLocation;
		for(AHazePlayerCharacter Player : Game::Players)
		{
			Player.PlayCameraShake(Boss.BossDiedCamShake, this);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Boss.bFullyDead = true;
		for(AHazePlayerCharacter Player : Game::Players)
		{
			Player.StopCameraShakeByInstigator(this);
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!TryCacheThings())
			return;

		float Alpha = (ActiveDuration - DelayBeforeLerpingDown) / LerpDownDuration;
		Alpha = Math::Saturate(Alpha);
		if(Math::IsNearlyEqual(Alpha, 1.0))
		{
			bMoveDone = true;
		}

		Alpha = Math::EaseInOut(0.0, 1.0, Alpha, 2.0);

		Boss.ManualRelativeLocation.Y = Math::Lerp(OGRelativeLocation.Y, -2000.0, Alpha) + Math::Sin(Time::GetGameTimeSeconds() * 30.0) * 25.0;
		Boss.ManualRelativeLocation.X = OGRelativeLocation.X + Math::Sin(Time::GetGameTimeSeconds() * 35.0 + 100.0) * 25.0;

		FVector2D ActualRelativeLocation = Boss.ManualRelativeLocation;
		FVector WorldLocation = ConstrainPlane.GetLocationInWorld(ActualRelativeLocation);
		Boss.SetActorLocationAndRotation(WorldLocation, ConstrainPlane.ActorRotation);

		for(AHazePlayerCharacter Player : Game::Players)
		{
			FHazeFrameForceFeedback FF;
			FF.LeftMotor = 0.5;
			FF.RightMotor = 0.5;
			Player.SetFrameForceFeedback(FF);
		}
	}

	bool TryCacheThings()
	{
		if (ConstrainPlane == nullptr)
		{
			TListedActors<ACoastBossActorReferences> Refs;
			if (Refs.Num() > 0)
				ConstrainPlane = Refs.Single.CoastBossPlane2D;
		}
		return ConstrainPlane != nullptr;
	}
}