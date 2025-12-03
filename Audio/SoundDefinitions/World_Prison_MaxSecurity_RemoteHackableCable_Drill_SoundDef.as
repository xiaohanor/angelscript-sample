
UCLASS(Abstract)
class UWorld_Prison_MaxSecurity_RemoteHackableCable_Drill_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void DisconnectedFromSocket(FRemoteHackableCableSocketEventData Data){}

	UFUNCTION(BlueprintEvent)
	void ConnectedToSocket(FRemoteHackableCableSocketEventData Data){}

	UFUNCTION(BlueprintEvent)
	void HitStartPoint(){}

	UFUNCTION(BlueprintEvent)
	void StopHacking(){}

	UFUNCTION(BlueprintEvent)
	void StartHacking(){}

	/* END OF AUTO-GENERATED CODE */

	UPlayerMovementComponent PlayerMoveComp;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		PlayerMoveComp = UPlayerMovementComponent::Get(Game::GetMio());
	}

	UFUNCTION(BlueprintPure)
	float GetStickInput()
	{
		return PlayerMoveComp.SyncedLocalSpaceMovementInputForAnimationOnly.Size();
	}
}