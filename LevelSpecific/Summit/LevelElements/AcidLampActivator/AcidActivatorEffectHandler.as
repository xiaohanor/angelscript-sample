struct FAcidActivatorProgressParams
{
	UPROPERTY()
	float Progress;

	FAcidActivatorProgressParams(float NewProgress)
	{
		Progress = NewProgress;
	}
}

UCLASS(Abstract)
class UAcidActivatorEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLampStartFilling() 
	{
		Print("START Filling");
	}
	
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLampStopFilling() {Print("STOP Filling");}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLampStartDecaying() {Print("START Decay");}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLampStopDecaying() {Print("STOP Decay");}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void UpdateAcidLampProgress(FAcidActivatorProgressParams Params) {}
};