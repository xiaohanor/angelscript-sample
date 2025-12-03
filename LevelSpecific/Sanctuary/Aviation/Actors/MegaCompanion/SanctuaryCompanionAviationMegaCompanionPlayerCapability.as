class USanctuaryCompanionAviationMegaCompanionPlayerCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(AviationCapabilityTags::MegaCompanion);
	default CapabilityTags.Add(AviationCapabilityTags::MegaCompanionVisible);
	default DebugCategory = AviationCapabilityTags::Aviation;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	private ASanctuaryMegaCompanion MegaCompanion;
	USanctuaryCompanionMegaCompanionPlayerComponent PlayerComponent;
	UInfuseEssencePlayerComponent EssenceComp;
	UMedallionPlayerComponent MedallionComp;
	UMedallionPlayerReferencesComponent RefsComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PlayerComponent = USanctuaryCompanionMegaCompanionPlayerComponent::Get(Player);
		SpawnMegaCompanion();
		MegaCompanion.AddActorVisualsBlock(this);
		EssenceComp = UInfuseEssencePlayerComponent::Get(Player);
		MedallionComp = UMedallionPlayerComponent::GetOrCreate(Player);
		RefsComp = UMedallionPlayerReferencesComponent::GetOrCreate(Player);
	}

	private void SpawnMegaCompanion()
	{
		if (Player == Game::Zoe)
			MegaCompanion = SpawnActor(PlayerComponent.MegaDarkMorayClass, FVector::ZeroVector, FRotator::ZeroRotator, n"MegaDarkPortalCompanion", true);
		else
			MegaCompanion = SpawnActor(PlayerComponent.MegaLightBirdClass, FVector::ZeroVector, FRotator::ZeroRotator, n"MegaLightBirdCompanion", true);

		MegaCompanion.MakeNetworked(this, 0);
		MegaCompanion.SetActorControlSide(Player);
		FinishSpawningActor(MegaCompanion);
		PlayerComponent.MegaCompanion = MegaCompanion;
		PlayerComponent.CompanionRidingOffset = MegaCompanion.SkeletalMesh.RelativeLocation;
		MegaCompanion.SkeletalMesh.SetRelativeLocation(FVector());
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{
		MegaCompanion.DestroyActor();
		MegaCompanion = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MegaCompanion.bIsControlledByCutscene)
			return true;
		if (RefsComp.Refs != nullptr && RefsComp.Refs.HydraAttackManager.Phase >= EMedallionPhase::GloryKill3 && !MegaCompanion.bIsControlledByCutscene)
			return false;
		if (Player.IsAnyCapabilityActive(AviationCapabilityTags::Aviation))
			return true;
		if (MedallionComp.IsMedallionCoopFlying())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MegaCompanion.bIsControlledByCutscene)
			return false;
		if (RefsComp.Refs != nullptr && RefsComp.Refs.HydraAttackManager.Phase >= EMedallionPhase::GloryKill3 && !MegaCompanion.bIsControlledByCutscene)
			return true;
		if (PlayerComponent.bTutorialStayForDoor)
			return false;
		if (Player.IsAnyCapabilityActive(AviationCapabilityTags::Aviation))
			return false;
		if (MedallionComp.IsMedallionCoopFlying())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		// AHazeCharacter Companion = GetCompanion();
		// Companion.SetActorScale3D(FVector::OneVector);
		// Companion.AddActorVisualsBlock(this);
		// if (!ensure(Companion != nullptr, "No companion found!"))
			// return;

		MegaCompanion.RemoveActorVisualsBlock(this);

		if (EssenceComp != nullptr)
			EssenceComp.RemoveFloatyOrbs();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		// AHazeCharacter Companion = GetCompanion();
		// if (Companion != nullptr)
		// 	Companion.RemoveActorVisualsBlock(this);
		MegaCompanion.AddActorVisualsBlock(this);
	}

	private AHazeCharacter GetCompanion()
	{
		if (MegaCompanion.bIsLightBird)
			return LightBirdCompanion::GetLightBirdCompanion();
		return DarkPortalCompanion::GetDarkPortalCompanion();
	}
};