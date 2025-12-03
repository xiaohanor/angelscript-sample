UCLASS(Abstract)
class UPinballBossTargetWidget : UHazeUserWidget
{
	UPROPERTY(BlueprintReadOnly, NotEditable)
	APinballBossTarget BossTarget;

	UFUNCTION(BlueprintEvent)
	void OnCountdownStarted() {}

	UFUNCTION(BlueprintEvent)
	void UpdateCountdown(float Alpha) {}

	UFUNCTION(BlueprintEvent)
	void OnRocketLaunched() {}

	UFUNCTION(BlueprintEvent)
	void OnRocketHit() {}
};