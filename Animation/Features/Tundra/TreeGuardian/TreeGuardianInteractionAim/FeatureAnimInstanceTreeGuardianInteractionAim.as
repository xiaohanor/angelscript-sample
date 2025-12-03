UCLASS(Abstract)
class UFeatureAnimInstanceTreeGuardianInteractionAim : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureTreeGuardianInteractionAim Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureTreeGuardianInteractionAimAnimData AnimData;
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
    FVector2D AimValues;

	UTundraPlayerTreeGuardianComponent TreeGuardianComp;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FTundraPlayerTreeGuardianRangedInteractAnimData RangedInteractAnimData;

	UPROPERTY(Transient, NotEditable)
	bool bFailAim;

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
		ULocomotionFeatureTreeGuardianInteractionAim NewFeature = GetFeatureAsClass(ULocomotionFeatureTreeGuardianInteractionAim);
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

		AimValues = Cast<AHazePlayerCharacter>(HazeOwningActor.AttachParentActor).CalculatePlayerAimAngles();
		PrintToScreen(f"{AimValues=}");
		RangedInteractAnimData = TreeGuardianComp.RangedInteractAnimData;
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
