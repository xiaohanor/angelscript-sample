
UCLASS(Abstract)
class UWorld_GameShow_Shared_Interactable_Bomb_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	/* END OF AUTO-GENERATED CODE */

	AGameShowArenaBomb ArenaBomb;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		ArenaBomb = Cast<AGameShowArenaBomb>(HazeOwner);
	}

	UFUNCTION()
	void NotifyGameplayOfEnvelopeValue(float InValue)
	{
		ArenaBomb.SetAudioEnvelopeValue(InValue);
	}

	UFUNCTION()
	void NotifyGameplayOfEnvelopeStart()
	{
		ArenaBomb.AudioEnvelopeStart();
	}

	UFUNCTION()
	void NotifyGameplayOfEnvelopeStop()
	{
		ArenaBomb.AudioEnvelopeStop();
	}
}