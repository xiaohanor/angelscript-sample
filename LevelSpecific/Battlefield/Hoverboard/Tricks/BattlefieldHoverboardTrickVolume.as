class ABattlefieldHoverboardTrickVolume : APlayerTrigger
{
	UPROPERTY(EditAnywhere)
	bool bAutoTrick = false;

	UPROPERTY(EditAnywhere)
	bool bCanTrick = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		OnPlayerEnter.AddUFunction(this, n"OnPlayerEnter");
		OnPlayerLeave.AddUFunction(this, n"OnPlayerLeave");
	}

	UFUNCTION()
	private void OnPlayerEnter(AHazePlayerCharacter Player)
	{
		if (bCanTrick)
			UBattlefieldHoverboardTrickComponent::Get(Player).IsInVolume.Add(this);
	}

	UFUNCTION()
	private void OnPlayerLeave(AHazePlayerCharacter Player)
	{
		if (bCanTrick)
			UBattlefieldHoverboardTrickComponent::Get(Player).IsInVolume.RemoveSingleSwap(this);
	}
};