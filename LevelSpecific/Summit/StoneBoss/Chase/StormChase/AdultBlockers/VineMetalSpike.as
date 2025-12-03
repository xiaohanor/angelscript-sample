class AVineMetalSpike : AGiantBreakableObject
{
	UPROPERTY(DefaultComponent)
	UAcidResponseComponent AcidResponse;

	UPROPERTY(DefaultComponent, Attach = Root)
	UAdultDragonAcidAutoAimComponent AutoAimComp;

	// UPROPERTY(DefaultComponent, Attach = Root)
	// UBoxComponent DeathBoxComp;
	// default DeathBoxComp.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Ignore);
	// default DeathBoxComp.SetCollisionResponseToChannel(ECollisionChannel::PlayerCharacter, ECollisionResponse::ECR_Overlap);

	// UPROPERTY(DefaultComponent)
	// UTargetableOutlineComponent TargetableOutlineComp;

	UPROPERTY()
	UNiagaraSystem BreakVFX;

	UPROPERTY(EditAnywhere)
	ASerpentEventActivator EventActivator;

	UPROPERTY(EditAnywhere)
	bool bStartShrunken = true;

	FVector DesiredScale;

	bool bCanBeAcidHit;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		DesiredScale = MeshRoot.RelativeScale3D;

		if (EventActivator != nullptr)
			EventActivator.OnSerpentEventTriggered.AddUFunction(this, n"ActivateSpike");

		if (bStartShrunken)
		{
			MeshRoot.SetRelativeScale3D(FVector(0.00001));
			SetActorTickEnabled(false);
			AutoAimComp.Disable(this);
			AddActorCollisionBlock(this);
			// SetActorEnableCollision(false);
		}

		AcidResponse.OnAcidHit.AddUFunction(this, n"OnAcidHit");
		// DeathBoxComp.OnComponentBeginOverlap.AddUFunction(this, n"OnComponentBeginOverlap");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		Super::Tick(DeltaSeconds);
		MeshRoot.SetRelativeScale3D(Math::VInterpTo(MeshRoot.RelativeScale3D, DesiredScale, DeltaSeconds, 1.5));

		if (MeshRoot.RelativeScale3D.Size() >= DesiredScale.Size() - (DesiredScale.Size() * 0.2) && !bCanBeAcidHit)
		{
			RemoveActorCollisionBlock(this);
			bCanBeAcidHit = true;
		}
	}

	UFUNCTION()
	void ActivateSpike()
	{
		SetActorTickEnabled(true);
		AutoAimComp.Enable(this);
	}

	UFUNCTION()
	private void OnAcidHit(FAcidHit Hit)
	{
		AutoAimComp.Disable(this);
		OnBreakGiantObject(-Hit.ImpactNormal, 26600000.0);
		UVineMetalSpikeEffectHandler::Trigger_OnMetalDestroyed(this, FVineGemOnMetalDestroyedParams(ActorLocation));
		Niagara::SpawnOneShotNiagaraSystemAtLocation(BreakVFX, BreakVFXLocation.WorldLocation);
		AddActorDisable(this);
	}

	// UFUNCTION()
	// private void OnComponentBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	//                                      UPrimitiveComponent OtherComp, int OtherBodyIndex,
	//                                      bool bFromSweep, const FHitResult&in SweepResult)
	// {
	// 	AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
	// 	if (Player == nullptr)
	// 		return;
	// 	Player.KillPlayer();
	// }
}