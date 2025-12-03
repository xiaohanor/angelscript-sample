
UCLASS(Abstract)
class UWorld_Sanctuary_Centipede_Shared_Ambience_Spot_LavaGeyser_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void OnStartGeyser(){}

	/* END OF AUTO-GENERATED CODE */

	UPROPERTY(VisibleAnywhere)
	ASanctuaryCentipedeLavaGeyser LavaGeyser;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		LavaGeyser = Cast<ASanctuaryCentipedeLavaGeyser>(HazeOwner);
	}
}