event void FIslandPanelIndicatorSignature();

UCLASS(Abstract)
class AIslandPanelIndicator : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MeshComp;

	UPROPERTY(EditInstanceOnly)
	AIslandOverloadShootablePanel PanelRef;
	
	UPROPERTY(EditInstanceOnly)
	AIslandOverloadPanelListener PanelListenerRef;

	UPROPERTY(EditInstanceOnly)
	AIslandGrenadeLockListener GrenadeListenerRef;

	UPROPERTY(EditDefaultsOnly)
	UMaterialInterface OnMaterial;

	UPROPERTY(EditDefaultsOnly)
	UMaterialInterface CompletedMaterial;

	UMaterialInterface DefaultMaterial;

	UPROPERTY()
	FIslandPanelIndicatorSignature OnActivated;
	UPROPERTY()
	FIslandPanelIndicatorSignature OnDeactivated;
	UPROPERTY()
	FIslandPanelIndicatorSignature OnCompleted;

	bool bCompleted = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (PanelRef != nullptr)
		{
			PanelRef.OnOvercharged.AddUFunction(this, n"HandlePanelOvercharge");
			PanelRef.OnReset.AddUFunction(this, n"HandlePanelReset");
		}
		if (PanelListenerRef != nullptr)
		{
			PanelListenerRef.OnCompleted.AddUFunction(this, n"HandlePanelListenerOvercharge");
			PanelListenerRef.OnReset.AddUFunction(this, n"HandlePanelListenerReset");
		}
		if (GrenadeListenerRef != nullptr)
		{
			GrenadeListenerRef.OnCompleted.AddUFunction(this, n"HandleGrenadeListenerOvercharge");
			GrenadeListenerRef.OnReset.AddUFunction(this, n"HandleGrenadeListenerReset");
		}

		DefaultMaterial = MeshComp.GetMaterial(0);
	}

	UFUNCTION()
	private void HandleGrenadeListenerReset()
	{
	}

	UFUNCTION()
	private void HandleGrenadeListenerOvercharge()
	{
	}

	UFUNCTION()
	private void HandlePanelListenerReset()
	{
	}

	UFUNCTION()
	private void HandlePanelListenerOvercharge()
	{
		bCompleted = true;
		OnCompleted.Broadcast();
		MeshComp.SetMaterial(0, CompletedMaterial);
	}

	UFUNCTION()
	private void HandlePanelReset()
	{
		ToggleLight(false);
	}

	UFUNCTION()
	private void HandlePanelOvercharge()
	{
		ToggleLight(true);
	}

	UFUNCTION()
	void ToggleLight(bool bOn)
	{
		if(bCompleted)
			return;
		
		if(bOn)
		{
			MeshComp.SetMaterial(0, OnMaterial);
			OnActivated.Broadcast();
			UIslandPanelIndicatorEffectHandler::Trigger_OnLightActivated(this);
		}
		else
		{
			MeshComp.SetMaterial(0, DefaultMaterial);
			OnDeactivated.Broadcast();
			UIslandPanelIndicatorEffectHandler::Trigger_OnLightReset(this);
		}
	}
}

UCLASS(Abstract)
class UIslandPanelIndicatorEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLightActivated() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLightReset() {}
}