struct FTundra_River_InteractableConeBellEffectParams
{
	FTundra_River_InteractableConeBellEffectParams(float In_Strength)
	{
		Strength = In_Strength;
	}

	UPROPERTY()
	float Strength;
}

UCLASS(Abstract)
class UTundra_River_InteractableConeBellEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnClapperHitSoundBow(FTundra_River_InteractableConeBellEffectParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPlayerStartImpactingBell(FTundra_River_InteractableConeBellEffectParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPlayerStopImpactingBell() {}
}