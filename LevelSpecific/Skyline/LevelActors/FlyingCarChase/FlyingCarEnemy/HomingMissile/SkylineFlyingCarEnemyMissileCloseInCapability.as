class USkylineFlyingCarEnemyMissileCloseInCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;


	ASkylineFlyingCarEnemyMissile Missile;

	float DelayCloseInTime = 2;
	FVector InitialVelocity;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Missile = Cast<ASkylineFlyingCarEnemyMissile>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(Missile.bIsClosingIn)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Missile.bIsClosingIn)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		InitialVelocity = Missile.Velocity;
		USkylineFlyingCarEnemyMissileEventHandler::Trigger_ClosingIn(Game::Zoe, FSkylineEnemyMissileEventData(Missile));
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{

		float Speed = Missile.MinVelocity;

		if(ActiveDuration > DelayCloseInTime)
		{
			float VelocityAlpha = Math::GetMappedRangeValueClamped(FVector2D(DelayCloseInTime, DelayCloseInTime + 1), FVector2D(0, 1), ActiveDuration);
			Speed = Math::Lerp(Missile.MinVelocity, Missile.MaxVelocity, VelocityAlpha);
		}

		Missile.Velocity = Missile.ToTarget.SafeNormal * Speed;

	}
};