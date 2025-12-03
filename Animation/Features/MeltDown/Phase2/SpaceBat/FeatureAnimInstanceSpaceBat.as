UCLASS(Abstract)
class UFeatureAnimInstanceSpaceBat : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureSpaceBat Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureSpaceBatAnimData AnimData;

	// Add Custom Variables Here

	//Rader swings at a meteor on screen left if facing Rader's direction
	UPROPERTY()
	bool bSwingFromLeft;

	//Rader swings at a meteor on screen right if facing Rader's direction
	UPROPERTY()
	bool bSwingFromRight;

	//Rader drops the bat to move into another attack
	UPROPERTY()
	bool bDropBat;

	//Rader's health is depleted and the entire boss phase is over
	UPROPERTY()
	bool bPhaseFinish;

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
		ULocomotionFeatureSpaceBat NewFeature = GetFeatureAsClass(ULocomotionFeatureSpaceBat);
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
			bSwingFromLeft = Rader.LastLeftAttackFrame >= GFrameNumber-1;
			bSwingFromRight = Rader.LastRightAttackFrame >= GFrameNumber-1;

			bDropBat = Rader.CurrentAttack != EMeltdownPhaseTwoAttack::SpaceBat;
			bPhaseFinish = bDropBat && !Rader.bThresholdActive;
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
