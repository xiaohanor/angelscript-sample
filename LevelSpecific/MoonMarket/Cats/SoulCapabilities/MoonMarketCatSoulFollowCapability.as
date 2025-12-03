class UMoonMarketCatSoulFollowCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default TickGroup = EHazeTickGroup::Gameplay;

	AMoonMarketCat Cat;

	FVector RandomTargetPosition;

	float MinDuration = 1.5;
	float MaxDuration = 2.5;
	float ChangeTime;

	FHazeAcceleratedVector AccelVector;
	FHazeAcceleratedRotator AccelRot;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Cat = Cast<AMoonMarketCat>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Cat.bHasbeenCompleted)
			return false;

		if (Cat.SoulTargetPlayer == nullptr)
			return false;

		if (Cat.bFlyToCatHead)
			return false;

		if (Cat.bCutsceneCat)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Cat.bFlyToCatHead)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		AccelVector.SnapTo(Cat.ActorLocation);
		AccelRot.SnapTo(Cat.ActorRotation);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (Time::GameTimeSeconds > ChangeTime)
		{
			SetNewRelativeLocation();
			ChangeTime = Time::GameTimeSeconds + Math::RandRange(MinDuration, MaxDuration);
		}

		AccelVector.AccelerateTo(GetTargetLocation(), 5.0, DeltaTime);
		AccelRot.AccelerateTo(Cat.SoulTargetPlayer.ActorRotation, 5.0, DeltaTime);
		Cat.ActorLocation = AccelVector.Value;
		Cat.ActorRotation = AccelRot.Value;
	}

	FVector GetTargetLocation()
	{
		FVector TargetLoc = Cat.SoulTargetPlayer.ActorTransform.TransformPosition(RandomTargetPosition);
		TargetLoc += -Cat.SoulTargetPlayer.ActorForwardVector * 70.0;
		return TargetLoc;
	}

	void SetNewRelativeLocation()
	{
		float RX = Math::RandRange(-25, -25);
		float RY = Math::RandRange(-15, 15);
		float RZ = Math::RandRange(40, 60);
		RandomTargetPosition = FVector(RX, RY, RZ) + Cat.CatSoulFollowOffset;
	}
};