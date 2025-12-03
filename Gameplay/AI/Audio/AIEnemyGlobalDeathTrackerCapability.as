class UAIEnemyGlobalDeathTrackerCapability : UHazeCapability
{
	ABasicAICharacter AICharacter;
	private bool bHasDied = false;

	UPROPERTY(EditDefaultsOnly)
	FName Tag = n"Default";

	UPROPERTY(EditDefaultsOnly, Meta = (ForceUnits = "seconds"))
	float DeathDecrementTime = 4.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		AICharacter = Cast<ABasicAICharacter>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(bHasDied)
			return false;

		return AICharacter != nullptr;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return bHasDied;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		AICharacter.HealthComp.OnStartDying.AddUFunction(this, n"OnAIDied");
	}

	UFUNCTION()
	void OnAIDied(AHazeActor ActorBeingKilled)
	{
		auto Manager = GlobalAIEnemy::GetDeathTrackerManager();
		Manager.RegisterDeath(Tag, DeathDecrementTime);
		bHasDied = true;
	}
}