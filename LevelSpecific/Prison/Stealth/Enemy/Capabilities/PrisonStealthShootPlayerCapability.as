struct FPrisonStealthShootPlayerActivatedParams
{
	AHazePlayerCharacter DetectedPlayer;
}

class UPrisonStealthShootPlayerCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(PrisonTags::Prison);
	default CapabilityTags.Add(PrisonStealthTags::StealthDetection);
	default CapabilityTags.Add(PrisonStealthTags::BlockedWhileStunned);

	APrisonStealthEnemy Enemy;
	AHazePlayerCharacter DetectedPlayer;
	UPlayerHealthComponent DetectedPlayerHealthComp;

	const float ShootFrequency = 0.05;

	float TimeOfLastShot = 0.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Enemy = Cast<APrisonStealthEnemy>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FPrisonStealthShootPlayerActivatedParams& Params) const
	{
		if(DeactiveDuration < ShootFrequency)
			return false;

		for(AHazePlayerCharacter Player : Game::Players)
		{
			if(!Enemy.HasDetectedPlayer(Player))
				continue;

			if(Player.IsPlayerDeadOrRespawning())
				continue;

			Params.DetectedPlayer = Player;
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(DetectedPlayer == nullptr)
			return true;

		if(DetectedPlayer.IsPlayerDeadOrRespawning())
			return true;

		if(!Enemy.HasDetectedPlayer(DetectedPlayer))
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FPrisonStealthShootPlayerActivatedParams Params)
	{
		DetectedPlayer = Params.DetectedPlayer;
		DetectedPlayerHealthComp = UPlayerHealthComponent::Get(DetectedPlayer);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(Time::GetGameTimeSince(TimeOfLastShot) < ShootFrequency)
			return;

		FPrisonStealthEnemyOnShootOnPlayerParams Params;
		Params.PlayerLocation = DetectedPlayer.ActorLocation;
		UPrisonStealthEnemyEventHandler::Trigger_OnShootOnPlayer(Enemy, Params);
		
		TimeOfLastShot = Time::GetGameTimeSeconds();
	}
}