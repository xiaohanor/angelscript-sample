UCLASS(Abstract)
class UFeatureAnimInstanceBarrelThrow : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureBarrelThrow Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureBarrelThrowAnimData AnimData;

	// Add Custom Variables Here
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bThrow;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bBossLeft;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bBossRight;

	UIslandOverseerReturnGrenadePlayerComponent GrenadeComp;

	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		if (HazeOwningActor == nullptr)
			return;
		// Get components here...
		GrenadeComp = UIslandOverseerReturnGrenadePlayerComponent::GetOrCreate(HazeOwningActor);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureBarrelThrow NewFeature = GetFeatureAsClass(ULocomotionFeatureBarrelThrow);
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
		if(GrenadeComp != nullptr)
		{
			bThrow = GrenadeComp.bReturnLeft || GrenadeComp.bReturnRight;
			bBossLeft = GrenadeComp.bReturnLeft;
			bBossRight = GrenadeComp.bReturnRight;
		}
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
