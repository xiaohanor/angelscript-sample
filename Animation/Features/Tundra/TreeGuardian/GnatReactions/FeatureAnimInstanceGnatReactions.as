UCLASS(Abstract)
class UFeatureAnimInstanceGnatReactions : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureGnatReactions Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureGnatReactionsAnimData AnimData;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	int NumberOfGnats = 0;

	UTundraGnapeAnnoyedPlayerComponent AnnoyedByGnatsComp;

	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		if (HazeOwningActor == nullptr)
			return;

	}

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		if ((OwningComponent != nullptr) && (OwningComponent.Owner != nullptr))
			AnnoyedByGnatsComp = UTundraGnapeAnnoyedPlayerComponent::Get(OwningComponent.Owner);
		NumberOfGnats = 1; // Assume there's one gnat until we know for sure (or we will exit immediately)

		ULocomotionFeatureGnatReactions NewFeature = GetFeatureAsClass(ULocomotionFeatureGnatReactions);
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
		if (Feature == nullptr)
			return;

		if (AnnoyedByGnatsComp != nullptr)
			NumberOfGnats = AnnoyedByGnatsComp.AnnoyingGnapes.Num();
	}

	UFUNCTION(BlueprintOverride)
	bool CanTransitionFrom() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnTransitionFrom(UHazeFeatureSubAnimInstance NewSubAnimInstance)
	{
	}
}
