UCLASS(Abstract)
class UFeatureAnimInstanceZipKites : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureZipKites Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureZipKitesAnimData AnimData;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FZipKiteAnimData ZipKiteAnimData;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	EZipKitePlayerStates State;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float AdditivePlayRate;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float AdditiveAlpha;

	UZipKitePlayerComponent ZipKitePlayerComp;

	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		if (HazeOwningActor == nullptr)
			return;

	}

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureZipKites NewFeature = GetFeatureAsClass(ULocomotionFeatureZipKites);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

		ZipKitePlayerComp = UZipKitePlayerComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr)
			return;

		ZipKiteAnimData = ZipKitePlayerComp.AnimData;

		AdditiveAlpha = Math::Lerp(0.4, 1, ZipKiteAnimData.MashRate);
		AdditivePlayRate = Math::Lerp(0.75, 1.25, ZipKiteAnimData.MashRate);

		State = ZipKitePlayerComp.PlayerKiteData.PlayerState;
	}

	UFUNCTION(BlueprintOverride)
	bool CanTransitionFrom() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnTransitionFrom(UHazeFeatureSubAnimInstance NewSubAnimInstance)
	{
	}
}
