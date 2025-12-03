class APlayerActionModeVolume : APlayerTrigger
{
	default BrushColor = FLinearColor::MakeFromHex(0xfffa5f05);

	UPROPERTY(EditAnywhere)
	EPlayerActionMode Mode = EPlayerActionMode::ForceActionMode;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		
		OnPlayerEnter.AddUFunction(this, n"PlayerEnter");
		OnPlayerLeave.AddUFunction(this, n"PlayerLeave");
	}

	UFUNCTION()
	private void PlayerEnter(AHazePlayerCharacter Player)
	{
		Player.ApplyActionMode(EPlayerActionMode::ForceActionMode, EInstigatePriority::Normal, this);
	}

	UFUNCTION()
	private void PlayerLeave(AHazePlayerCharacter Player)
	{
		Player.ClearActionMode(this);
	}
}