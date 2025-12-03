namespace SubTagSanctuaryRangedGhostAttack
{
	const FName Attack = n"Attack";
}

struct FSanctuaryRangedGhostAttackSubTags
{
	UPROPERTY()
	FName Attack = SubTagSanctuaryRangedGhostAttack::Attack;	
}

UCLASS(Abstract)
class UFeatureAnimInstanceRangedGhostAttack : UFeatureAnimInstanceAIBase
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureRangedGhostAttack Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureRangedGhostAttackAnimData AnimData;

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		Super::BlueprintInitializeAnimation();

		ULocomotionFeatureRangedGhostAttack NewFeature = GetFeatureAsClass(ULocomotionFeatureRangedGhostAttack);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		Super::BlueprintUpdateAnimation(DeltaTime);

		if (Feature == nullptr)
			return;
	}

	UFUNCTION(BlueprintOverride)
	bool CanTransitionFrom() const
	{
		return TopLevelGraphRelevantAnimTimeRemaining <= 0.1;
	}

	UFUNCTION(BlueprintOverride)
	void OnTransitionFrom(UHazeFeatureSubAnimInstance NewSubAnimInstance)
	{
	}
}
