namespace SubTagAIRocketLauncher
{
	
	
	const FName MHToAim = n"MHToAim";
	const FName Aim = n"Aim";
	const FName Shoot = n"Shoot";

}

struct FRocketLauncherSubTags
{
	UPROPERTY()
	FName MHToAim = SubTagAIRocketLauncher::MHToAim;	
	UPROPERTY()
	FName Aim = SubTagAIRocketLauncher::Aim;	
	UPROPERTY()
	FName Shoot = SubTagAIRocketLauncher::Shoot;	


}

UCLASS(Abstract)
class UFeatureAnimInstanceRocketLauncher : UFeatureAnimInstanceAIBase
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureRocketLauncher Feature;

	UPROPERTY()
	FRocketLauncherSubTags SubTags;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureRocketLauncherAnimData AnimData;

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		Super::BlueprintInitializeAnimation();
		
		ULocomotionFeatureRocketLauncher NewFeature = GetFeatureAsClass(ULocomotionFeatureRocketLauncher);
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
