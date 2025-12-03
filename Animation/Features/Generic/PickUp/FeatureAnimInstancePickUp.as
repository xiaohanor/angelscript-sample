UCLASS(Abstract)
class UFeatureAnimInstancePickUp : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeaturePickUp Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeaturePickUpAnimData AnimData;

	UPROPERTY(Transient, Category = "Code variables", NotEditable)
	UPlayerPickupComponent PlayerPickupComp;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bPickingUp;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bPuttingDown;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	EPickupType PickupType;

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeaturePickUp NewFeature = GetFeatureAsClass(ULocomotionFeaturePickUp);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

		PlayerPickupComp = UPlayerPickupComponent::Get(Player);
		PickupType = PlayerPickupComp.GetCurrentPickup().PickupSettings.PickupType;
		bPickingUp = false;
		bPuttingDown = false;
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr)
			return;

		if (PlayerPickupComp == nullptr)
			return;

		bPickingUp = PlayerPickupComp.IsPickingUp();
		bPuttingDown = PlayerPickupComp.IsPuttingDown();
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
