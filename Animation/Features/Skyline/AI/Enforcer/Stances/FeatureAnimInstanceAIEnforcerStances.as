namespace SubTagAIEnforcerStances
{
	
	
	const FName DefensiveStance = n"DefensiveStance";
	const FName AimToDefensiveStance = n"AimToDefensiveStance";
	const FName DefensiveStanceToMH = n"DefensiveStanceToMH";
	const FName DefensiveStanceToAim = n"DefensiveStanceToAim";

}

struct FEnforcerStancesSubTags
{
	UPROPERTY()
	FName DefensiveStance = SubTagAIEnforcerStances::DefensiveStance;	
	UPROPERTY()
	FName AimToDefensiveStance = SubTagAIEnforcerStances::AimToDefensiveStance;	
	UPROPERTY()
	FName DefensiveStanceToMH = SubTagAIEnforcerStances::DefensiveStanceToMH;
	UPROPERTY()
	FName DefensiveStanceToAim = SubTagAIEnforcerStances::DefensiveStanceToAim;
}	


UCLASS(Abstract)
class UFeatureAnimInstanceAIEnforcerStancesDefensiveStance : UFeatureAnimInstanceAIBase
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureAIEnforcerStances Feature;

	UPROPERTY()
	FEnforcerStancesSubTags SubTags;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureAIEnforcerStancesAnimData AnimData;

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		Super::BlueprintInitializeAnimation();
		ULocomotionFeatureAIEnforcerStances NewFeature = GetFeatureAsClass(ULocomotionFeatureAIEnforcerStances);
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
