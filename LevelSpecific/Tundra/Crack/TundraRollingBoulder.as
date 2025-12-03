UCLASS(Abstract)
class ATundraRollingBoulder : AHazeActor
{
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorControlSide(Game::Zoe);
	}

	UFUNCTION()
	void StartRolling()
	{
		if(!HasControl())
			return;

		CrumbStartRolling();
	}

	UFUNCTION(CrumbFunction)
	private void CrumbStartRolling()
	{
		OnStartRolling();
	}

	UFUNCTION(BlueprintEvent)
	void OnStartRolling() {}

	UFUNCTION()
	void TriggerBoulderCrash()
	{
		if(!HasControl())
			return;

		CrumbBoulderCrash();
	}

	UFUNCTION(CrumbFunction)
	private void CrumbBoulderCrash()
	{
		OnBoulderCrash();
	}

	UFUNCTION(NetFunction)
	void NetKillPlayer(AHazePlayerCharacter Player, TSubclassOf<UDeathEffect> DeathEffect)
	{
		Player.KillPlayer(DeathEffect = DeathEffect);
	}

	UFUNCTION(BlueprintEvent)
	void OnBoulderCrash() {}
}