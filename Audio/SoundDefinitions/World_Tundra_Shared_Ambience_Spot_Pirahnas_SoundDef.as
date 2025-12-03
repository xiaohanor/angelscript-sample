
UCLASS(Abstract)
class UWorld_Tundra_Shared_Ambience_Spot_Pirahnas_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	/* END OF AUTO-GENERATED CODE */

	private APiranha_Tundra Piranha;
	private TArray<FAkSoundPosition> PiranhaPlayerPositions;
	default PiranhaPlayerPositions.SetNum(2);

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		Piranha = Cast<APiranha_Tundra>(HazeOwner);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		FVector MioPos;
		FVector ZoePos;
		Piranha.GetPiranhaPlayerPositions(MioPos, ZoePos);

		if(!MioPos.IsZero())
			PiranhaPlayerPositions[0].SetPosition(MioPos);

		if(!ZoePos.IsZero())
			PiranhaPlayerPositions[1].SetPosition(ZoePos);

		DefaultEmitter.AudioComponent.SetMultipleSoundPositions(PiranhaPlayerPositions);
	}
}