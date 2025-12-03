UCLASS(Abstract)
class UFeatureAnimInstanceSnowMonkeySwimming : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureSnowMonkeySwimming Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureSnowMonkeySwimmingAnimData AnimData;


	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureSnowMonkeySwimming NewFeature = GetFeatureAsClass(ULocomotionFeatureSnowMonkeySwimming);
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
	}


	UFUNCTION(BlueprintOverride)
	void OnTransitionFrom(UHazeFeatureSubAnimInstance NewSubAnimInstance)
	{
	
	}

	UFUNCTION(BlueprintOverride)
	bool CanTransitionFrom() const
	{
		if (LocomotionAnimationTag == n"None")
		{
			return IsTopLevelGraphRelevantAnimFinished();

		}
		else
		{
			return true;
		}
	}


}
