UCLASS(Abstract)
class USummitBouncyBirdNestEventHandler : UHazeEffectEventHandler
{

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLand()
    {
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLaunch()
    {
	}

};