UCLASS(Abstract)
class UPrisonBossFirstPersonDebrisTargetWidget : UHazeUserWidget
{
	UPROPERTY(BlueprintReadOnly)
	float WidgetScale = 1.0;

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry MyGeometry, float InDeltaTime)
	{
		WidgetScale = 0.75 + (Math::Sin(Time::GameTimeSeconds * 2.5) * 0.25);
	}
}