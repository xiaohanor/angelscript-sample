class ACentipedeMovementSettingsVolume : AHazeActor
{
	UPROPERTY(DefaultComponent, ShowOnActor)
	UHazeMovablePlayerTriggerComponent PlayerTriggerComponent;
	default PlayerTriggerComponent.ShapeColor = FLinearColor::LucBlue;
	default PlayerTriggerComponent.EditorLineThickness = 10;

	UPROPERTY(EditAnywhere)
	const bool bCanLeaveEdges = false;

	UPROPERTY(EditAnywhere)
	const float StepUpOverride = 100.0;

	UPROPERTY(EditAnywhere)
	const float StepDownOverride = 100.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PlayerTriggerComponent.OnPlayerEnter.AddUFunction(this, n"OnPlayerEnter");
		PlayerTriggerComponent.OnPlayerLeave.AddUFunction(this, n"OnPlayerLeave");
	}

	UFUNCTION(NotBlueprintCallable)
	void OnPlayerEnter(AHazePlayerCharacter Player)
	{
		UCentipedeMovementSettings::SetCanLeaveEdges(Player, bCanLeaveEdges, this);

		UCentipedeMovementSettings::SetStepUpSize(Player, StepUpOverride, this);
		UCentipedeMovementSettings::SetStepDownSize(Player, StepDownOverride, this);
	}

	UFUNCTION(NotBlueprintCallable)
	void OnPlayerLeave(AHazePlayerCharacter Player)
	{
		UCentipedeMovementSettings::ClearCanLeaveEdges(Player, this);

		UCentipedeMovementSettings::ClearStepUpSize(Player, this);
		UCentipedeMovementSettings::ClearStepDownSize(Player, this);
	}
}