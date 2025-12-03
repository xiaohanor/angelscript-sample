UCLASS(Abstract)
class UFeatureAnimInstanceFlowerHat : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureFlowerHat Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureFlowerHatAnimData AnimData;

	// Add Custom Variables Here
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bDancing;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float Speed;

	UMoonMarketPlayerFlowerSpawningComponent FlowerComp;

	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		if (HazeOwningActor == nullptr)
			return;
		// Get components here...

		FlowerComp = UMoonMarketPlayerFlowerSpawningComponent::Get(HazeOwningActor);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureFlowerHat NewFeature = GetFeatureAsClass(ULocomotionFeatureFlowerHat);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

		// Implement Custom Stuff Here
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

		// Implement Custom Stuff Here

		if(FlowerComp == nullptr)
			return;

		bDancing = FlowerComp.bIsDancing;
		Speed = HazeOwningActor.ActorHorizontalVelocity.Size();
		PrintToScreen("Speed " + Speed);
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
