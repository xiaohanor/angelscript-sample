class UPrisonBossPlayerTakeControlFollowCameraCapability : UHazeCapability
{
	default CapabilityTags.Add(n"TakeControl");

	default TickGroup = EHazeTickGroup::PostWork;

	APrisonBoss BossActor;
	AHazePlayerCharacter Player;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		BossActor = Cast<APrisonBoss>(Owner);
		Player = Game::Mio;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!BossActor.bControlled)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!BossActor.bControlled)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Boss rotation is updated in a separate capability that happens at the end of the frame (PostWork)
		// Otherwise, the boss will use the previous frame's view rotation which means it will jitter
		if (BossActor.bHackedRotationFollowsCamera)
			BossActor.SetActorRotation(Player.ViewRotation);
	}
};