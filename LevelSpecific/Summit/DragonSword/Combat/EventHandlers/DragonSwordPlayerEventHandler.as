UCLASS(Abstract)
class UDragonSwordPlayerEventHandler : UHazeEffectEventHandler
{
	UPROPERTY(NotEditable, BlueprintReadOnly)
	AHazePlayerCharacter Player;

	UPROPERTY(NotEditable, BlueprintReadOnly)
	UDragonSwordUserComponent SwordComp;

	UPROPERTY(NotEditable, BlueprintReadOnly)
	UDragonSwordCombatUserComponent CombatComp;

	UPROPERTY(NotEditable, BlueprintReadOnly)
	ADragonSword DragonSword;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		check(Player != nullptr);

		SwordComp = UDragonSwordUserComponent::Get(Player);
		CombatComp = UDragonSwordCombatUserComponent::Get(Player);

		DragonSword = SwordComp.Weapon;
	}

	// Called when the player starts moving towards the blade.
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StartPull() { }
	
	// Called when the player has reached the blade.
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void EndPull() { }

	UFUNCTION(BlueprintCallable, Meta = (AdvancedDisplay = "StartLocationName, StartTangentName, EndTangentName, EndLocationName"))
	void SetNiagaraBeamParameters(UNiagaraComponent NiagaraComponent,
		FVector StartLocation,
		FVector StartTangent,
		FVector EndTangent,
		FVector EndLocation,
		const FString& StartLocationName = "P0",
		const FString& StartTangentName = "P1",
		const FString& EndTangentName = "P2",
		const FString& EndLocationName = "P3") const
	{
		if (NiagaraComponent == nullptr ||
			NiagaraComponent.IsBeingDestroyed())
			return;

		NiagaraComponent.SetNiagaraVariableVec3(StartLocationName, StartLocation);
		NiagaraComponent.SetNiagaraVariableVec3(StartTangentName, StartTangent);
		NiagaraComponent.SetNiagaraVariableVec3(EndTangentName, EndTangent);
		NiagaraComponent.SetNiagaraVariableVec3(EndLocationName, EndLocation);
	}
}