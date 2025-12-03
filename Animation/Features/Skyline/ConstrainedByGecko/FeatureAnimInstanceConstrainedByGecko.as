UCLASS(Abstract)
class UFeatureAnimInstanceConstrainedByGecko : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureConstrainedByGecko Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureConstrainedByGeckoAnimData AnimData;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bRecover = false;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsInAir;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bWantsToMove;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bHasRecovered = false;

	UPROPERTY(EditDefaultsOnly)
	UHazePhysicalAnimationProfile PhysProfile;

	USkylineGeckoConstrainedPlayerComponent ConstrainedByGeckoComp;
	UPlayerMovementComponent MoveComponent;

	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()												
	{
		ConstrainedByGeckoComp = USkylineGeckoConstrainedPlayerComponent::GetOrCreate(HazeOwningActor);
		MoveComponent = UPlayerMovementComponent::GetOrCreate(HazeOwningActor);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		Feature = GetFeatureAsClass(ULocomotionFeatureConstrainedByGecko);
		if (Feature == nullptr)
			return;
		AnimData = Feature.AnimData;
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (HazeOwningActor == nullptr)
			return;

		bRecover = (ConstrainedByGeckoComp.ConstrainingGeckos.Num() == 0);	
		bIsInAir = MoveComponent.IsInAir();
		bWantsToMove = !MoveComponent.SyncedMovementInputForAnimationOnly.IsNearlyZero();
		bHasRecovered = ConstrainedByGeckoComp.bHasRecovered;
	}

	UFUNCTION(BlueprintOverride)
	bool CanTransitionFrom() const
	{
		// return false until player input is unblocked and player gives input
		if (bHasRecovered)
			return true;

		return false;
	}
}
