UCLASS(Abstract)
class UGravityBladePlayerEventHandler : UHazeEffectEventHandler
{
	UPROPERTY(NotEditable, BlueprintReadOnly)
	AHazePlayerCharacter Player;

	UPROPERTY(NotEditable, BlueprintReadOnly)
	UGravityBladeUserComponent BladeComp;

	UPROPERTY(NotEditable, BlueprintReadOnly)
	UGravityBladeCombatUserComponent CombatComp;

	UPROPERTY(NotEditable, BlueprintReadOnly)
	UGravityBladeGrappleUserComponent GrappleComp;

	UPROPERTY(NotEditable, BlueprintReadOnly)
	AGravityBladeActor GravityBlade;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		check(Player != nullptr);

		BladeComp = UGravityBladeUserComponent::Get(Player);
		CombatComp = UGravityBladeCombatUserComponent::Get(Player);
		GrappleComp = UGravityBladeGrappleUserComponent::Get(Player);

		GravityBlade = BladeComp.Blade;
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

	UFUNCTION(BlueprintPure)
	float GetPullDelay() const
	{
		return GravityBladeGrapple::PullDelay;
	}
}