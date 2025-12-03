UCLASS(Abstract)
class USkylineGravityBladeTriggerEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBladeTriggerHit()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBladeTriggerEnable()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBladeTriggerDisable()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBladeTriggerActivate()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBladeTriggerDeactivate()
	{
	}		
};

class ASkylineGravityBladeTrigger : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent BladeCollision;
	default BladeCollision.bGenerateOverlapEvents = false;
	default BladeCollision.CollisionResponseToAllChannels = ECollisionResponse::ECR_Ignore;
	default BladeCollision.SetCollisionResponseToChannel(ECollisionChannel::WeaponTraceMio, ECollisionResponse::ECR_Block);

	UPROPERTY(DefaultComponent)
	UGravityBladeCombatTargetComponent TargetComp;
	default TargetComp.AimRayType = EGravityBladeCombatAimRayType::Camera;

	UPROPERTY(DefaultComponent, Attach = TargetComp)
	UTargetableOutlineComponent OutlineComp;

	UPROPERTY(DefaultComponent)
	UGravityBladeCombatInteractionResponseComponent GravityBladeCombatInteractionResponseComp;
	default GravityBladeCombatInteractionResponseComp.InteractionType = EGravityBladeCombatInteractionType::HorizontalRight;

	UPROPERTY(DefaultComponent)
	USkylineInterfaceComponent InterfaceComp;

	UPROPERTY(EditAnywhere)
	bool bToggle = false;

	bool bIsReady = true;

	UPROPERTY()
	bool bIsActivated = false;

	TArray<FInstigator> DisableInstigators;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		GravityBladeCombatInteractionResponseComp.OnHit.AddUFunction(this, n"HandleHit");

		InterfaceComp.OnActivated.AddUFunction(this, n"HandleActivated");
		InterfaceComp.OnDeactivated.AddUFunction(this, n"HandleDeactivated");

		Enable();
	}

	UFUNCTION()
	private void HandleHit(UGravityBladeCombatUserComponent CombatComp, FGravityBladeHitData HitData)
	{
		if (bIsReady)
		{
			if (bToggle)
			{
				if (!bIsActivated)
					Activate();
				else
					Deactivate();
			}
			else
				Activate();
		}

		BP_OnHit(HitData);
	}

	UFUNCTION()
	private void HandleActivated(AActor Caller)
	{
		RemoveDisabler(Caller);
	}

	UFUNCTION()
	private void HandleDeactivated(AActor Caller)
	{
		AddDisabler(Caller);
	}

	void Enable()
	{
//		PrintToScreen("Trigger Enabled", 2.0, FLinearColor::Green);

		BladeCollision.RemoveComponentCollisionBlocker(this);
		TargetComp.Enable(this);

		BP_OnEnable();
		USkylineGravityBladeTriggerEventHandler::Trigger_OnBladeTriggerEnable(this);
	}

	void Disable()
	{
//		PrintToScreen("Trigger Disabled", 2.0, FLinearColor::Green);

		BladeCollision.AddComponentCollisionBlocker(this);
		TargetComp.Disable(this);

		BP_OnDisable();
		USkylineGravityBladeTriggerEventHandler::Trigger_OnBladeTriggerDisable(this);
	}

	void Activate()
	{
//		PrintToScreen("Activate", 2.0, FLinearColor::Green);

		bIsActivated = true;

		InterfaceComp.TriggerActivate();

		BP_OnActivate();
		USkylineGravityBladeTriggerEventHandler::Trigger_OnBladeTriggerActivate(this);		
	}

	void Deactivate()
	{
//		PrintToScreen("Deactivate", 2.0, FLinearColor::Green);

		bIsActivated = false;

		InterfaceComp.TriggerDeactivate();

		BP_OnDeactivate();
		USkylineGravityBladeTriggerEventHandler::Trigger_OnBladeTriggerDeactivate(this);
	}
	
	/* BlueprintEvents */
	UFUNCTION(BlueprintEvent, NotBlueprintCallable)
	void BP_OnHit(FGravityBladeHitData HitData) {}

	UFUNCTION(BlueprintEvent, NotBlueprintCallable)
	void BP_OnEnable() {}

	UFUNCTION(BlueprintEvent, NotBlueprintCallable)
	void BP_OnDisable() {}

	UFUNCTION(BlueprintEvent, NotBlueprintCallable)
	void BP_OnActivate() {}

	UFUNCTION(BlueprintEvent, NotBlueprintCallable)
	void BP_OnDeactivate() {}

	/* DisableInstigator */
	UFUNCTION()
	void AddDisabler(FInstigator DisableInstigator)
	{
		if (DisableInstigators.Num() == 0)
			Disable();

		DisableInstigators.Add(DisableInstigator);
	}

	UFUNCTION()
	void RemoveDisabler(FInstigator DisableInstigator)
	{
		bool bWasEnabled = DisableInstigators.Num() > 0;

		DisableInstigators.Remove(DisableInstigator);

		if (bWasEnabled && DisableInstigators.Num() == 0)
			Enable();
	}

	UFUNCTION()
	void RemoveAllDisablers(FInstigator DisableInstigator)
	{
		bool bWasEnabled = DisableInstigators.Num() > 0;

		DisableInstigators.Empty();

		if (bWasEnabled)
			Enable();		
	}
};