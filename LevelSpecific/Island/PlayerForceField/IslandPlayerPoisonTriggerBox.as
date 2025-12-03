class AIslandPlayerPoisonTriggerBox : APlayerTrigger
{
	/* 1 means force field will be destroyed in 1 seond, 0.5 means 2 seconds etc. */
	UPROPERTY(EditAnywhere)
	float ForceFieldDamagePerSecond = 0.2;

	/* 1 means player will die in 1 second, 0.5 means 2 seconds etc. */
	UPROPERTY(EditAnywhere)
	float PlayerDamagePerSecond = 1.0;

	TArray<AHazePlayerCharacter> PlayersInTrigger;

	void TriggerOnPlayerEnter(AHazePlayerCharacter Player) override
	{
		Super::TriggerOnPlayerEnter(Player);
		
		PlayersInTrigger.Add(Player);
	}

	void TriggerOnPlayerLeave(AHazePlayerCharacter Player) override
	{
		Super::TriggerOnPlayerLeave(Player);
		
		PlayersInTrigger.Remove(Player);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		for(auto Player : PlayersInTrigger)
		{
			auto UserComp = UIslandPlayerForceFieldUserComponent::Get(Player);
			if(UserComp == nullptr)
				continue;

			UserComp.TakeDamagePoison(DeltaSeconds, ForceFieldDamagePerSecond, PlayerDamagePerSecond);
		}
	}
}