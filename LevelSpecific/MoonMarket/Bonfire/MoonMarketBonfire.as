class AMoonMarketBonfire : AMoonMarketInteractableActor
{
	default CompatibleInteractions.Add(EMoonMarketInteractableTag::Lantern);
	
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UThreeShotInteractionComponent MioInteract;
	default MioInteract.UsableByPlayers = EHazeSelectPlayer::Mio;

	UPROPERTY(DefaultComponent)
	UThreeShotInteractionComponent ZoeInteract;
	default ZoeInteract.UsableByPlayers = EHazeSelectPlayer::Zoe;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent BonfireMesh;

	UPROPERTY(EditInstanceOnly)
	AActor LightActor;

	ULightComponent Light;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent Collision;
	default Collision.SetHiddenInGame(true);
	default Collision.SetCollisionResponseToChannel(ECollisionChannel::ECC_Camera, ECollisionResponse::ECR_Ignore);

	UPROPERTY(DefaultComponent, Attach = BonfireMesh)
	UStaticMeshComponent Sword;

	UPROPERTY()
	TSubclassOf<UHazeUserWidget> TextWidget;

	UPROPERTY(EditInstanceOnly)
	AMoonMarketGhost MioGhost;

	UPROPERTY(EditInstanceOnly)
	AMoonMarketGhost ZoeGhost;

	UPROPERTY(EditDefaultsOnly)
	UHazeCameraSpringArmSettingsDataAsset CameraSettings;

	UPROPERTY(EditAnywhere)
	UMaterialInstance BlueGhostMat;

	UPROPERTY(EditAnywhere)
	UMaterialInstance YellowGhostMat;

	UPROPERTY(EditAnywhere)
	float LightIntensityTarget = 15.0;

	float CurrentLightIntensity = 0.0;

	bool bActivated = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		SetActorTickEnabled(false);

		InteractComp.Disable(this);
		MioInteract.OnInteractionStarted.AddUFunction(this, n"OnInteractionStarted");
		MioInteract.OnInteractionStopped.AddUFunction(this, n"Cancel");
		ZoeInteract.OnInteractionStarted.AddUFunction(this, n"OnInteractionStarted");
		ZoeInteract.OnInteractionStopped.AddUFunction(this, n"Cancel");

		if(LightActor != nullptr)
		{
			Light = ULightComponent::Get(LightActor);
			if(Light == nullptr)
			{
				PrintError("Bonfire referenced actor " + LightActor.Name + " does not have a light component!");
			}
		}
		else
		{
			PrintError("Bonfire missing referenced light actor!");
		}

		UHazeSkeletalMeshComponentBase::Get(MioGhost).SetScalarParameterValueOnMaterials(n"Alpha", 0);
		UHazeSkeletalMeshComponentBase::Get(ZoeGhost).SetScalarParameterValueOnMaterials(n"Alpha", 0);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (CurrentLightIntensity != LightIntensityTarget)
			CurrentLightIntensity = Math::FInterpConstantTo(CurrentLightIntensity, LightIntensityTarget, DeltaSeconds, LightIntensityTarget / 5);

		float Sin = (1 + Math::Sin(Time::GameTimeSeconds * 1.5)) / 2.0;
		float Multiplier = 0.75 + (Sin / 1.7);

		if(Light != nullptr)
			Light.SetIntensity(CurrentLightIntensity * Multiplier);
		else
			PrintError("No spotlight assigned to bonfire");
	}

	private void OnInteractionStarted(UInteractionComponent InteractionComponent,
	                                  AHazePlayerCharacter Player) override
	{
		Super::OnInteractionStarted(InteractionComponent, Player);

		if(Player.IsZoe())
			ZoeInteract.Disable(this);
		else
			MioInteract.Disable(this);

		auto Lanterns = TListedActors<AMoonMarketRevealingLantern>().Array;
		for(auto Lantern : Lanterns)
		{
			if(Lantern.InteractingPlayer == Player)
			{
				SetGhostColor(Player, Lantern.PlatformType);

				if(bActivated)
					ActivateGhost(Player);
			}
		}

		if(!bActivated && InteractingPlayers.Num() == 2)
		{
			bActivated = true;
			TArray<UNiagaraComponent> NiagaraComps;
			GetComponentsByClass(UNiagaraComponent, NiagaraComps);
			
			for(int i = 0; i < NiagaraComps.Num(); i++)
			{
				NiagaraComps[i].Activate();
			}

			SetActorTickEnabled(true);
			UMoonMarketBonfireEventHandler::Trigger_OnFireLit(this);
			Widget::AddFullscreenWidget(TextWidget);

			ActivateGhost(InteractingPlayers[0]);
			ActivateGhost(InteractingPlayers[1]);
		}

		Player.ApplyCameraSettings(CameraSettings, 3, this, EHazeCameraPriority::High);
	}

	//Needs to be handled in a special way since it uses the three-shot interaction cancel
	UFUNCTION()
	private void Cancel(UInteractionComponent InteractionComponent, AHazePlayerCharacter Player)
	{
		StopInteraction(Player);
		Player.ClearCameraSettingsByInstigator(this, 3.0);
	}

	void SetGhostColor(AHazePlayerCharacter Player, EMoonMarketRevealableColor Color)
	{
		UMaterialInstance Mat = Color == EMoonMarketRevealableColor::Blue ? BlueGhostMat : YellowGhostMat;

		if(Player.IsMio())
		{
			MioGhost.SkelMesh.SetMaterial(0, Mat);
			UHazeSkeletalMeshComponentBase::Get(MioGhost).SetScalarParameterValueOnMaterials(n"Alpha", 0);
		}
		else
		{
			ZoeGhost.SkelMesh.SetMaterial(0, Mat);
			UHazeSkeletalMeshComponentBase::Get(ZoeGhost).SetScalarParameterValueOnMaterials(n"Alpha", 0);
		}
	}

	void ActivateGhost(AHazePlayerCharacter Player)
	{
		if(Player.IsMio())
		{
			UMoonMarketRevealableComponent::Get(MioGhost).StartFadingIn();
			MioGhost.SkelMesh.SetRenderedForPlayer(Player, true);
			MioGhost.SkelMesh.SetRenderedForPlayer(Player.OtherPlayer, false);
		}
		else
		{
			UMoonMarketRevealableComponent::Get(ZoeGhost).StartFadingIn();
			ZoeGhost.SkelMesh.SetRenderedForPlayer(Player, true);
			ZoeGhost.SkelMesh.SetRenderedForPlayer(Player.OtherPlayer, false);	
		}
	}

	void OnInteractionStopped(AHazePlayerCharacter Player) override
	{
		if(Player.IsZoe())
			ZoeInteract.Enable(this);
		else
			MioInteract.Enable(this);

		Super::OnInteractionStopped(Player);
		
		if(bActivated)
		{
			if(Player.IsMio())
			{
				UMoonMarketRevealableComponent::Get(MioGhost).FadeOut();
			}
			else
			{
				UMoonMarketRevealableComponent::Get(ZoeGhost).FadeOut();
			}
		}
	}
};