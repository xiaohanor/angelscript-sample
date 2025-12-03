namespace SubTagAIEnforcerShooting
{
	const FName Telegraph = n"Telegraph";
	const FName Shoot = n"Shoot";
	const FName ThrowGrenade = n"ThrowGrenade";
}

struct FEnforcerShootingSubTags
{
	UPROPERTY()
	FName Telegraph = SubTagAIEnforcerShooting::Telegraph;	
	UPROPERTY()
	FName Shoot = SubTagAIEnforcerShooting::Shoot;	
	UPROPERTY()
	FName ThrowGrenade = SubTagAIEnforcerShooting::ThrowGrenade;	
}

UCLASS(Abstract)
class UFeatureAnimInstanceEnforcerShooting : UFeatureAnimInstanceAIBase
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureEnforcerShooting Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureEnforcerShootingAnimData AnimData;

	UPROPERTY(Transient, BlueprintReadOnly,NotEditable)
	FEnforcerShootingSubTags SubTags;


	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		if (HazeOwningActor == nullptr)
			return;

	}

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		Super::BlueprintInitializeAnimation();

		ULocomotionFeatureEnforcerShooting NewFeature = GetFeatureAsClass(ULocomotionFeatureEnforcerShooting);
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
