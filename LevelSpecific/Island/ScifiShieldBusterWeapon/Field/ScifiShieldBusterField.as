event void FScifiShieldBusterEnableSignature();
event void FScifiShieldBusterDisableSignature();
event void FScifiShieldBusterBreakResponseSignature();
event void FScifiShieldBusterRecoverResponseSignature();

/** Add 'UScifiShieldBusterFieldTargetableComponent' and place them where you want to be able to disable fields */
class UScifiShieldBusterField : USphereComponent
{
	TArray<AActor> Overlappers;
	UScifiShieldBusterImpactResponseComponent ImpactResponse;

	UPROPERTY(Category = "Enable")
	FScifiShieldBusterEnableSignature OnEnable;

	UPROPERTY(Category = "Enable")
	FScifiShieldBusterDisableSignature OnDisable;

	UPROPERTY(Category = "Break")
	FScifiShieldBusterBreakResponseSignature OnBreak;

	UPROPERTY(Category = "Break")
	FScifiShieldBusterRecoverResponseSignature OnRecover;

	UPROPERTY(EditAnywhere)
	UScifiShieldBusterFieldSettings CustomSettings;

	UPROPERTY(EditConst)
	TArray<UScifiShieldBusterFieldTargetableComponent> Targets;

	UPROPERTY(EditConst)
	TArray<FInstigator> FunctionalityBlockers;

	UPROPERTY(EditConst)
	TArray<FInstigator> BreakFunctionalityBlockers;

	UPROPERTY()
	UDisableComponent Disable;

	UPROPERTY(BlueprintReadOnly)
	EScifiShieldBusterFieldState State = EScifiShieldBusterFieldState::Enabled;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		TArray<UActorComponent> FoundComponents;
		GetOwner().GetAllComponents(UScifiShieldBusterFieldTargetableComponent, FoundComponents);

		Targets.Reset();

		for(auto ActorComp : FoundComponents)
		{
			Targets.Add(Cast<UScifiShieldBusterFieldTargetableComponent>(ActorComp));
		}
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ImpactResponse = UScifiShieldBusterImpactResponseComponent::Get(GetOwner());
		Disable = UDisableComponent::Get(Owner);
		
		#if EDITOR
		if(!ensure(Targets.Num() > 0, "" + GetName() + " has no 'ScifiShieldBusterFieldTargetableComponent'"))
		{
			auto HazeActor = Cast<AHazeActor>(GetOwner());
			FVector Extends = HazeActor.GetActorBoxExtents(true);
			float DebugRadius = Shape::GetEncapsulatingSphereRadius(FCollisionShape::MakeBox(Extends));
			Debug::DrawDebugSphere(HazeActor.GetActorLocation(), DebugRadius, LineColor = FLinearColor::Red, Duration = 10);
		}
		#endif
	}

	UScifiShieldBusterFieldSettings GetSettings() property
	{
		if(CustomSettings == nullptr)
			return Cast<UScifiShieldBusterFieldSettings>(UScifiShieldBusterFieldSettings.DefaultObject);
		else
			return CustomSettings;
	}

	// Stops this shield from being busted
	UFUNCTION()
	void AddBreakBlocker(FInstigator Instigator)
	{
		BreakFunctionalityBlockers.AddUnique(Instigator);
	}

	// Enables this shield to be busted, when all blockers has been removed
	UFUNCTION()
	void RemoveBreakBlocker(FInstigator Instigator)
	{
		BreakFunctionalityBlockers.RemoveSingleSwap(Instigator);
	}

	bool CanBreak() const
	{
		return BreakFunctionalityBlockers.Num() == 0;
	}

	bool IsEnabled() const
	{
		return FunctionalityBlockers.Num() == 0;
	}

	bool IsBroken() const
	{
		return BreakFunctionalityBlockers.Num() > 0;
	}

	UFUNCTION()
	void DisableField(FInstigator Instigator)
	{
		SetCollisionProfileName(n"TriggerOnlyPlayer");
		FunctionalityBlockers.AddUnique(Instigator);
		OnDisable.Broadcast();
		SetVisibility(false, true);
	}

	UFUNCTION()
	void EnableField(FInstigator Instigator)
	{
		FunctionalityBlockers.RemoveSingleSwap(Instigator);
		if(FunctionalityBlockers.Num() > 0) return;
		State = EScifiShieldBusterFieldState::Recovering;
		OnRecover.Broadcast();	
		SetVisibility(true, true);
	}

	void BreakField(FInstigator Instigator)
	{
		SetCollisionProfileName(n"TriggerOnlyPlayer");
		State = EScifiShieldBusterFieldState::Disabled;
		AddBreakBlocker(Instigator);
		OnBreak.Broadcast();
		SetVisibility(false, true);
	}

	void RecoverField(FInstigator Instigator)
	{		
		RemoveBreakBlocker(Instigator);
		if(BreakFunctionalityBlockers.Num() > 0 || !IsEnabled()) return;
		State = EScifiShieldBusterFieldState::Recovering;
		OnRecover.Broadcast();		
		SetVisibility(true, true);
	}

	void CompleteFieldRecovery()
	{
		SetCollisionProfileName(n"EnemyCharacter");
		State = EScifiShieldBusterFieldState::Enabled;
	}

	void Reset()
	{
		FunctionalityBlockers.Empty();
		BreakFunctionalityBlockers.Empty();
		State = EScifiShieldBusterFieldState::Enabled;
	}
}

/** Add to 'ScifiShieldBusterField' and place them where you want to be able to disable the shield */
class UScifiShieldBusterFieldTargetableComponent : UScifiShieldBusterTargetableComponent
{

}

/** Settings controlling the shield */
class UScifiShieldBusterFieldSettings : UDataAsset
{
	// Recovery impulse velocity
	UPROPERTY(Category = "Recovery", meta = (ClampMin = "0"))
	float RecoveryVelocity = 3000;

	// Lifetime of field breaking
	UPROPERTY(Category = "Lifetime", meta = (ClampMin = "0"))
	float Lifetime = 3;
}

/** Internal class for cutting wholes in the walls */
class UScifiShieldBusterInternalFieldBreaker
{
	float LastImpactTime = 0;
	UScifiShieldBusterField CurrentBreakingField;
	UScifiShieldBusterFieldTargetableComponent LinkedTargetComponent;
}

enum EScifiShieldBusterFieldState
{
	Disabled,
	Recovering,
	Enabled
}