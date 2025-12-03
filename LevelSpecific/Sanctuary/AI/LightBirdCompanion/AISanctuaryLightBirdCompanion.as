UCLASS(Abstract)
class AAISanctuaryLightBirdCompanion : AHazeCharacter
{
	default CapsuleComponent.bOffsetBottomToAttachParentLocation = false;
	default CapsuleComponent.bGenerateOverlapEvents = false;
	default CapsuleComponent.CollisionProfileName = n"EnemyIgnoreCharacters";
	default Mesh.CollisionProfileName = n"NoCollision";
	default Mesh.AddTag(n"AutomatedRenderHidden");

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedActorPositionComponent SyncedPosition;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"BasicAIUpdateCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SanctuaryLightBirdCompanionIntroCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SanctuaryLightBirdCompanionTightFollowCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SanctuaryLightBirdCompanionFollowCapability"); 
	default CapabilityComp.DefaultCapabilities.Add(n"SanctuaryLightBirdCompanionLaunchStartCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SanctuaryLightBirdCompanionLaunchCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SanctuaryLightBirdCompanionLaunchAttachedCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SanctuaryLightBirdCompanionLaunchExitCapability");	
	default CapabilityComp.DefaultCapabilities.Add(n"SanctuaryLightBirdCompanionLanternRecallCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SanctuaryLightBirdCompanionLanternAttachedCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SanctuaryLightBirdCompanionObstructedReturnCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SanctuaryLightBirdCompanionFreeflyingEventCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SanctuaryLightBirdCompanionPlayerTeleportCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SanctuaryLightBirdCompanionLightUpCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SanctuaryLightBirdCompanionInvestigateCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SanctuaryLightBirdCompanionInvestigateAttachedCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SanctuaryLightBirdCompanionOutOfViewTeleportCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SanctuaryLightBirdCompanionObstructedTeleportCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SanctuaryLightBirdCompanionDiscSlideFollowCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SanctuaryLightBirdCompanionCentipedeFollowCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"BlockBehavioursWhenControlledByCutsceneCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SanctuaryLightBirdCompanionHideDuringCutsceneCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SanctuaryLightBirdCompanionAudioSetupCapability");

    UPROPERTY(DefaultComponent)
	UBasicAICharacterMovementComponent MoveComp;

    UPROPERTY(DefaultComponent)
	UBasicAIAnimationComponent AnimComp;
	default AnimComp.BaseMovementTag = LocomotionFeatureAITags::Flying;

	UPROPERTY(DefaultComponent)
	UBasicAIDestinationComponent DestinationComp;

	UPROPERTY(DefaultComponent)
	UBasicBehaviourComponent BehaviourComp; 

	UPROPERTY(DefaultComponent)
	UHazeSphereComponent HazeSphereComponent;

	UPROPERTY(DefaultComponent)
	UPointLightComponent PointLightComponent;
	default PointLightComponent.SetCastShadows(false);

	UPROPERTY(DefaultComponent)
	USanctuaryLightBirdCompanionComponent CompanionComp = nullptr;

	USanctuaryLightBirdCompanionSettings Settings;

	//audio
	UPROPERTY(DefaultComponent)
	UHazeMovementAudioComponent AudioMoveComp;

	UPROPERTY(DefaultComponent)
	USanctuaryLightBirdCompanionAudioComponent AudioComp;

	UPROPERTY(DefaultComponent, Attach = "MeshOffsetComponent")
	USceneComponent HaxMeshScaleComp;
	FVector HaxMeshScale = FVector::OneVector;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (CompanionComp.Player == nullptr)
			CompanionComp.Player = Game::Mio;
		SetActorControlSide(CompanionComp.Player);
		CompanionComp.GlowMaterial = Material::CreateDynamicMaterialInstance(this, Mesh.GetMaterial(0));
		if (CompanionComp.GlowMaterial != nullptr)
		{
			Mesh.SetMaterial(0, CompanionComp.GlowMaterial);
			CompanionComp.GlowMaterial.SetScalarParameterValue(n"Emissive", 0.1);
		}

		// HACK: Cutscene mesh gets broken by scale, so until this is handled by export or one-scaled model we hack it		
		Mesh.AttachToComponent(HaxMeshScaleComp, NAME_None, EAttachmentRule::KeepRelative);
		HaxMeshScale = Mesh.RelativeScale3D;
		HaxMeshScaleComp.RelativeScale3D = HaxMeshScale;
		Mesh.RelativeScale3D = FVector::OneVector;
		OnPreSequencerControl.AddUFunction(this, n"OnCutsceneStarted");
		OnPostSequencerControl.AddUFunction(this, n"OnCutsceneStopped");

		Settings = USanctuaryLightBirdCompanionSettings::GetSettings(this);
		Outline::AddToPlayerOutlineActor(this, CompanionComp.Player, this, EInstigatePriority::Low);
	}

	UFUNCTION()
	private void OnCutsceneStarted(FHazePreSequencerControlParams Params)
	{
		// HACK, see above
		HaxMeshScaleComp.RelativeScale3D = FVector::OneVector;
	}

	UFUNCTION()
	private void OnCutsceneStopped(FHazePostSequencerControlParams Params)
	{
		// HACK, see above
		HaxMeshScaleComp.RelativeScale3D = HaxMeshScale;
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		Outline::ClearOutlineOnActor(this, CompanionComp.Player, this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
#if EDITOR		

//Debug::DrawDebugSphere(ActorLocation, 100);
		//bHazeEditorOnlyDebugBool = true;
		if (bHazeEditorOnlyDebugBool)
		{
			Debug::DrawDebugString(FocusLocation, "" + CompanionComp.State);
		}
#endif
	}

	bool CanIlluminate() const
	{
		if (Settings != nullptr && Settings.IlluminateImmediately)
			return true;
		return (CompanionComp.Illuminators.Num() > 0);
	}

	bool MustIlluminate() const
	{
		return (CompanionComp.ForceIlluminators.Num() > 0);
	}
}

enum ELightBirdCompanionIntroPhase
{
	Prepare,
	Spawn
}

namespace LightBirdCompanion
{
	UFUNCTION(BlueprintPure)
	AAISanctuaryLightBirdCompanion GetLightBirdCompanion()
	{
		auto UserComp = ULightBirdUserComponent::Get(Game::Mio);
		if (UserComp == nullptr)
			return nullptr;
		return UserComp.Companion;
	}

	FVector GetWatsonTeleportLocation(AHazePlayerCharacter Player)
	{
		FRotator ViewRot = Player.ViewRotation;
		FVector WatsonLocation = Player.ViewLocation - ViewRot.ForwardVector * 100.0 + ViewRot.RightVector * -200.0 + ViewRot.UpVector * 200.0;
		return WatsonLocation;
	}

	UFUNCTION(BlueprintCallable, meta = (ExpandEnumAsExecs = "Phase"))
	AAISanctuaryLightBirdCompanion IntroduceLightBirdCompanion(ELightBirdCompanionIntroPhase Phase, FVector SpawnLocation, FRotator SpawnRotation, bool& out bWasSpawned)
	{
		AHazePlayerCharacter Player = Game::Mio;
		ULightBirdUserComponent User = ULightBirdUserComponent::Get(Player);
		if (User == nullptr)
			return nullptr;

		if (Phase == ELightBirdCompanionIntroPhase::Prepare)
		{
			User.bIsIntroducing = true;
			return User.Companion;
		}

		if (Phase == ELightBirdCompanionIntroPhase::Spawn)
		{
			bWasSpawned = User.bIsIntroducing;

			User.IntroLocation = SpawnLocation;
			User.IntroRotation = SpawnRotation;
			User.bIsIntroducing = false;
			return User.Companion;
		}
	
		return nullptr;
	}

	UFUNCTION(BlueprintCallable, Meta = (DefaultToSelf = Instigator))
	void LightBirdInvestigate(FLightBirdInvestigationDestination Destination, FInstigator Instigator, EInstigatePriority Prio = EInstigatePriority::Normal)
	{
		AHazePlayerCharacter Player = Game::Mio;
		ULightBirdUserComponent User = ULightBirdUserComponent::Get(Player);
		if (User == nullptr)
			return;

		User.Companion.CompanionComp.InvestigationDestination.Apply(Destination, Instigator, Prio);	
	}

	UFUNCTION(BlueprintCallable, Meta = (DefaultToSelf = Instigator))
	void LightBirdStopInvestigating(FInstigator Instigator)
	{
		AHazePlayerCharacter Player = Game::Mio;
		ULightBirdUserComponent User = ULightBirdUserComponent::Get(Player);
		if (User == nullptr)
			return;

		User.Companion.CompanionComp.InvestigationDestination.Clear(Instigator);	
	}

	UFUNCTION(BlueprintCallable)
	void LightBirdForceLeaveInteraction()
	{
		AHazePlayerCharacter Player = Game::Mio;
		ULightBirdUserComponent User = ULightBirdUserComponent::Get(Player);
		if (User == nullptr)
			return;

		if (User.State == ELightBirdState::Attached)	
			User.Hover();	
	}

	UFUNCTION(BlueprintPure)
	UHazeAudioEmitter GetLightBirdVOEmitter()
	{
		auto LightBirdCompanion = GetLightBirdCompanion();
		if(LightBirdCompanion == nullptr)
			return nullptr;

		auto AudioComponent = UHazeAudioComponent::Get(LightBirdCompanion);
		if(AudioComponent == nullptr)
			return nullptr;

		return AudioComponent.GetEmitter(LightBirdCompanion, n"LightBirdCompanion_VOEmitter");
	}
}
