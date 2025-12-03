UCLASS(Abstract)
class UFeatureAnimInstanceSnowMonkeyHitReactions : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureSnowMonkeyHitReactions Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureSnowMonkeyHitReactionsAnimData AnimData;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	EHazeCardinalDirection Direction = EHazeCardinalDirection::Backward;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	EPlayerAdditiveHitReactionType HitReactionType = EPlayerAdditiveHitReactionType::Small;

	UPlayerAdditiveHitReactionComponent HitReactionComp;

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureSnowMonkeyHitReactions NewFeature = GetFeatureAsClass(ULocomotionFeatureSnowMonkeyHitReactions);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

		HitReactionComp = UPlayerAdditiveHitReactionComponent::GetOrCreate(Game::GetMio());
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
