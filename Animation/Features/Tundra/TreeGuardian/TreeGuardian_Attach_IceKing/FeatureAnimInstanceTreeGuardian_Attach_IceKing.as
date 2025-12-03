UCLASS(Abstract)
class UFeatureAnimInstanceTreeGuardian_Attach_IceKing : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureTreeGuardian_Attach_IceKing Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureTreeGuardian_Attach_IceKingAnimData AnimData;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bSuccess = false;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bFail = false;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float ButtonMashProgress = 0.0;

	UTundraPlayerTreeGuardianComponent TreeGuardianComp;

	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		if (HazeOwningActor == nullptr)
			return;

		TreeGuardianComp = UTundraPlayerTreeGuardianComponent::Get(HazeOwningActor.AttachParentActor);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureTreeGuardian_Attach_IceKing NewFeature = GetFeatureAsClass(ULocomotionFeatureTreeGuardian_Attach_IceKing);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr)
			return;

		bSuccess = TreeGuardianComp.HoldDownIceKingAnimData.bSuccess;
		bFail = TreeGuardianComp.HoldDownIceKingAnimData.bFail;
		ButtonMashProgress = Math::Lerp(-1.0, 1.0, TreeGuardianComp.HoldDownIceKingAnimData.ButtonMashProgress);
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
