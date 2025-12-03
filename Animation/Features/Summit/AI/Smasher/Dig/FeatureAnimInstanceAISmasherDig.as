namespace SubTagAISmasherDig
{
	const FName DigUp = n"DigUp";	
	const FName DigDown = n"DigDown";	
}

struct FAISmasherDigSubTags
{
	UPROPERTY()
	FName DigUpName = SubTagAISmasherDig::DigUp;
	UPROPERTY()
	FName DigDownName = SubTagAISmasherDig::DigDown;
}

UCLASS(Abstract)
class UFeatureAnimInstanceAISmasherDig : UFeatureAnimInstanceAIBase
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureAISmasherDig Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureAISmasherDigAnimData AnimData;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FAISmasherDigSubTags SubTags;

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		Super::BlueprintInitializeAnimation();
		ULocomotionFeatureAISmasherDig NewFeature = GetFeatureAsClass(ULocomotionFeatureAISmasherDig);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;
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
