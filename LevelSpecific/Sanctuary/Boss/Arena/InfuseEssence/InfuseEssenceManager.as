event void FEssencePickedUp();
event void FEssenceRespawned();
class AInfuseEssenceManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UInteractionComponent InteractComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent BillboardComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	USphereComponent TriggerComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent EssenceRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent VFXComp;

	UPROPERTY()
	float EssenceRadius = 300.0;

	UPROPERTY(EditInstanceOnly)
	bool bLightEssence = true;

	UPROPERTY(EditInstanceOnly)
	bool bAttachEssence = false;

	UPROPERTY()
	TSubclassOf<AInfuseEssence> LightEssenceClass;

	UPROPERTY()
	TSubclassOf<AInfuseEssence> DarkEssenceClass;

	UPROPERTY()
	UNiagaraSystem LightEssenceVFX;

	UPROPERTY()
	UNiagaraSystem DarkEssenceVFX;

	UPROPERTY()
	UNiagaraSystem AllEssenceConsumedVFXSystem;

	UPROPERTY(EditInstanceOnly)
	FDarkPortalInvestigationDestination DarkPortalInvestigationDestination;

	UPROPERTY(EditInstanceOnly)
	FLightBirdInvestigationDestination LightBirdInvestigationDestination;

	UPROPERTY()
	FEssencePickedUp OnEssencePickedUp;
	UPROPERTY()
	FEssenceRespawned OnEssenceRespawned;

	UPROPERTY(EditAnywhere, Category = Settings)
	int EssenceAmount = 7;
	int ConsumedEssence = 0;

	TArray<AInfuseEssence> EssenceActors;
	AHazePlayerCharacter Player;

	float DarkPortalOGScale = -1.0;
	float LightBirbOGScale = -1.0;
	bool bBoundEvent = false;

	bool bInteracted = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		LightBirdInvestigationDestination.OverrideSpeed = 2000.0;
		DarkPortalInvestigationDestination.OverrideSpeed = 2000.0;

		DarkPortalInvestigationDestination.Type = EDarkPortalInvestigationType::Flyby;
		LightBirdInvestigationDestination.Type = ELightBirdInvestigationType::Flyby;

		DarkPortalInvestigationDestination.TargetComp = EssenceRoot;
		LightBirdInvestigationDestination.TargetComp = EssenceRoot;

		EssenceRadius = TriggerComp.BoundsRadius;

		for (int i = 0; i < EssenceAmount; i++)
		{
			auto Essence = SpawnActor(bLightEssence ? LightEssenceClass : DarkEssenceClass, ActorLocation, bDeferredSpawn = true);
			Essence.Manager = this;
			Essence.AttachToComponent(EssenceRoot, NAME_None, EAttachmentRule::KeepWorld);
			EssenceActors.Add(Essence);
			FinishSpawningActor(Essence);
			Essence.SetActorLocation(EssenceRoot.WorldLocation + Math::GetRandomPointInSphere() * FVector(1.0, 1.0, 1.5)* 400.0);
		}

		if (!bAttachEssence)
			EssenceRoot.DetachFromParent(true);

		//TriggerComp.OnComponentBeginOverlap.AddUFunction(this, n"HandleOverlap"); // if we want overlap again we need to network it
		InteractComp.OnInteractionStarted.AddUFunction(this, n"HandleInteractionStarted");

		//Setup type
		VFXComp.SetAsset(bLightEssence ? LightEssenceVFX : DarkEssenceVFX);
		InteractComp.SetUsableByPlayers(bLightEssence ? EHazeSelectPlayer::Mio : EHazeSelectPlayer::Zoe);
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		for (auto Essence : EssenceActors)
			Essence.SetAutoDestroyWhenFinished(true);
	}

	UFUNCTION()
	private void HandleInteractionStarted(UInteractionComponent InteractionComponent,
	                                      AHazePlayerCharacter InteractingPlayer)
	{
		Player = InteractingPlayer;
		UInfuseEssencePlayerComponent EssenceComp = UInfuseEssencePlayerComponent::Get(InteractingPlayer);
		if (EssenceComp.HasEnoughOrbs())
			return;

		for (auto Essence : EssenceActors)
		{
			if (InteractingPlayer == Game::Zoe)
			{
				Essence.TargetCompanion(DarkPortalCompanion::GetDarkPortalCompanion());
				DarkPortalCompanion::DarkPortalInvestigate(DarkPortalInvestigationDestination,this);
			}
			else
			{
					Essence.TargetCompanion(LightBirdCompanion::GetLightBirdCompanion());
					LightBirdCompanion::LightBirdInvestigate(LightBirdInvestigationDestination,this);
			}
		}
		InteractComp.Disable(this);
		VFXComp.Deactivate();
		OnEssencePickedUp.Broadcast();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		LateSetupScales();

		DisableForPlayerIfEnoughOrbs();
		EssenceRoot.AddRelativeRotation(FRotator(0.0, 50.0 * DeltaSeconds, 0.0));
	}

	private void LateSetupScales()
	{
		if (DarkPortalOGScale < 0.0)
		{
			AAISanctuaryDarkPortalCompanion DarkPortal = DarkPortalCompanion::GetDarkPortalCompanion();
			DarkPortalOGScale = DarkPortal.GetActorScale3D().Size();
		}
		if (LightBirbOGScale < 0.0)
		{
			AAISanctuaryLightBirdCompanion LightBird = LightBirdCompanion::GetLightBirdCompanion();
			LightBirbOGScale = LightBird.GetActorScale3D().Size();
		}
	}

	private void DisableForPlayerIfEnoughOrbs()
	{
		for (auto PlayerCharacter : Game::Players)
		{
			UInfuseEssencePlayerComponent EssenceComp = UInfuseEssencePlayerComponent::Get(PlayerCharacter);
			if (EssenceComp == nullptr)
				continue;

			if (EssenceComp.HasEnoughOrbs())
				InteractComp.DisableForPlayer(PlayerCharacter, EssenceComp);
			else
				InteractComp.EnableForPlayer(PlayerCharacter, EssenceComp);
		}
	}

	UFUNCTION()
	private void HandleOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                           UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep,
	                           const FHitResult&in SweepResult)
	{
		if (Player != nullptr)
			return;

		Player = Cast<AHazePlayerCharacter>(OtherActor);

		if (Player == nullptr)
			return;

		UInfuseEssencePlayerComponent EssenceComp = UInfuseEssencePlayerComponent::Get(Player);
		if (EssenceComp.HasEnoughOrbs())
			return;

		for (auto Essence : EssenceActors)
		{
			if (Player == Game::Zoe){
				Essence.TargetCompanion(DarkPortalCompanion::GetDarkPortalCompanion());
				DarkPortalCompanion::DarkPortalInvestigate(DarkPortalInvestigationDestination,this);
			}else{
					Essence.TargetCompanion(LightBirdCompanion::GetLightBirdCompanion());
					LightBirdCompanion::LightBirdInvestigate(LightBirdInvestigationDestination,this);
			}
				
		}

		VFXComp.Deactivate();
	}

	UFUNCTION()
	void DelayingRespawnEssence()
	{
		Timer::SetTimer(this, n"RespawnEssence", 5.0);
	}

	UFUNCTION()
	void RespawnEssence()
	{
		for (auto Essence : EssenceActors)
		{
			ConsumedEssence = 0;
			Essence.RemoveActorDisable(this);
			Essence.SetActorLocation(ActorLocation + Math::GetRandomPointInSphere() * EssenceRadius);
			
			Player = nullptr;
		}

		InteractComp.Enable(this);
		VFXComp.Activate();
		OnEssenceRespawned.Broadcast();
	}

	UFUNCTION()
	void EssenceConsumed(AHazeActor Companion)
	{
		ConsumedEssence++;

		if (ConsumedEssence == EssenceAmount)
		{
			// PrintToScreen("AllEssenceConsumed", 3.0);
			Niagara::SpawnOneShotNiagaraSystemAttached(AllEssenceConsumedVFXSystem, Companion.RootComponent);
			UInfuseEssencePlayerComponent EssenceComp = UInfuseEssencePlayerComponent::Get(Player);
			EssenceComp.AddOrb();
			if (!bBoundEvent)
			{
				bBoundEvent = true;
				EssenceComp.OnOrbsShouldReset.AddUFunction(this, n"DelayingRespawnEssence");
			}

			// Scale companions when they're ready!
			// 2024/06/11, new design again: dont scale companions!

			// if (EssenceComp.HasEnoughOrbs())
			// {
			// 	if (Player == Game::Zoe)
			// 	{
			// 		AAISanctuaryDarkPortalCompanion DarkPortal = DarkPortalCompanion::GetDarkPortalCompanion();
			// 		auto AviationComp = USanctuaryCompanionAviationPlayerComponent::Get(Player);
			// 		const float NewCompanionScale = Math::Lerp(DarkPortalOGScale, CompanionAviation::MegaCompanionScale* 0.8, EssenceComp.GetProgress());
			// 		if (ensure(NewCompanionScale > KINDA_SMALL_NUMBER, "EssenceConsumed: Negative scale?"))
			// 			DarkPortal.SetActorScale3D(FVector::OneVector * NewCompanionScale);
			// 	}
			// 	else
			// 	{
			// 		AAISanctuaryLightBirdCompanion LightBird = LightBirdCompanion::GetLightBirdCompanion();
			// 		auto AviationComp = USanctuaryCompanionAviationPlayerComponent::Get(Player);
			// 		const float NewCompanionScale = Math::Lerp(LightBirbOGScale, CompanionAviation::MegaCompanionScale * 0.8, EssenceComp.GetProgress());
			// 		if (ensure(NewCompanionScale > KINDA_SMALL_NUMBER, "EssenceConsumed: Negative scale?"))
			// 			LightBird.SetActorScale3D(FVector::OneVector * NewCompanionScale);
			// 	}
			// }
		}
	}
};