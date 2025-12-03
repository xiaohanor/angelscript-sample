class ASummitMountainBirdLandingSpot : AScenepointActorBase
{
	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedActorComp;

	bool bIsNest = false;

	UPROPERTY()
	const float Cooldown = 1.0;

	private AHazeActor CurrentUser;
	private float CooldownEndTime = 0.0;

	void Claim(AHazeActor User)
	{
		CurrentUser = User;
	}

	void Release()
	{
		if (bIsNest) // Always kept.
			return;
		CurrentUser = nullptr;
		CooldownEndTime = Time::GameTimeSeconds + Cooldown;
	}
	
	bool IsAvailable(AHazeActor User)
	{
		if (CurrentUser == User)
			return true;

		if (bIsNest)
			return false;

		if (CurrentUser != nullptr)
			return false;
		
		if (CooldownEndTime > Time::GameTimeSeconds)
			return false;

		return true;
	}

}