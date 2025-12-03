class ACapabilitySheetVolume : APlayerTrigger
{
    default Shape::SetVolumeBrushColor(this, FLinearColor(0.8, 1.0, 0.2, 1.0));

	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent RequestComp;

	UPROPERTY(EditAnywhere, Category = "Capability Sheets")
	TArray<UHazeCapabilitySheet> PlayerSheets;

	UPROPERTY(EditAnywhere, Category = "Capability Sheets", AdvancedDisplay)
	TArray<UHazeCapabilitySheet> MioSheets;

	UPROPERTY(EditAnywhere, Category = "Capability Sheets", AdvancedDisplay)
	TArray<UHazeCapabilitySheet> ZoeSheets;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		RequestComp.InitialStoppedSheets = PlayerSheets;
		RequestComp.InitialStoppedSheets_Mio = MioSheets;
		RequestComp.InitialStoppedSheets_Zoe = ZoeSheets;
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		OnPlayerEnter.AddUFunction(this, n"OnEnter");
		OnPlayerLeave.AddUFunction(this, n"OnLeave");
	}

	UFUNCTION()
	private void OnEnter(AHazePlayerCharacter Player)
	{
		RequestComp.StartInitialSheetsAndCapabilities(Player, this);
	}

	UFUNCTION()
	private void OnLeave(AHazePlayerCharacter Player)
	{
		RequestComp.StopInitialSheetsAndCapabilities(Player, this);
	}
};