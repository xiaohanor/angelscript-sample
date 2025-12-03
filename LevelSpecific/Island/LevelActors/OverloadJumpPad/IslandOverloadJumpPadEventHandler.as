UCLASS(Abstract)
class UIslandOverloadJumpPadEventHandler : UHazeEffectEventHandler
{
	AIslandOverloadJumpPad JumpPad;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		JumpPad = Cast<AIslandOverloadJumpPad>(Owner);
	}

	UFUNCTION(BlueprintPure)
	float RetractAlpha()
	{
		return JumpPad.GetPanelAlpha();
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Retract()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void RetractStop()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Launched()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void ResetStart()
	{
	}
	
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void ResetStop()
	{
	}

};