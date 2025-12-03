
UCLASS(Abstract)
class UWorld_Meltdown_SplitTraversal_Interactable_SplitTraversalInteractableTurret_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void OnInteractionStopped(){}

	UFUNCTION(BlueprintEvent)
	void OnInteractionStarted(){}

	UFUNCTION(BlueprintEvent)
	void OnFire(){}

	UFUNCTION(BlueprintEvent)
	void OnArrowHit(FSplitTraversalControllableTurretArrowParams Params){}

	/* END OF AUTO-GENERATED CODE */

	UPROPERTY(EditInstanceOnly)
	UHazeAudioEmitter SciFiTurretEmitter;
	UPROPERTY(EditInstanceOnly)
	UHazeAudioEmitter FantasyBallistaEmitter;

	ASplitTraversalControllableTurret Turret;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		Turret = Cast<ASplitTraversalControllableTurret>(HazeOwner);
	}

	UFUNCTION(BlueprintPure)
	void GetMovementInputForce(float&out Pitch, float&out Yaw)
	{	
		Pitch = Turret.PitchForceComp.Force.Size() * Math::Sign(Turret.PitchForceComp.Force.SignVector.X);		
		Yaw = Turret.YawForceComp.Force.Size() * Math::Sign(Turret.YawForceComp.Force.SignVector.X);
	}
}