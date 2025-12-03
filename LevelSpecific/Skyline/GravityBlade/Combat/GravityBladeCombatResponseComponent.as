struct FGravityBladeHitData
{
	UPROPERTY(BlueprintReadOnly)
	float Damage;
	UPROPERTY(BlueprintReadOnly)
	EDamageType DamageType;
	UPROPERTY(BlueprintReadOnly)
	float AttackMovementLength;
	UPROPERTY(BlueprintReadOnly)
	AActor Actor;
	UPROPERTY(BlueprintReadOnly)
	UPrimitiveComponent Component;
	UPROPERTY(BlueprintReadOnly)
	FVector ImpactPoint;
	UPROPERTY(BlueprintReadOnly)
	FVector ImpactNormal;
	UPROPERTY(BlueprintReadOnly)
	EGravityBladeAttackMovementType MovementType;
	UPROPERTY(BlueprintReadOnly)
	EGravityBladeAttackAnimationType AnimationType;
}

event void FGravityBladeHitSignature(UGravityBladeCombatUserComponent CombatComp, FGravityBladeHitData HitData);
event void FOnResponseComponentEnabled();
event void FOnResponseComponentDisabled();

class UGravityBladeCombatResponseComponent : UActorComponent
{
	default PrimaryComponentTick.bStartWithTickEnabled = false;

	// Called when the player hits the object with an attack.
	UPROPERTY(Category = "Response", Meta = (BPCannotCallEvent))
	FGravityBladeHitSignature OnHit;

	// Called when the response component becomes enabled after having been disabled
	UPROPERTY(Category = "Response", Meta = (BPCannotCallEvent))
	FOnResponseComponentEnabled OnResponseEnabled;

	// Called when the response component first becomes disabled
	UPROPERTY(Category = "Response", Meta = (BPCannotCallEvent))
	FOnResponseComponentDisabled OnResponseDisabled;

	// If true will disable this component from BeginPlay (the disable instigator will be this response component so when removing the disable, pass in a reference to this).
	UPROPERTY(EditAnywhere, Category = "Settings")
	bool bDisableOnBeginPlay = false;

	// If true will also disable the targetable on BeginPlay (using the same instigator)
	UPROPERTY(EditAnywhere, Category = "Settings", Meta = (EditCondition = "bDisableOnBeginPlay"))
	bool bAlsoDisableTargetableOnBeginPlay = true;

	// Prevent the gravity blade from hitting this if there is collision between the player and the target, even if the blade visually intersects with the object
	UPROPERTY(EditAnywhere, Category = "Settings")
	bool bPreventHittingThroughCollision = false;

	private TArray<FInstigator> DisableInstigators;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if(bDisableOnBeginPlay)
			AddResponseComponentDisable(this, bAlsoDisableTargetableOnBeginPlay);
	}

	bool WillDieFromHit(FGravityBladeHitData HitData) const
	{
		UBasicAIHealthComponent HealthComp = UBasicAIHealthComponent::Get(Owner);
		if(HealthComp == nullptr)
			return false;

		return HealthComp.CurrentHealth < HitData.Damage;
	}

	void Hit(UGravityBladeCombatUserComponent CombatComp, FGravityBladeHitData HitData)
	{
		OnHit.Broadcast(CombatComp, HitData);
	}

	UFUNCTION()
	void AddResponseComponentDisable(FInstigator Instigator, bool bAlsoAddDisableOnTargetable = true)
	{
		const bool bWasDisabled = IsResponseComponentDisabled();
		DisableInstigators.AddUnique(Instigator);

		auto Targetable = UGravityBladeCombatTargetComponent::Get(Owner);
		if(bAlsoAddDisableOnTargetable && Targetable != nullptr)
			Targetable.Disable(Instigator);

		if(!bWasDisabled)
			OnResponseDisabled.Broadcast();
	}

	UFUNCTION()
	void RemoveResponseComponentDisable(FInstigator Instigator, bool bAlsoRemoveDisableOnTargetable = true)
	{
		DisableInstigators.RemoveSingleSwap(Instigator);


		auto Targetable = UGravityBladeCombatTargetComponent::Get(Owner);
		if(bAlsoRemoveDisableOnTargetable && Targetable != nullptr)
			Targetable.Enable(Instigator);

		if(!IsResponseComponentDisabled())
			OnResponseEnabled.Broadcast();
	}

	UFUNCTION(BlueprintPure)
	bool IsResponseComponentDisabled()
	{
		return DisableInstigators.Num() > 0;
	}
}