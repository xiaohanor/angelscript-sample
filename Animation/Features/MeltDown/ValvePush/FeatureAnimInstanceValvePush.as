UCLASS(Abstract)
class UFeatureAnimInstanceValvePush : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureValvePush Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureValvePushAnimData AnimData;

	// Add Custom Variables Here

	//Becomes true when button mashing
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsPushing;

	//Becomes true when both players are button mashing. Only when both push does the characters turn the valve
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bBothArePushing;

	//When the feature tag is no longer called
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bExit;

	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		if (HazeOwningActor == nullptr)
			return;
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureValvePush NewFeature = GetFeatureAsClass(ULocomotionFeatureValvePush);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

		bExit = false;
	}

	/*UFUNCTION(BlueprintOverride)
	float GetBlendTime() const
	{
		return 0.2f;
	}
	*/

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr)
			return;

		ASoftSplitValveDoubleInteract ValveDoor = TListedActors<ASoftSplitValveDoubleInteract>().GetSingle();
		bIsPushing = ValveDoor.bPushing[Player] || ValveDoor.bIsSpinning;
		bBothArePushing = ValveDoor.bIsSpinning;

		bExit = LocomotionAnimationTag != n"ValvePush";
	}

	UFUNCTION(BlueprintOverride)
	bool CanTransitionFrom() const
	{
		// Implement Custom Stuff Here

		if(LocomotionAnimationTag != n"Movement" || IsLowestLevelGraphRelevantAnimFinished())
		{
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnTransitionFrom(UHazeFeatureSubAnimInstance NewSubAnimInstance)
	{
		// Implement Custom Stuff Here
	}
}
