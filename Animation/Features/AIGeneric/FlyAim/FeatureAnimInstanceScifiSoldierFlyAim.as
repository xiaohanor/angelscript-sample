namespace SubTagAIFlyAim
{
	const FName Land = n"Land";	
}

struct FAIFlyAimSubTags
{
	UPROPERTY()
	FName LandName = SubTagAIFlyAim::Land;	
}

UCLASS(Abstract)
class UFeatureAnimInstanceScifiSoldierFlyAim : UFeatureAnimInstanceAIBase
{

	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureScifiSoldierFlyAim Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureScifiSoldierFlyAimAnimData AnimData;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FAIFlyAimSubTags SubTags;


	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		Super::BlueprintInitializeAnimation();
		ULocomotionFeatureScifiSoldierFlyAim NewFeature = GetFeatureAsClass(ULocomotionFeatureScifiSoldierFlyAim);
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
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnTransitionFrom(UHazeFeatureSubAnimInstance NewSubAnimInstance)
	{
	}
}
