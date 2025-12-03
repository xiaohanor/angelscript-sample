
UCLASS(Abstract)
class UWorld_Skyline_Shared_Interactable_GravityWhip_Movable_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void ConstrainHitLowAlpha(FGravityWhipMovableParams GravityWhipMovableParams){}

	UFUNCTION(BlueprintEvent)
	void ConstrainHitHighAlpha(FGravityWhipMovableParams GravityWhipMovableParams){}

	UFUNCTION(BlueprintEvent)
	void GravityWhipGrabbed(){}

	UFUNCTION(BlueprintEvent)
	void GravityWhipReleased(){}

	UFUNCTION(BlueprintEvent)
	void StartMoving(){}

	UFUNCTION(BlueprintEvent)
	void StopMoving(){}

	UFUNCTION(BlueprintEvent)
	void StartMovingFromLowAlpha(){}

	UFUNCTION(BlueprintEvent)
	void StartMovingFromHighAlpha(){}

	/* END OF AUTO-GENERATED CODE */

	UPROPERTY(BlueprintReadOnly, NotVisible)
	UFauxPhysicsTranslateComponent FauxTranslationComp;

	UPROPERTY(BlueprintReadOnly, NotVisible)
	UFauxPhysicsSplineFollowComponent FauxSplineComp;

	//UPROPERTY(BlueprintReadOnly)
	//FVector Alpha;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		FauxTranslationComp = UFauxPhysicsTranslateComponent::Get(HazeOwner);
		FauxSplineComp = UFauxPhysicsSplineFollowComponent::Get(HazeOwner);
	}

	UFUNCTION(BlueprintPure)
	FVector GetFauxTranslationAlphaVector()
	{
		if (FauxTranslationComp != nullptr)
			return FauxTranslationComp.GetCurrentAlphaBetweenConstraints();
		return FVector();
	}

	UFUNCTION(BlueprintPure)
	float GetFauxSplineAlphaFloat()
	{
		if (FauxSplineComp != nullptr)
			return FauxSplineComp.GetCurrentAlphaBetweenConstraints();
		return 0;
	}
}

USTRUCT()
struct FGravityWhipMovableParams
{
	UPROPERTY()
	float HitStrength = 0;

}