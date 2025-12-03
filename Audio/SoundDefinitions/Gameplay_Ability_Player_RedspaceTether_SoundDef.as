
UCLASS(Abstract)
class UGameplay_Ability_Player_RedspaceTether_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void TetherDisabled(){}

	UFUNCTION(BlueprintEvent)
	void TetherEnabled(){}

	/* END OF AUTO-GENERATED CODE */

	ARedSpaceTether Teather;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		Teather = Cast<ARedSpaceTether>(HazeOwner);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		const FVector MidPoint = Teather.GetTeatherMidPoint();
		DefaultEmitter.AudioComponent.SetWorldLocation(MidPoint);
	}

}