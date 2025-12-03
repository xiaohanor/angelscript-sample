class UEnforcerRocketLauncherProjectileIndicatorComponent : UActorComponent
{
	TArray<FEnforcerRocketLauncherProjectileIndicatorWidgetData> Widgets;

	void ShowIndicator(AHazePlayerCharacter TargetPlayer)
	{
		HideIndicator();

		FEnforcerRocketLauncherProjectileIndicatorWidgetData Data;
		Data.Player = TargetPlayer;
		Data.Widget = TargetPlayer.AddWidget(WidgetClass);
		Widgets.Add(Data);

		FEnforcerRocketLauncherProjectileIndicatorWidgetData SecondaryData;
		SecondaryData.Player = TargetPlayer.OtherPlayer;
		SecondaryData.Widget = TargetPlayer.OtherPlayer.AddWidget(SecondaryWidgetClass);
		Widgets.Add(SecondaryData);
	}

	void HideIndicator()
	{
		TArray<FEnforcerRocketLauncherProjectileIndicatorWidgetData> RemoveWidgets = Widgets;
		for(FEnforcerRocketLauncherProjectileIndicatorWidgetData Widget : RemoveWidgets)
		{
			Widget.Player.RemoveWidget(Widget.Widget);
			Widgets.Remove(Widget);
		}
	}

	UPROPERTY()
	TSubclassOf<UHazeUserWidget> WidgetClass;

	UPROPERTY()
	TSubclassOf<UHazeUserWidget> SecondaryWidgetClass;
}

struct FEnforcerRocketLauncherProjectileIndicatorWidgetData
{
	AHazePlayerCharacter Player;
	UHazeUserWidget Widget; 
}