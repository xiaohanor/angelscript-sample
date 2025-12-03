event void FSkylineTorHoldHammerComponentOnDetachedSignature();
event void FSkylineTorHoldHammerComponentOnAttachedSignature();

class USkylineTorHoldHammerComponent : USceneComponent
{
	UPROPERTY()
	TSubclassOf<ASkylineTorHammer> HammerClass;
	UPROPERTY(BlueprintReadOnly)
	ASkylineTorHammer Hammer;

	private bool bInternalDetached;
	ASkylineTor Tor;

	FSkylineTorHoldHammerComponentOnDetachedSignature OnDetached;
	FSkylineTorHoldHammerComponentOnAttachedSignature OnAttached;

	bool GetbDetached() property
	{
		return bInternalDetached;
	}

	bool GetbAttached() property
	{
		return !bInternalDetached;
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Tor = Cast<ASkylineTor>(Owner);
		Hammer = SpawnActor(HammerClass, bDeferredSpawn = true, Level = Owner.Level);
		Hammer.MakeNetworked(this, n"TorHammer");
		Hammer.SetupHammerHolder(Tor);
		FinishSpawningActor(Hammer);
		Attach();
	}

	void Attach()
	{
		bInternalDetached = false;
		Hammer.HammerComp.SetMode(ESkylineTorHammerMode::Idle);	
		Hammer.AttachToComponent(this);
		Hammer.ActorRotation = WorldRotation;
		Hammer.HealthBarComp.SetHealthBarEnabled(false);
		OnAttached.Broadcast();
	}

	void Detach(ESkylineTorHammerMode Mode)
	{
		bInternalDetached = true;
		Hammer.DetachFromActor();
		Hammer.HammerComp.SetMode(Mode);
		OnDetached.Broadcast();
	}
}