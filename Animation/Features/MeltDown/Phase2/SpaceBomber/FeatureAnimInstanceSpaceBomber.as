UCLASS(Abstract)
class UFeatureAnimInstanceSpaceBomber : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureSpaceBomber Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureSpaceBomberAnimData AnimData;

	// Add Custom Variables Here

	//Rader shoots out bombs from the ship. When this turns false, he lets go of the ship and goes to a neutral MH
	UPROPERTY()
	bool bShooting;

	//Rader changes attack feature. Might not be needed at all, since the bShooting variable means that this feature just has Rader in an MH when he has let go of the bomb ship instead of playing a specific transition animation
	UPROPERTY()
	bool bChangeAttack;

	//Rader's HP is depleted and the boss transitions into the next Meltdown level
	UPROPERTY()
	bool bHealthDepleted;

	AMeltdownBossPhaseTwo Rader;


	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		if (HazeOwningActor == nullptr)
			return;

		Rader = Cast<AMeltdownBossPhaseTwo>(HazeOwningActor);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureSpaceBomber NewFeature = GetFeatureAsClass(ULocomotionFeatureSpaceBomber);
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

		if (Rader != nullptr)
		{
			bShooting = Rader.bIsFiringBombs;
			bChangeAttack = Rader.CurrentAttack != EMeltdownPhaseTwoAttack::SpaceBomber;
			bHealthDepleted = bChangeAttack && !Rader.bThresholdActive;
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
