
UCLASS(Abstract)
class UGameplay_Creature_Tundra_Evergreen_WalkingStick_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	/* END OF AUTO-GENERATED CODE */

	UPROPERTY(NotEditable)
	UHazeAudioEmitter CloseFootEmitter;

	UPROPERTY(NotEditable)
	UHazeAudioEmitter DistantFootEmitter;

	private TArray<FVector> TrackedArmLocations;
	
	private TArray<FName> ArmSocketNames;
	default ArmSocketNames.Add(n"Hand");
	default ArmSocketNames.Add(n"Hand");
	default ArmSocketNames.Add(n"Hand");
	default ArmSocketNames.Add(n"Hand");
}