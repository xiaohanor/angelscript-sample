
UCLASS(Abstract)
class USolarFlare_Shared_Event_DestructableSidescrollLift_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void OnLiftCrash(FSolarFlareSidescrollLiftParams Params){}

	UFUNCTION(BlueprintEvent)
	void OnLiftFlareBreak(FSolarFlareSidescrollLiftParams Params){}

	UFUNCTION(BlueprintEvent)
	void OnLiftStarted(FSolarFlareSidescrollLiftParams Params){}

	/* END OF AUTO-GENERATED CODE */

	UFUNCTION(BlueprintPure)
	float GetSplineProgression(const USolarFlareSplineMoveComponent SolarSplineComp)
	{
		return Audio::GetSplineProgression(SolarSplineComp.SplinePos);
	}

}