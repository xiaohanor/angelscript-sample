
UCLASS(Abstract)
class UPlayer_Movement_Falling_SoundDef : UAir_Movement_SoundDef
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	/* END OF AUTO-GENERATED CODE */

	float LastPlayerHeight;

	UFUNCTION(BlueprintPure)
	float GetAirMovementDirection()
	{
		const float PlayerHeight = Player.GetActorLocation().Z;
		const float Direction = Math::Sign(PlayerHeight - LastPlayerHeight);
		
		LastPlayerHeight = PlayerHeight;
		return Direction;
	}	

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return IsRequested();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return !IsRequested();
	}
}