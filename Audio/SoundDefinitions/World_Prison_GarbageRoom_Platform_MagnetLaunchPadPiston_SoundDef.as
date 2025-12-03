
UCLASS(Abstract)
class UWorld_Prison_GarbageRoom_Platform_MagnetLaunchPadPiston_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	/* END OF AUTO-GENERATED CODE */

	UPROPERTY(BlueprintReadOnly)
	AGarbageRoomMagneticLaunchPadPiston MagneticPadLaunchPiston;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		MagneticPadLaunchPiston = Cast<AGarbageRoomMagneticLaunchPadPiston>(HazeOwner);
	}

	UFUNCTION(BlueprintPure)
	float GetLaunchPistonPosition()
	{
		return MagneticPadLaunchPiston.MoveTimeLike.Value;
	}
}