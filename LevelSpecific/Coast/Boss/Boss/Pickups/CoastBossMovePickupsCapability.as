class UCoastBossMovePickupsCapability : UHazeCapability
{
	default CapabilityTags.Add(CoastBossTags::CoastBossTag);
	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 91;

	ACoastBossActorReferences Refs;
	ACoastBoss2DPlane ConstrainPlane;
	TArray<ACoastBossPlayerNormalPowerUp> Disablings;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (ConstrainPlane == nullptr)
		{
			TListedActors<ACoastBossActorReferences> AllRefs;
			if (AllRefs.Num() > 0)
			{
				Refs = AllRefs.Single;
				ConstrainPlane = AllRefs.Single.CoastBossPlane2D;
			}
		}

		if (ConstrainPlane == nullptr)
			return;

		for (auto PowerUp : Refs.PowerUps)
		{
			if (PowerUp.bActive)
				UpdatePowerUp(PowerUp, DeltaTime);
		}
	}

	void UpdatePowerUp(ACoastBossPlayerNormalPowerUp PowerUp, float DeltaSeconds)
	{
		PowerUp.AliveDuration += DeltaSeconds;

		{
			float MoveAlpha = Math::Saturate(PowerUp.AliveDuration / CoastBossConstants::PowerUp::AliveDuration);
			float Angle = Math::Wrap((PowerUp.AliveDuration / CoastBossConstants::PowerUp::SinusLoopTime) + PowerUp.RandomSinusOffset, 0.0, 1.0) * PI * 2.0;
			float Multiplier = 1.3;
			float Y = Math::Lerp(ConstrainPlane.PlaneExtents.Y * Multiplier, -ConstrainPlane.PlaneExtents.Y * Multiplier, MoveAlpha);
			float X = Math::Sin(Angle) * CoastBossConstants::PowerUp::SinusWidthOffset;
			PowerUp.ManualRelativeLocation.X = X + PowerUp.RandomXOffset;
			PowerUp.ManualRelativeLocation.Y = Y;
		}
		// if (PowerUp.bPlayerPicked)
		// {
		// 	float TimeSincePickedUp = PowerUp.PickedUpTimestamp - Time::GameTimeSeconds;
		// 	float MoveAlpha = Math::Saturate(TimeSincePickedUp / CoastBossConstants::PowerUp::PowerUpDuration);
		// 	FVector Scale = Math::Lerp(PowerUp.OGScale, PowerUp.OGScale * 0.01, MoveAlpha);
		// 	PowerUp.SetActorScale3D(Scale);
		// }

		FVector WorldLocation = ConstrainPlane.GetLocationInWorld(PowerUp.ManualRelativeLocation);
		FRotator PowerUpRotation = FRotator::MakeFromXZ(-ConstrainPlane.ActorForwardVector, ConstrainPlane.ActorUpVector);

		PowerUp.SetActorLocationAndRotation(WorldLocation, PowerUpRotation);
		//Debug::DrawDebugLine(PowerUp.ActorLocation, ConstrainPlane.ActorLocation, ColorDebug::Magenta, 10.0, 0.0, true);

		if (PowerUp.AliveDuration > CoastBossConstants::PowerUp::AliveDuration)
			PowerUp.Unspawn();
	}
};