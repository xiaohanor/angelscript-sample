
UCLASS(Abstract)
class UCharacter_Boss_Tundra_IceKing_Movement_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	/* END OF AUTO-GENERATED CODE */

	UPROPERTY(NotVisible)
	UHazeAudioEmitter BodyEmitter;

	UPROPERTY(NotVisible)
	UHazeAudioEmitter FrontFeetEmitter;

	UPROPERTY(NotVisible)
	UHazeAudioEmitter RearFeetEmitter;

	// UPROPERTY(BlueprintReadOnly)
	// float BodyMovementSpeedLinearNormalized;

	// UPROPERTY(BlueprintReadOnly)
	// float BodyMovementSpeedDeltaNormalized;

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		
	}
}