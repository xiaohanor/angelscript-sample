UCLASS(Abstract)
class AAISanctuaryDarkPortalCompanion : AHazeCharacter
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
	default CapabilityComp.DefaultCapabilities.Add(n"SanctuaryDarkPortalCompanionIntroCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SanctuaryDarkPortalCompanionReplaceWeaponPortalCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SanctuaryDarkPortalCompanionTightFollowCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SanctuaryDarkPortalCompanionFollowCapability");	
	default CapabilityComp.DefaultCapabilities.Add(n"SanctuaryDarkPortalCompanionFreeflyingEventCapability");	
	default CapabilityComp.DefaultCapabilities.Add(n"SanctuaryDarkPortalCompanionObstructedReturnCapability");	
	default CapabilityComp.DefaultCapabilities.Add(n"SanctuaryDarkPortalCompanionLaunchStartCapability");	
	default CapabilityComp.DefaultCapabilities.Add(n"SanctuaryDarkPortalCompanionLaunchCapability");	
	default CapabilityComp.DefaultCapabilities.Add(n"SanctuaryDarkPortalCompanionAtPortalCapability");	
	default CapabilityComp.DefaultCapabilities.Add(n"SanctuaryDarkPortalCompanionPortalExitCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SanctuaryDarkPortalCompanionPlayerTeleportCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SanctuaryDarkPortalCompanionInvestigateCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SanctuaryDarkPortalCompanionInvestigateAttachedCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SanctuaryDarkPortalCompanionOutOfViewTeleportCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SanctuaryDarkPortalCompanionObstructedTeleportCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SanctuaryDarkPortalCompanionMeshRotationCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SanctuaryDarkPortalCompanionDiscSlideFollowCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SanctuaryDarkPortalCompanionCentipedeFollowCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"BlockBehavioursWhenControlledByCutsceneCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SanctuaryDarlPortalCompanionHideDuringCutsceneCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SanctuaryDarkPortalCompanionAudioSetupCapability");

    UPROPERTY(DefaultComponent)
	UBasicAICharacterMovementComponent MoveComp;

    UPROPERTY(DefaultComponent)
	UBasicAIAnimationComponent AnimComp;
	default AnimComp.BaseMovementTag = LocomotionFeatureAITags::Movement;

	UPROPERTY(DefaultComponent)
	UBasicAIDestinationComponent DestinationComp;

	UPROPERTY(DefaultComponent)
	UBasicBehaviourComponent BehaviourComp; 
	
	UPROPERTY(DefaultComponent)
	USanctuaryDarkPortalCompanionComponent CompanionComp = nullptr;

	USanctuaryDarkPortalCompanionSettings Settings;

	//audio
	UPROPERTY(DefaultComponent)
	UHazeMovementAudioComponent AudioMoveComp;

	UPROPERTY(DefaultComponent)
	USanctuaryDarkPortalCompanionAudioComponent AudioComp;


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (CompanionComp.Player == nullptr)
			CompanionComp.Player = Game::Zoe;
		SetActorControlSide(CompanionComp.Player);
		Outline::AddToPlayerOutlineActor(this, CompanionComp.Player, this, EInstigatePriority::Low);
		Settings = USanctuaryDarkPortalCompanionSettings::GetSettings(this);

		EffectEvent::LinkActorToReceiveEffectEventsFrom(this, CompanionComp.Portal);
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
		//bHazeEditorOnlyDebugBool = true;
		if (bHazeEditorOnlyDebugBool)
		{
			Debug::DrawDebugString(FocusLocation, "" + CompanionComp.State);
			Debug::DrawDebugString(CompanionComp.Player.FocusLocation, "" + CompanionComp.Portal.State);
		}
#endif		
	}
}

enum EDarkPortalCompanionIntroPhase
{
	Prepare,
	Spawn
}

namespace DarkPortalCompanion
{
	UFUNCTION(BlueprintPure)
	AAISanctuaryDarkPortalCompanion GetDarkPortalCompanion()
	{
		auto UserComp = UDarkPortalUserComponent::Get(Game::Zoe);
		if (UserComp == nullptr)
			return nullptr;
		return UserComp.Companion;
	}

	FVector GetWatsonTeleportLocation(AHazePlayerCharacter Player)
	{
		FRotator ViewRot = Player.ViewRotation;
		FVector WatsonLocation = Player.ViewLocation - ViewRot.ForwardVector * 100.0 + ViewRot.RightVector * 200.0 + ViewRot.UpVector * 200.0;
		return WatsonLocation;
	}

	UFUNCTION(BlueprintCallable, meta = (ExpandEnumAsExecs = "Phase"))
	AAISanctuaryDarkPortalCompanion IntroduceDarkPortalCompanion(EDarkPortalCompanionIntroPhase Phase, FVector SpawnLocation, FRotator SpawnRotation, bool& out bWasSpawned)
	{
		AHazePlayerCharacter Player = Game::Zoe;
		UDarkPortalUserComponent User = UDarkPortalUserComponent::Get(Player);
		const FName Instigator = n"Introduction";

		if (Phase == EDarkPortalCompanionIntroPhase::Prepare)
		{
			User.bIsIntroducing = true;
			return User.Companion;
		}

		if (Phase == EDarkPortalCompanionIntroPhase::Spawn)
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
	void DarkPortalInvestigate(FDarkPortalInvestigationDestination Destination, FInstigator Instigator, EInstigatePriority Prio = EInstigatePriority::Normal)
	{
		AHazePlayerCharacter Player = Game::Zoe;
		UDarkPortalUserComponent User = UDarkPortalUserComponent::Get(Player);
		if (User == nullptr)
			return;

		User.Companion.CompanionComp.InvestigationDestination.Apply(Destination, Instigator, Prio);	
	}

	UFUNCTION(BlueprintCallable, Meta = (DefaultToSelf = Instigator))
	void DarkPortalStopInvestigating(FInstigator Instigator)
	{
		AHazePlayerCharacter Player = Game::Zoe;
		UDarkPortalUserComponent User = UDarkPortalUserComponent::Get(Player);
		if (User == nullptr)
			return;
		if (User.Companion == nullptr) // end play in editor
			return;

		User.Companion.CompanionComp.InvestigationDestination.Clear(Instigator);	
	}

	UFUNCTION(BlueprintCallable)
	void DarkPortalForceLeavePortal()
	{
		AHazePlayerCharacter Player = Game::Zoe;
		UDarkPortalUserComponent User = UDarkPortalUserComponent::Get(Player);
		if (User == nullptr)
			return;

		if (User.Portal.State == EDarkPortalState::Settle)	
			User.Portal.InstantRecall();	
	}

	UFUNCTION(BlueprintPure)
	UHazeAudioEmitter GetDarkPortalVOEmitter()
	{
		auto DarkPortalCompanion = GetDarkPortalCompanion();
		if(DarkPortalCompanion == nullptr)
			return nullptr;

		auto AudioComponent = UHazeAudioComponent::Get(DarkPortalCompanion);
		if(AudioComponent == nullptr)
			return nullptr;

		return AudioComponent.GetEmitter(DarkPortalCompanion, n"DarkPortalCompanion_VOEmitter");
	}
}
