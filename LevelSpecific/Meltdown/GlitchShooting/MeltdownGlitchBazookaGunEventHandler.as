UCLASS(Abstract)
class UMeltdownGlitchBazookaGunEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		
	}

	UFUNCTION(BlueprintPure)
	AMeltdownGlitchBazooka GetGlitchBazooka()
	{
		return Cast<AMeltdownGlitchBazooka>(Owner);
	}

	UFUNCTION(BlueprintEvent)
	void Onfired()
	{

	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void MuzzleLocation() {}
};