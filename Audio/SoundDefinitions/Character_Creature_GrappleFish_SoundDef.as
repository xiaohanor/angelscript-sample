
UCLASS(Abstract)
class UCharacter_Creature_GrappleFish_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void OnFinalJumpStarted(){}

	UFUNCTION(BlueprintEvent)
	void OnResurface(){}

	UFUNCTION(BlueprintEvent)
	void OnDiveSandSurfaceBreached(FGrappleFishSandSurfaceBreachedParams Params){}

	UFUNCTION(BlueprintEvent)
	void OnDiveStarted(){}

	UFUNCTION(BlueprintEvent)
	void OnStopSwimming(){}

	UFUNCTION(BlueprintEvent)
	void OnStartSwimming(){}

	/* END OF AUTO-GENERATED CODE */
	
	ADesertGrappleFish GrappleFish;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		GrappleFish = Cast<ADesertGrappleFish>(HazeOwner);
	}

	UFUNCTION(BlueprintPure)
	float GetStickInput()
	{
		if (GrappleFish.MountedPlayer == nullptr)
		{
			return 0;
		}
		UHazeMovementComponent MountedPlayerMoveComp = UHazeMovementComponent::Get(GrappleFish.MountedPlayer);
		/*PrintToScreenScaled("" + MountedPlayerMoveComp.SyncedLocalSpaceMovementInputForAnimationOnly.Size());*/

		return MountedPlayerMoveComp.SyncedLocalSpaceMovementInputForAnimationOnly.Size();
	}

}