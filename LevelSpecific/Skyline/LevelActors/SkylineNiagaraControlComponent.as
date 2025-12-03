class USkylineNiagaraControlComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = USkylineNiagaraControlComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent InComponent)
	{
		DrawWorldString("SkylineNiagaraControlComp", InComponent.Owner.ActorLocation + FVector::UpVector * 10.0, FLinearColor::White, 2.0, bCenterText = true);
	}
}

class USkylineNiagaraControlComponent : UActorComponent
{
	UPROPERTY(EditAnywhere)
	float ActivationDelay = 0.0;

	UPROPERTY(EditAnywhere)
	float DeactivationDelay = 0.0;

	UPROPERTY(EditAnywhere)
	bool bInvertActivation = false;

	UNiagaraComponent NiagaraComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		NiagaraComp = UNiagaraComponent::Get(Owner);

		auto InterfaceComp = USkylineInterfaceComponent::Get(Owner);
		if (InterfaceComp != nullptr)
		{
			InterfaceComp.OnActivated.AddUFunction(this, (bInvertActivation ? n"HandleDeactivated" : n"HandleActivated"));
			InterfaceComp.OnDeactivated.AddUFunction(this, (bInvertActivation ? n"HandleActivated" : n"HandleDeactivated"));

			InterfaceComp.OnSnapActivated.AddUFunction(this, (bInvertActivation ? n"HandleSnapDeactivated" : n"HandleSnapActivated"));
			InterfaceComp.OnSnapDeactivated.AddUFunction(this, (bInvertActivation ? n"HandleSnapActivated" : n"HandleSnapDeactivated"));
		}
	}

	UFUNCTION()
	private void HandleActivated(AActor Caller)
	{
		if (ActivationDelay > 0.0)
			Timer::SetTimer(this, n"ActivateNiagara", ActivationDelay);
		else
			ActivateNiagara();
	}

	UFUNCTION()
	private void ActivateNiagara()
	{
		NiagaraComp.Activate();
	}

	UFUNCTION()
	private void HandleDeactivated(AActor Caller)
	{
		if (DeactivationDelay > 0.0)
			Timer::SetTimer(this, n"DeactivateNiagara", DeactivationDelay);
		else
			DeactivateNiagara();
	}

	UFUNCTION()
	private void DeactivateNiagara()
	{
		NiagaraComp.Deactivate();
	}

	UFUNCTION()
	private void HandleSnapDeactivated(AActor Caller)
	{
		DeactivateNiagara();
	}

	UFUNCTION()
	private void HandleSnapActivated(AActor Caller)
	{
		ActivateNiagara();
	}
};