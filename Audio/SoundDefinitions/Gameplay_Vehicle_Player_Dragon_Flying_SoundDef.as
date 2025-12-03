
UCLASS(Abstract)
class UGameplay_Vehicle_Player_Dragon_Flying_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	/* END OF AUTO-GENERATED CODE */

	UPROPERTY(BlueprintReadOnly, NotVisible)
	UDragonMovementAudioComponent DragonMoveComp;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		DragonMoveComp = UDragonMovementAudioComponent::Get(HazeOwner);
	}

}