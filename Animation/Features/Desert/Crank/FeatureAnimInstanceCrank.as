UCLASS(Abstract)
class UFeatureAnimInstanceCrank : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureCrank Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureCrankAnimData AnimData;

	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	UDesertPlayerCrankComponent CrankComp;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FDesertPlayerCrankData CrankData;

	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		if (HazeOwningActor == nullptr)
			return;

	}

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureCrank NewFeature = GetFeatureAsClass(ULocomotionFeatureCrank);
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

		CrankComp = UDesertPlayerCrankComponent::Get(Player);
		if (CrankComp == nullptr)
			return;

		CrankData = CrankComp.CrankData;
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
