UCLASS(Abstract)
class UFeatureAnimInstanceVault : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureVault Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureVaultAnimData AnimData;

	UPROPERTY()
	UPlayerVaultComponent VaultComp;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FPlayerVaultAnimationData VaultAnimData;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool IsMirrored;

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureVault NewFeature = GetFeatureAsClass(ULocomotionFeatureVault);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

		VaultComp = UPlayerVaultComponent::Get(Player);

		VaultAnimData = VaultComp.AnimData;
		
		IsMirrored = VaultAnimData.bIsMirrored;
	}

	UFUNCTION(BlueprintOverride)
	float GetBlendTime() const
	{
		return 0.1;
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr)
			return;

		VaultAnimData = VaultComp.AnimData;

	}

	UFUNCTION(BlueprintOverride)
	bool CanTransitionFrom() const
	{
		if (LocomotionAnimationTag != n"Movement")
		{
			return true;
		}

		return TopLevelGraphRelevantAnimTimeRemaining <= HazeAnimation::ANIMATION_MIN_TIME;

	}

	UFUNCTION(BlueprintOverride)
	void OnTransitionFrom(UHazeFeatureSubAnimInstance NewSubAnimInstance)
	{
	}
}
