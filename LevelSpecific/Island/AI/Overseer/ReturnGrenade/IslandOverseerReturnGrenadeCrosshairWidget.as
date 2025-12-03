class UIslandOverseerReturnGrenadeCrosshairWidget : UHazeUserWidget
{
	FVector TargetLocation;
	FHazeAcceleratedVector AccLocation;

	UFUNCTION(BlueprintEvent)
	void OnTelegraphing() {}

	UFUNCTION(BlueprintEvent)
	void OnFire() {}

	UFUNCTION(BlueprintOverride)
	void RemoveFromScreen()
	{
		if (!IsAnyAnimationPlaying())
			FinishRemovingWidget();
	}

	UFUNCTION(BlueprintOverride)
	void OnAnimationFinished(const UWidgetAnimation Animation)
	{
		if (bIsInDelayedRemove)
			FinishRemovingWidget();
	}
}