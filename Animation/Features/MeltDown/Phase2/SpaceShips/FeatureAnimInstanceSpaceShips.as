UCLASS(Abstract)
class UFeatureAnimInstanceSpaceShips : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureSpaceShips Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureSpaceShipsAnimData AnimData;

	// Add Custom Variables Here

	//Rader throws the ship in his left hand, the hand to the right side of the screen when looking at Rader
	UPROPERTY()
	bool bThrowLeftHand;

	//Rader throws the ship in his right hand, the hand to the left side of the screen when looking at Rader 
	UPROPERTY()
	bool bThrowRightHand;

	//Rader changes attack feature. Might not be needed at all, since this feature just has Rader in an MH when he has thrown both ships
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
		ULocomotionFeatureSpaceShips NewFeature = GetFeatureAsClass(ULocomotionFeatureSpaceShips);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

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
			bThrowLeftHand = Rader.LastLeftAttackFrame >= GFrameNumber-1;
			bThrowRightHand = Rader.LastRightAttackFrame >= GFrameNumber-1;

			bChangeAttack = Rader.CurrentAttack != EMeltdownPhaseTwoAttack::SpaceBat;
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
