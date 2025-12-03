class AIslandOverseerLaserBomb : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY()
	TSubclassOf<UDamageEffect> DamageEffect;

	UPROPERTY()
	TSubclassOf<UDeathEffect> DeathEffect;

	float ActiveDuration;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		ActiveDuration += DeltaSeconds;

		if(ActiveDuration < 1)
			return;

		UIslandOverseerLaserBombEventHandler::Trigger_OnExplode(this);
		for(AHazePlayerCharacter Player : Game::Players)
		{
			if(Player.GetDistanceTo(this) < 90)
				Player.DamagePlayerHealth(0.5, FPlayerDeathDamageParams(), DamageEffect, DeathEffect);
		}

		AddActorDisable(this);
	}
}