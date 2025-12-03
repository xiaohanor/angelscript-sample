
UCLASS(Abstract)
class UVO_DES_Solarflare_PartOne_ControlRoom_OpenTheMainDoor_SoundDef : UHazeVOSoundDef
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void OnDoubleInteractCompleted(){}

	/* END OF AUTO-GENERATED CODE */

	UFUNCTION(BlueprintPure)
	bool IsOtherPlayerOutOfRange(const AHazePlayerCharacter InPlayer, const float InRange)
	{
		AHazePlayerCharacter OtherPlayer = InPlayer.OtherPlayer;	

		const FVector OwnerLocation = HazeOwner.GetActorLocation();	
		const FVector OtherPlayerLocation = OtherPlayer.GetActorLocation();

		const float InRangeSqrd = InRange * InRange;
		const float DistSqrd = OwnerLocation.DistSquared(OtherPlayerLocation);

		return InRangeSqrd > DistSqrd;

	}

	UFUNCTION()
	bool IfMioIsWaiting(const AHazePlayerCharacter InPlayer)
	{
		if (InPlayer.IsMio() == true)
			return true;
		return false;
	}
}