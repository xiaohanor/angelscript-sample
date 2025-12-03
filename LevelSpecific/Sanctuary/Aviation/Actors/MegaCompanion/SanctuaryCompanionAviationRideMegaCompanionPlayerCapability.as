struct FSanctuaryCompanionAviationRideMegaCompanionPlayerActivationParams
{
	FVector SnapLocation;
	FRotator SnapRotation;
}
struct FSanctuaryCompanionAviationRideMegaCompanionPlayerDeactivationParams
{
	bool bCutscene = false;
	bool bNatural = false;
}

class USanctuaryCompanionAviationRideMegaCompanionPlayerCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(AviationCapabilityTags::Aviation);
	default CapabilityTags.Add(AviationCapabilityTags::AviationRiding);
	default CapabilityTags.Add(AviationCapabilityTags::MegaCompanion);
	default DebugCategory = AviationCapabilityTags::Aviation;
	default TickGroup = EHazeTickGroup::Movement;
	UPlayerHealthComponent HealthComp;
	// default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	private USceneComponent AttachComp;
	private ASanctuaryBossArenaManager ArenaManager;
	USanctuaryCompanionAviationPlayerComponent AviationComp;
	USanctuaryCompanionMegaCompanionPlayerComponent PlayerComponent;
	UMedallionPlayerGloryKillComponent GloryKillComp;
	UInfuseEssencePlayerComponent EssenceComp;
	UMedallionPlayerComponent MedallionComp;

	FSanctuaryCompanionAviationRideMegaCompanionPlayerActivationParams ActivationParams;
	bool bAddedLocomotion = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PlayerComponent = USanctuaryCompanionMegaCompanionPlayerComponent::Get(Player);
		GloryKillComp = UMedallionPlayerGloryKillComponent::GetOrCreate(Player);
		TListedActors<ASanctuaryBossArenaManager> BossManagers;
		if (BossManagers.Num() == 1)
			ArenaManager = BossManagers[0];

		AviationComp = USanctuaryCompanionAviationPlayerComponent::Get(Owner);
		EssenceComp = UInfuseEssencePlayerComponent::Get(Player);
		UPlayerHealthComponent::Get(Player).OnStartDying.AddUFunction(this, n"DeactivateAviation");
		MedallionComp = UMedallionPlayerComponent::GetOrCreate(Owner);
	}

	UFUNCTION()
	private void DeactivateAviation()
	{
		if (AviationComp.GetIsAviationActive())
			AviationComp.StopAviation();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FSanctuaryCompanionAviationRideMegaCompanionPlayerActivationParams& Params) const
	{
		if (GloryKillComp.GloryKillState == EMedallionGloryKillState::EnterSequence)
			return false;
		if (GloryKillComp.GloryKillState == EMedallionGloryKillState::ExecuteSequence)
			return false;
		if (Player.bIsControlledByCutscene)
			return false;

		if (AviationComp.GetIsAviationActive() || MedallionComp.IsMedallionCoopFlying())
		{
			Params.SnapLocation = Player.ActorLocation;
			Params.SnapRotation = Player.ActorRotation;
			return true;
		}
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FSanctuaryCompanionAviationRideMegaCompanionPlayerDeactivationParams& Params) const
	{
		if (GloryKillComp.GloryKillState == EMedallionGloryKillState::EnterSequence || GloryKillComp.GloryKillState == EMedallionGloryKillState::ExecuteSequence)
		{
			Params.bCutscene = true;
			Params.bNatural = true;
			return true;
		}

		if (AviationComp.GetIsAviationActive())
			return false;
		if (MedallionComp.IsMedallionCoopFlying())
			return false;


		Params.bNatural = true;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FSanctuaryCompanionAviationRideMegaCompanionPlayerActivationParams Params)
	{
		// Add locomotion feature
		if (!bAddedLocomotion && PlayerComponent.MegaCompanion.PlayerRideLocomotionFeature != nullptr)
		{
			bAddedLocomotion = true;
			ULocomotionFeatureMegaCompanionRiding LocomotionFeature = PlayerComponent.MegaCompanion.PlayerRideLocomotionFeature;
			Player.AddLocomotionFeature(LocomotionFeature, this);
		}

		ActivationParams = Params;
		bool bAttachedToSequence = false;
		if (PlayerComponent.MegaCompanion.AttachParentActor != nullptr)
		{
			ASanctuaryCompanionAviationSwoopSequence PlayingSequence = Cast<ASanctuaryCompanionAviationSwoopSequence>(PlayerComponent.MegaCompanion.AttachParentActor);
			if (PlayingSequence != nullptr)
			{
				bAttachedToSequence = true;
				PlayingSequence.OnDone.AddUFunction(this, n"Ride");
			}
		}
		if (!bAttachedToSequence)
		{
			Ride();
		}
	}

	UFUNCTION()
	private void Ride()
	{
		PlayerComponent.bIsRiding = true;
		PlayerComponent.MegaCompanion.AttachRootComponentTo(Player.RootComponent, NAME_None, EAttachLocation::SnapToTarget, true);

		PlayerComponent.MegaCompanion.SetActorLocation(ActivationParams.SnapLocation);
		PlayerComponent.MegaCompanion.SetActorRotation(ActivationParams.SnapRotation);

		if (AttachComp == nullptr)
			AttachComp = USceneComponent::Create(PlayerComponent.MegaCompanion, n"PlayerAttachComponent");
		
		if (AttachComp.AttachParent != PlayerComponent.MegaCompanion.SkeletalMesh)
			AttachComp.AttachToComponent(PlayerComponent.MegaCompanion.SkeletalMesh, GetCompanionMountBoneName());

		if (Player.IsMio() && ! PlayerComponent.bModifiedMioAttachedTransform)
		{
			PlayerComponent.bModifiedMioAttachedTransform = true;
			FRotator NeckRotation = PlayerComponent.MegaCompanion.SkeletalMesh.GetSocketRotation(n"Neck");
			FTransform AttachTransform = FTransform(NeckRotation.Inverse);
			PlayerComponent.MegaCompanion.PlayerAttachOffset = PlayerComponent.MegaCompanion.PlayerAttachOffset * AttachTransform;
		}

		AttachComp.SetRelativeTransform(PlayerComponent.MegaCompanion.PlayerAttachOffset);
		// AttachComp.SetWorldScale3D(Player.Mesh.GetWorldScale());
		
		Player.MeshOffsetComponent.AttachToComponent(AttachComp, n"", EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, EAttachmentRule::KeepWorld, false);
		Player.MeshOffsetComponent.SnapToRelativeTransform(this, AttachComp, FTransform::Identity);

		Player.BlockCapabilities(CapabilityTags::Collision, this);
		Player.BlockCapabilities(CapabilityTags::Outline, this);
		Player.BlockCapabilities(CapabilityTags::GameplayAction, this);

		if (EssenceComp != nullptr)
			EssenceComp.RemoveFloatyOrbs();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FSanctuaryCompanionAviationRideMegaCompanionPlayerDeactivationParams Params)
	{
		if (PlayerComponent.bIsRiding)
		{
			AttachComp.DetachFromParent();

			PlayerComponent.bIsRiding = false;
			Player.UnblockCapabilities(CapabilityTags::Collision, this);
			Player.UnblockCapabilities(CapabilityTags::Outline, this);
			Player.UnblockCapabilities(CapabilityTags::GameplayAction, this);

			Player.ClearSettingsByInstigator(this);

			Player.GetMeshOffsetComponent().ClearOffset(this);

			// if (!Params.bCutscene)
			{
				Player.MeshOffsetComponent.AttachToComponent(Player.RootOffsetComponent);
				Player.MeshOffsetComponent.SetRelativeTransform(FTransform::Identity);
			}
			Player.ClearCameraSettingsByInstigator(this);

			PlayerComponent.MegaCompanion.DetachFromActor();
		}
	}

	private FName GetCompanionMountBoneName()
	{
		if (PlayerComponent.MegaCompanion.bIsLightBird)
			return n"Neck";
		return n"Hips";
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (Player.Mesh.CanRequestLocomotion())
		{
			if (bAddedLocomotion)
				Player.RequestLocomotion(n"MegaCompanionRiding", this);
			else
				Player.RequestLocomotion(n"AirMovement", this);
		}
#if EDITOR
		TEMPORAL_LOG(PlayerComponent.MegaCompanion, "Companion Stuffz").Transform("Player Transformy", Player.ActorTransform, 120.0, 5.0);
		TEMPORAL_LOG(PlayerComponent.MegaCompanion, "Companion Stuffz").Transform("Player Mesh Transformy", Player.MeshOffsetComponent.WorldTransform, 120.0, 5.0);
		// TEMPORAL_LOG(PlayerComponent.MegaCompanion, "Companion Stuffz").Transform("Player Offset Transformy", Player.RootOffsetComponent.WorldTransform, 120.0, 5.0);
		// Debug::DrawDebugCoordinateSystem(Player.ActorLocation, Player.ActorRotation, 120.0, 5.0, 0.0, true);
#endif
	}
};

