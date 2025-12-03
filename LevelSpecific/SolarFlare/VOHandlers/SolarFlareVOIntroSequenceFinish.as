UCLASS(Abstract)
class USolarFlareVOIntroSequenceFinish : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSequenceIntroFinished()
	{
	}
};