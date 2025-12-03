
UCLASS(Abstract)
class UGameplay_Vehicle_Player_Dragon_Baby_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	/* END OF AUTO-GENERATED CODE */

	UPROPERTY(BlueprintReadOnly, NotVisible)
	UDragonMovementAudioComponent MoveAudioComp;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		MoveAudioComp = UDragonMovementAudioComponent::Get(HazeOwner);
	}
}