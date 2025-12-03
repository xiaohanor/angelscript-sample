
UCLASS(Abstract)
class UWorld_Sanctuary_Boss_Interactable_SanctuaryHydraKillerBallista_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void OnButtonMashCompleted(){}

	UFUNCTION(BlueprintEvent)
	void OnStartDoubleInteraction(){}

	UFUNCTION(BlueprintEvent)
	void OnStopDoubleInteraction(){}

	/* END OF AUTO-GENERATED CODE */

	ASanctuaryHydraKillerBallista Ballista;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		Ballista = Cast<ASanctuaryHydraKillerBallista>(HazeOwner);
	}

	UFUNCTION(BlueprintPure)
	float GetButtonMashProgress()
	{
		return Ballista.CombinedProgress;
	}
}