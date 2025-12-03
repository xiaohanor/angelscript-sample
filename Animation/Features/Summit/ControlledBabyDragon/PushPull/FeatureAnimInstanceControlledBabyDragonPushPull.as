UCLASS(Abstract)
class UFeatureAnimInstanceControlledBabyDragonPushPull : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureControlledBabyDragonPushPull Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureControlledBabyDragonPushPullAnimData AnimData;

	UPROPERTY(BlueprintReadOnly)
	float WantedPullDirection = 0.0;

	UPlayerPullComponent PullComp;

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureControlledBabyDragonPushPull NewFeature = GetFeatureAsClass(ULocomotionFeatureControlledBabyDragonPushPull);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

		PullComp = UPlayerPullComponent::Get(Player);
	}

	/*UFUNCTION(BlueprintOverride)
	float GetBlendTime() const
	{
		return 0.2;
	}
	*/

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr)
			return;

		WantedPullDirection = PullComp.WantedPullDirection;
	}

	UFUNCTION(BlueprintOverride)
	bool CanTransitionFrom() const
	{
		// Implement Custom Stuff Here

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnTransitionFrom(UHazeFeatureSubAnimInstance NewSubAnimInstance)
	{
		// Implement Custom Stuff Here
	}
}
