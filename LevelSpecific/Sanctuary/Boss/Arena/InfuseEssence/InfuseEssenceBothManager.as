class AInfuseEssenceBothManager : AHazeActor
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
	float EssenceRadius = 70.0;


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

	UPROPERTY(EditAnywhere, Category = Settings)
	int EssenceAmount = 7;
	int ConsumedLightEssence = 0;
	int ConsumedDarkEssence = 0;

	TArray<AInfuseEssence> LightEssenceActors;
	TArray<AInfuseEssence> DarkEssenceActors;

	float DarkPortalOGScale = -1.0;
	float LightBirbOGScale = -1.0;
	bool bBoundEvent = false;

	bool bFullDisabled = false;
	bool bInteracted = false;
	
	FEssencePickedUp OnPlayerInfused;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		LightBirdInvestigationDestination.OverrideSpeed = 2000.0;
		DarkPortalInvestigationDestination.OverrideSpeed = 2000.0;

		DarkPortalInvestigationDestination.Type = EDarkPortalInvestigationType::Flyby;
		LightBirdInvestigationDestination.Type = ELightBirdInvestigationType::Flyby;

		DarkPortalInvestigationDestination.TargetComp = EssenceRoot;
		LightBirdInvestigationDestination.TargetComp = EssenceRoot;
		

		for (int i = 0; i < EssenceAmount; i++)
		{
			auto Essence = SpawnActor(LightEssenceClass, ActorLocation, bDeferredSpawn = true);
			Essence.BothManager = this;
			Essence.AttachToComponent(EssenceRoot, NAME_None, EAttachmentRule::KeepWorld);
			LightEssenceActors.Add(Essence);
			FinishSpawningActor(Essence);
			Essence.SetActorLocation(EssenceRoot.WorldLocation + Math::GetRandomPointInSphere() * FVector(1.0, 1.0, 1.5)* EssenceRadius);
		}

		for (int i = 0; i < EssenceAmount; i++)
		{
			auto Essence = SpawnActor(DarkEssenceClass, ActorLocation, bDeferredSpawn = true);
			Essence.BothManager = this;
			Essence.AttachToComponent(EssenceRoot, NAME_None, EAttachmentRule::KeepWorld);
			DarkEssenceActors.Add(Essence);
			FinishSpawningActor(Essence);
			Essence.SetActorLocation(EssenceRoot.WorldLocation + Math::GetRandomPointInSphere() * FVector(1.0, 1.0, 1.5)* EssenceRadius);
		}

		if (!bAttachEssence)
			EssenceRoot.DetachFromParent(true);

		//TriggerComp.OnComponentBeginOverlap.AddUFunction(this, n"HandleOverlap"); // if we want overlap again we need to network it
		InteractComp.OnInteractionStarted.AddUFunction(this, n"HandleInteractionStarted");

	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		for (auto Essence : LightEssenceActors)
			Essence.SetAutoDestroyWhenFinished(true);
		for (auto Essence : DarkEssenceActors)
			Essence.SetAutoDestroyWhenFinished(true);
	}

	void UpdateHiddenStatusOnEssences()
	{

	}

	UFUNCTION()
	void HandleInteractionStarted(UInteractionComponent InteractionComponent, AHazePlayerCharacter InteractingPlayer)
	{
		OnPlayerInfused.Broadcast();

		for(auto Player : Game::GetPlayers())
		{
			UInfuseEssencePlayerComponent EssenceComp = UInfuseEssencePlayerComponent::Get(Player);
			if (EssenceComp.HasEnoughOrbs())
				return;
		}

		for (auto Essence : LightEssenceActors)
		{
			Essence.TargetCompanion(LightBirdCompanion::GetLightBirdCompanion());
			LightBirdCompanion::LightBirdInvestigate(LightBirdInvestigationDestination,this);		
		}

		for (auto Essence : DarkEssenceActors)
		{
			Essence.TargetCompanion(DarkPortalCompanion::GetDarkPortalCompanion());
			DarkPortalCompanion::DarkPortalInvestigate(DarkPortalInvestigationDestination,this);		
		}

		InteractComp.Disable(this);
		VFXComp.Deactivate();
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

			bool bShouldBeDisabled = EssenceComp.HasEnoughOrbs();
			if (bShouldBeDisabled && !bFullDisabled)
			{
				bFullDisabled = true;
				InteractComp.DisableForPlayer(PlayerCharacter, this);
			}
			else if (!bShouldBeDisabled && bFullDisabled)
			{
				bFullDisabled = false;
				InteractComp.EnableForPlayer(PlayerCharacter, this);
			}
		}
	}

	UFUNCTION()
	void DelayingRespawnEssence()
	{
		Timer::SetTimer(this, n"RespawnEssence", 5.0);
	}

	UFUNCTION()
	void RespawnEssence()
	{
		ConsumedLightEssence = 0;
		ConsumedDarkEssence = 0;

		for (auto Essence : LightEssenceActors)
		{	
			Essence.RemoveActorDisable(this);
			Essence.SetActorLocation(EssenceRoot.WorldLocation + Math::GetRandomPointInSphere() * FVector(1.0, 1.0, 1.5)* EssenceRadius);
		}

		for (auto Essence : DarkEssenceActors)
		{	
			Essence.RemoveActorDisable(this);
			Essence.SetActorLocation(EssenceRoot.WorldLocation + Math::GetRandomPointInSphere() * FVector(1.0, 1.0, 1.5)* EssenceRadius);
		}

		InteractComp.Enable(this);
		VFXComp.Activate();
	}

	UFUNCTION()
	void EssenceConsumed(AHazeActor Companion)
	{
		UInfuseEssencePlayerComponent EssenceComp;

		if(Companion == DarkPortalCompanion::GetDarkPortalCompanion())
		{
			EssenceComp = UInfuseEssencePlayerComponent::Get(Game::Zoe);
			ConsumedDarkEssence++;
			CheckAddDarkPortalEssence(EssenceComp, Companion);
		}
		else
		{
			EssenceComp = UInfuseEssencePlayerComponent::Get(Game::Mio);
			ConsumedLightEssence++;
			CheckAddLightBirdEssence(EssenceComp, Companion);
		}
	}

	void CheckAddLightBirdEssence(UInfuseEssencePlayerComponent EssenceComp, AHazeActor Companion)
	{
		if (ConsumedLightEssence == EssenceAmount)
		{
			// PrintToScreen("AllEssenceConsumed", 3.0);
			Niagara::SpawnOneShotNiagaraSystemAttached(AllEssenceConsumedVFXSystem, Companion.RootComponent);
			
			EssenceComp.AddOrb();
			if (!bBoundEvent)
			{
				bBoundEvent = true;
				EssenceComp.OnOrbsShouldReset.AddUFunction(this, n"DelayingRespawnEssence");
			}

			// Scale companions when they're ready!
			if (EssenceComp.HasEnoughOrbs())
			{
				AAISanctuaryLightBirdCompanion LightBird = LightBirdCompanion::GetLightBirdCompanion();
				auto AviationComp = USanctuaryCompanionAviationPlayerComponent::Get(Game::Mio);
				const float NewCompanionScale = Math::Lerp(LightBirbOGScale, CompanionAviation::MegaCompanionScale * 0.8, EssenceComp.GetProgress());
				if (ensure(NewCompanionScale > KINDA_SMALL_NUMBER, "EssenceConsumed: Negative scale?"))
					LightBird.SetActorScale3D(FVector::OneVector * NewCompanionScale);
			}
		}
	}

	void CheckAddDarkPortalEssence(UInfuseEssencePlayerComponent EssenceComp, AHazeActor Companion)
	{
		if (ConsumedDarkEssence == EssenceAmount)
		{
			// PrintToScreen("AllEssenceConsumed", 3.0);
			Niagara::SpawnOneShotNiagaraSystemAttached(AllEssenceConsumedVFXSystem, Companion.RootComponent);
			
			EssenceComp.AddOrb();
			if (!bBoundEvent)
			{
				bBoundEvent = true;
				EssenceComp.OnOrbsShouldReset.AddUFunction(this, n"DelayingRespawnEssence");
			}

			PrintToScreen("INFUUUSSED" + EssenceAmount, 2.0);

			// Scale companions when they're ready!
			if (EssenceComp.HasEnoughOrbs())
			{
				AAISanctuaryDarkPortalCompanion DarkPortal = DarkPortalCompanion::GetDarkPortalCompanion();
				auto AviationComp = USanctuaryCompanionAviationPlayerComponent::Get(Game::Zoe);
				const float NewCompanionScale = Math::Lerp(DarkPortalOGScale, CompanionAviation::MegaCompanionScale * 0.8, EssenceComp.GetProgress());
				if (ensure(NewCompanionScale > KINDA_SMALL_NUMBER, "EssenceConsumed: Negative scale?"))
					DarkPortal.SetActorScale3D(FVector::OneVector * NewCompanionScale);
				
			}
		}
	}

	UFUNCTION()
	void HideEssences()
	{
		for (auto Essence : LightEssenceActors)
		{	
			Essence.AddActorDisable(this);
			//Essence.SetActorLocation(EssenceRoot.WorldLocation + Math::GetRandomPointInSphere() * FVector(1.0, 1.0, 1.5)* EssenceRadius);
		}

		for (auto Essence : DarkEssenceActors)
		{	
			Essence.AddActorDisable(this);
			//Essence.SetActorLocation(EssenceRoot.WorldLocation + Math::GetRandomPointInSphere() * FVector(1.0, 1.0, 1.5)* EssenceRadius);
		}
	}

	UFUNCTION(DevFunction)
	void Devrespwan()	
	{
		RespawnEssence();
	}
};