class UPigRainbowFartEffectEventHandler : UHazeEffectEventHandler
{
	UPROPERTY(Category = "VFX")
	UNiagaraSystem FartVFX;

	UPROPERTY(Category = "VFX")
	UNiagaraSystem InterruptedVFX;

	UPROPERTY(NotEditable, BlueprintReadOnly)
	UPlayerPigComponent PlayerPigComponent;

	UPROPERTY(NotEditable, BlueprintHidden)
	UNiagaraComponent FartNiagaraComponent;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PlayerPigComponent = UPlayerPigComponent::Get(Owner);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFartingStarted()
	{
		FartNiagaraComponent = Niagara::SpawnLoopingNiagaraSystemAttached(FartVFX, PlayerPigComponent.PlayerOwner.Mesh);
		FartNiagaraComponent.SetRelativeLocation(FVector(-40.0, 0.0, 50.0));
		FartNiagaraComponent.SetRelativeRotation(FRotator(90.0, 0.0, 0.0));
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFartingStopped()
	{
		FartNiagaraComponent.DetachFromParent(true);
		FartNiagaraComponent.Deactivate();
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFartInterrupted()
	{
		UNiagaraComponent InterruptedNiagaraComponent = Niagara::SpawnOneShotNiagaraSystemAtLocation(InterruptedVFX, PlayerPigComponent.PlayerOwner.Mesh.WorldLocation + FVector::UpVector * 40.0, (-PlayerPigComponent.PlayerOwner.Mesh.ForwardVector).Rotation());
		InterruptedNiagaraComponent.SetFloatParameter(n"SpriteSizeMin", 30.0);
		InterruptedNiagaraComponent.SetFloatParameter(n"SpriteSizeMax", 70.0);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSlideStarted(){}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSlideStopped(){}
}