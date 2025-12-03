UCLASS(Abstract)
class UFeatureAnimInstanceSpinnerPortal : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureSpinnerPortal Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureSpinnerPortalAnimData AnimData;

	// Add Custom Variables Here


	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bShootLeft;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bShootRight;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bStartedShooting;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bAttackDone;


	UMeltdownBossPhaseThreeSpinnerAttackComponent AttackComp;


	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		if (HazeOwningActor == nullptr)
			return;

		AttackComp = UMeltdownBossPhaseThreeSpinnerAttackComponent::Get(HazeOwningActor);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureSpinnerPortal NewFeature = GetFeatureAsClass(ULocomotionFeatureSpinnerPortal);
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

		bShootLeft = AttackComp.bShotLeftThisFrame;
		bShootRight = AttackComp.bShotRightThisFrame;
		bStartedShooting = AttackComp.bStartedShooting;
		bAttackDone = AttackComp.bIsAttackDone;
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
