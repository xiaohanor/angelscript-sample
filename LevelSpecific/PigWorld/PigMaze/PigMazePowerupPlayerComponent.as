class UPigMazePowerupPlayerComponent : UActorComponent
{
	UPROPERTY()
	UNiagaraSystem PoweredUpSystem;

	AHazePlayerCharacter Player;

	bool bPowerupActive = false;

	float PowerupDuration = 8.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
	}

	void ActivatePowerup()
	{
		bPowerupActive = true;
		Timer::SetTimer(this, n"DeactivatePowerup", PowerupDuration);
	}

	UFUNCTION()
	private void DeactivatePowerup()
	{
		bPowerupActive = false;

		UPlayerPigComponent PigComp = UPlayerPigComponent::Get(Player);
	}
}