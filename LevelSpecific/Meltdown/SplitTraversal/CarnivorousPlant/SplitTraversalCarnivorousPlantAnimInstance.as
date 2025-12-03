class USplitTraversalCarnivorousPlantAnimInstance : UHazeAnimInstanceBase
{
	ASplitTraversalCarnivorousPlant2 CarnivorousPlant;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float PlayerDistanceFromCenter = 0.0;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bActive = false;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bAttacking = false;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bAttackingTarget = false;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bRetracting = false;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bLostTarget = false;

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		CarnivorousPlant = Cast<ASplitTraversalCarnivorousPlant2>(GetOwningComponent().Owner);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTimeX)
	{
		if (CarnivorousPlant == nullptr)
			return;

		PlayerDistanceFromCenter = CarnivorousPlant.PlayerDistanceFromCenter;
		bActive = CarnivorousPlant.bActive;
		bAttacking = CarnivorousPlant.bAttacking;
		bAttackingTarget = CarnivorousPlant.bAttackingTarget;
		bRetracting = CarnivorousPlant.bRetracting;
		bLostTarget = CarnivorousPlant.bLostTarget;
	}

	
	// Animations

    UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlayBlendSpaceData Idle;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlayBlendSpaceData Attack;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlaySequenceData AttackTarget;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlayBlendSpaceData Retract;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData Inactive;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData Activate;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData Deactivate;

}