UCLASS(Abstract)
class UFeatureAnimInstanceGameShowBombOverride : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureGameShowBombOverride Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureGameShowBombOverrideAnimData AnimData;

	// Add Custom Variables Here

	UPROPERTY()
	float ThrowAngle;

	UPROPERTY()
	bool bThrow;

	UPROPERTY()
	bool bCatch;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FGameShowArenaBombTossAnimationParams BombAnimParams;

	UGameShowArenaBombTossPlayerComponent BombTossPlayerComponent;


	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		if (HazeOwningActor == nullptr)
			return;

		BombTossPlayerComponent = UGameShowArenaBombTossPlayerComponent::Get(Player);
		// Get components here...

	}

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureGameShowBombOverride NewFeature = GetFeatureAsClass(ULocomotionFeatureGameShowBombOverride);
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
		BombAnimParams = BombTossPlayerComponent.AnimParams;
		ThrowAngle = BombAnimParams.ThrowAngle;
		bCatch = BombAnimParams.bCatch;
		bThrow = BombAnimParams.bThrow;
		//ThrowAngle = ThrowAngle;
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
