class ASummitPlayerKnockBackVolume : APlayerTrigger
{
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		OnPlayerEnter.AddUFunction(this, n"PlayerEntered");
	}

	UFUNCTION()
	private void PlayerEntered(AHazePlayerCharacter Player)
	{
		FKnockdown KnockDown;
		FVector MoveBar = ActorForwardVector * 2000.0; 
		MoveBar += FVector::UpVector * 1500.0;
		KnockDown.Move = MoveBar;
		Player.ApplyKnockdown(KnockDown);
	}
};