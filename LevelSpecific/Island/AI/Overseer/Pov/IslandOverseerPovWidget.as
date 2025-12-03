event void FIslandOverseerPovWidgetStartupCompleted();
event void FIslandOverseerPovWidgetShutdownCompleted();

class UIslandOverseerPovWidget : UHazeUserWidget
{
	UPROPERTY()
	FIslandOverseerPovWidgetStartupCompleted OnStartupCompleted;

	UPROPERTY()
	FIslandOverseerPovWidgetShutdownCompleted OnShutdownCompleted;

	UPROPERTY()
	float Health;

	UFUNCTION(BlueprintEvent)
	void OnHit() {}

	UFUNCTION(BlueprintEvent)
	void OnStartup() {}

	UFUNCTION(BlueprintEvent)
	void OnShutdown() {}
}