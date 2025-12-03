UCLASS(Abstract)
class UFeatureAnimInstancePumpCart : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeaturePumpCart Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeaturePumpCartAnimData AnimData;

	AVillagePumpCart PumpCart;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bFailing = false;
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bPumping = false;
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bPumpOnLeftSide = true;
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bFinished = false;

	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		if (HazeOwningActor == nullptr)
			return;

		PumpCart = TListedActors<AVillagePumpCart>().Single;
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeaturePumpCart NewFeature = GetFeatureAsClass(ULocomotionFeaturePumpCart);
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

		bFailing = PumpCart.bFailActive;
		bPumping = PumpCart.bPumping;
		bPumpOnLeftSide = PumpCart.bPumpOnLeftSide;
		bFinished = PumpCart.bReachedTop;
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
