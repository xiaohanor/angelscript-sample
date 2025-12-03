
UCLASS(Abstract)
class UWorld_Sanctuary_Upper_Interactable_WellGateLightActivator_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void BothAbilitiesActivatedSuccess(){}

	UFUNCTION(BlueprintEvent)
	void SocketInDoor(){}

	UFUNCTION(BlueprintEvent)
	void SocketReturnedToStartPosition(){}

	UFUNCTION(BlueprintEvent)
	void SocketReleasedMovingToStartPosition(){}

	UFUNCTION(BlueprintEvent)
	void SocketGrabbedMovingTowardsDoor(){}

	UFUNCTION(BlueprintEvent)
	void LightProgressTimeLikeFinished(){}

	/* END OF AUTO-GENERATED CODE */
	
	ASanctuaryWellGateLightActivator LightActivator;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		LightActivator = Cast<ASanctuaryWellGateLightActivator>(HazeOwner);
	}
	
	UFUNCTION(BlueprintPure)
	float GetLightProgressValue() const
	{
		return LightActivator.LightProgressTimeLike.Value;
	}
}