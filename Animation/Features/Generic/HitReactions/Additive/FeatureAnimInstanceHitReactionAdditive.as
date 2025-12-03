enum EPlayerAdditiveHitReactionType
{
	None,
	Small,
	Big
}

UCLASS(Abstract)
class UFeatureAnimInstanceHitReaction_Additive : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureHitReaction_Additive Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureHitReaction_AdditiveAnimData AnimData;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	EHazeCardinalDirection Direction = EHazeCardinalDirection::Backward;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	EPlayerAdditiveHitReactionType HitReactionType = EPlayerAdditiveHitReactionType::Small;

	UPlayerAdditiveHitReactionComponent HitReactionComp;

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureHitReaction_Additive NewFeature = GetFeatureAsClass(ULocomotionFeatureHitReaction_Additive);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

		HitReactionComp = UPlayerAdditiveHitReactionComponent::GetOrCreate(HazeOwningActor);
	}

	
	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (HitReactionComp == nullptr)
			return;

		Direction = HitReactionComp.HitDirection; 
		HitReactionType = HitReactionComp.HitType;
	}

	UFUNCTION(BlueprintOverride)
	bool CanTransitionFrom() const
	{
		if (TopLevelGraphRelevantAnimTimeRemaining > 0.01)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnTransitionFrom(UHazeFeatureSubAnimInstance NewSubAnimInstance)
	{
	}

}


