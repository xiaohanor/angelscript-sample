
UCLASS(Abstract)
class UPlayer_Movement_Skydive_SoundDef : UAir_Movement_SoundDef
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	/* END OF AUTO-GENERATED CODE */

	
	UFUNCTION(BlueprintOverride)
	bool CanActivate() const
	{
		if(bIsBlocked)
			return false;

		if(MoveComp.IsOnAnyGround())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(bIsBlocked)
			return true;

		if(MoveComp.IsOnAnyGround())
			return true;

		return false;
	}
}