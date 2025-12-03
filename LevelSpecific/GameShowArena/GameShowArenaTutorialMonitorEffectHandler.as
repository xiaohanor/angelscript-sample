UCLASS(Abstract)
class UGameShowArenaTutorialMonitorEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void MovingDown() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void SuccesCountUp(FGameShowArenaTutorialMonitorData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void MovingUp() {}
};

struct FGameShowArenaTutorialMonitorData
{
	UPROPERTY()
	float Catches;

	UPROPERTY()
	bool bCompleted = false;
}