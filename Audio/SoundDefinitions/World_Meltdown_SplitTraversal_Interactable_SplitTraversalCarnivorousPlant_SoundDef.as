
UCLASS(Abstract)
class UWorld_Meltdown_SplitTraversal_Interactable_SplitTraversalCarnivorousPlant_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void OnStartRetract(){}

	UFUNCTION(BlueprintEvent)
	void OnStartAttack(){}

	UFUNCTION(BlueprintEvent)
	void OnWakeUp(){}

	UFUNCTION(BlueprintEvent)
	void OnActivatorInteractionStart(){}

	UFUNCTION(BlueprintEvent)
	void OnActivatorInteractionStop(){}

	/* END OF AUTO-GENERATED CODE */	

	ASplitTraversalCarnivorousPlant2 Plant;	
	FVector CachedHeadForward;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		Plant = Cast<ASplitTraversalCarnivorousPlant2>(HazeOwner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return Plant.bActive;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return !Plant.bActive;
	}

	UFUNCTION(BlueprintPure)
	float GetHeadVerticalMovementDirection()
	{
		float HeadVerticalMovementDirection = 0.0;

	 	FVector HeadVerticalVelo = CachedHeadForward - Plant.HeadRoot.ForwardVector;
		HeadVerticalVelo = HeadVerticalVelo.ConstrainToDirection(FVector::ForwardVector);
		if(HeadVerticalVelo.Size() > SMALL_NUMBER)		
			HeadVerticalMovementDirection = Math::Sign(HeadVerticalVelo.X);	
		
		CachedHeadForward = Plant.HeadRoot.ForwardVector;
		return HeadVerticalMovementDirection;
	}
}