UCLASS(Abstract)
class UFeatureAnimInstancePlayerGrappleFish : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeaturePlayerGrappleFish Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeaturePlayerGrappleFishAnimData AnimData;

	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	UDesertGrappleFishPlayerComponent PlayerComp;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bShouldJump;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector2D TurnBS;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bTriggerEndJump;

	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		if (HazeOwningActor == nullptr)
			return;

	}

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeaturePlayerGrappleFish NewFeature = GetFeatureAsClass(ULocomotionFeaturePlayerGrappleFish);
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

		PlayerComp = UDesertGrappleFishPlayerComponent::Get(Player);
		bTriggerEndJump = PlayerComp.bTriggerEndJump;
		if (bTriggerEndJump)
			bShouldJump = false;
		else
			bShouldJump = PlayerComp.State == EDesertGrappleFishPlayerState::Launched;

		TurnBS = PlayerComp.TurnBS;
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

	UFUNCTION(BlueprintOverride)
    float GetBlendTime() const
    {
        return 0.05;
    }
}
