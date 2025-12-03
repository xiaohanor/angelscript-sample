class ASkylineCablePanel : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UCapsuleComponent Collision;
	default Collision.bGenerateOverlapEvents = false;
	default Collision.CollisionResponseToAllChannels = ECollisionResponse::ECR_Ignore;
	default Collision.SetCollisionResponseToChannel(ECollisionChannel::WeaponTraceMio, ECollisionResponse::ECR_Block);

	UPROPERTY(DefaultComponent)
	UGravityBladeCombatTargetComponent BladeTarget;

	UPROPERTY(DefaultComponent, Attach = BladeTarget)
	UTargetableOutlineComponent OutlineComp;

	UPROPERTY(DefaultComponent)
	USkylineInterfaceComponent InterfaceComp;

	UPROPERTY(DefaultComponent)
	UGravityBladeCombatInteractionResponseComponent BladeResponseComp;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 10000.0;

	UPROPERTY(EditAnywhere)
	float EnableDelay = 1.0;
	float EnableTime = 0.0;
	bool bShouldEnable = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Disable();

		if (!BindFrontPanel())
			PrintToScreen("No front panel attached!", 5.0, FLinearColor::Red);

		BladeResponseComp.OnHit.AddUFunction(this, n"HandleBladeHit");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bShouldEnable && Time::GameTimeSeconds > EnableTime)
		{
			Enable();
			bShouldEnable = false;
		}
	}

	UFUNCTION()
	private void HandleBladeHit(UGravityBladeCombatUserComponent CombatComp, FGravityBladeHitData HitData)
	{
		// TEMP Attack tutorial bool
		auto BladeTutorialComp = UGravityBladeTutorialComponent::Get(CombatComp.Owner);
		if (BladeTutorialComp != nullptr)
			BladeTutorialComp.bAttackTutorialComplete = true;

		Activate();

		BP_OnBladeHit(HitData);

		USkylineCablePanelEventHandler::Trigger_OnBladeHit(this);
	}

	UFUNCTION()
	private void HandleFrontPanelGrabbed(UGravityWhipUserComponent UserComponent, UGravityWhipTargetComponent TargetComponent, TArray<UGravityWhipTargetComponent> OtherComponents)
	{
		USkylineCablePanelEventHandler::Trigger_OnFrontPanelRemoved(this);

		bShouldEnable = true;
		EnableTime = Time::GameTimeSeconds + EnableDelay;
	}

	UFUNCTION(BlueprintCallable)
	void Disable()
	{
		Collision.AddComponentCollisionBlocker(this);
		BladeTarget.Disable(this);
	}

	void Enable()
	{
		Collision.RemoveComponentCollisionBlocker(this);
		BladeTarget.Enable(this);

		BP_OnEnable();
	}

	void Activate()
	{
		InterfaceComp.TriggerActivate();
		Disable();

		BP_OnActivate();

		USkylineCablePanelEventHandler::Trigger_OnActivated(this);
	}

	bool BindFrontPanel()
	{
		TArray<AActor> AttachedActors;
		GetAttachedActors(AttachedActors);

		for (auto AttachedActor : AttachedActors)
		{
			auto PanelFront = Cast<ASkylineCablePanelFront>(AttachedActor);
			if (PanelFront != nullptr)
			{
				PanelFront.GravityWhipResponseComponent.OnGrabbed.AddUFunction(this, n"HandleFrontPanelGrabbed");
				
				return true;
			}
		}

		return false;
	}

	UFUNCTION(BlueprintEvent, NotBlueprintCallable)
	void BP_OnBladeHit(FGravityBladeHitData HitData) {}

	UFUNCTION(BlueprintEvent, NotBlueprintCallable)
	void BP_OnEnable() {}

	UFUNCTION(BlueprintEvent, NotBlueprintCallable)
	void BP_OnActivate() {}

	UFUNCTION(BlueprintEvent)
	void BP_StartDisabled() {}
};