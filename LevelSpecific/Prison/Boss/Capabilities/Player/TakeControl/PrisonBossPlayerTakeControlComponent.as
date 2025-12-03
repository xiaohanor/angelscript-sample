class UPrisonBossPlayerTakeControlComponent : UActorComponent
{
	AHazePlayerCharacter Player;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UPrisonBossFirstPersonWidget> FirstPersonWidgetClass;
	UPrisonBossFirstPersonWidget Widget;

	bool bDebrisLaunchActive = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Game::Mio;
	}

	void CreateWidget()
	{
		Widget = Player.AddWidget(FirstPersonWidgetClass);
	}

	void RemoveWidget()
	{
		if (Widget != nullptr)
		{
			Player.RemoveWidget(Widget);
			Widget = nullptr;
		}
	}
}