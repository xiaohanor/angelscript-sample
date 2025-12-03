class USanctuaryDarlPortalCompanionHideDuringCutsceneCapability : UHazeCapability
{
	default CapabilityTags.Add(DarkPortal::Tags::DarkPortal);
	default CapabilityTags.Add(n"HideDuringCutscene");
	default CapabilityTags.Add(n"Teleport");
	default CapabilityTags.Add(n"BlockedDuringIntro");	

	default TickGroup = EHazeTickGroup::BeforeMovement; 
	default TickGroupOrder = 10; 

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	USanctuaryDarkPortalCompanionComponent CompanionComp;
	USanctuaryLightBirdCompanionSettings Settings;
	TArray<UNiagaraComponent> AttachedEffects;
	bool bVisible = true;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		CompanionComp = USanctuaryDarkPortalCompanionComponent::Get(Owner); 
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (CompanionComp.Player == nullptr)
			return false;
		if (!CompanionComp.Player.bIsControlledByCutscene)
			return false;
		if (Owner.bIsControlledByCutscene)
			return false;
		AHazePlayerCharacter FullScreenPlayer = SceneView::FullScreenPlayer;
		if (FullScreenPlayer == nullptr)
			return false;
		if (FullScreenPlayer.CurrentlyUsedCamera == nullptr)
			return false;
		if (FullScreenPlayer.CurrentlyUsedCamera.Owner == nullptr)
			return false;
		if (!FullScreenPlayer.CurrentlyUsedCamera.Owner.IsA(AHazeCinematicCameraActor))
			return false;
		// Controlling player is in a cutscene which we're not in, hide!
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!CompanionComp.Player.bIsControlledByCutscene)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		if (!bVisible)
			return;

		bVisible = false;
		Owner.AddActorVisualsBlock(this);
		Owner.BlockCapabilities(CapabilityTags::Movement, this);

		AttachedEffects.Reset(AttachedEffects.Num());
		Owner.GetComponentsByClass(AttachedEffects);
		for (UNiagaraComponent Effect : AttachedEffects)
		{
			// Turn off trail etc so we won't get streaks of these in front of camera when watson teleporting on deactivation
			if (Effect != nullptr)
				Effect.Deactivate();
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if (HasControl() && (CompanionComp.Player != nullptr))
		{
			AHazePlayerCharacter ViewPlayer = SceneView::FullScreenPlayer;
			if (ViewPlayer == nullptr)
				ViewPlayer = CompanionComp.Player;
			CrumbPlaceBehindCamera(DarkPortalCompanion::GetWatsonTeleportLocation(ViewPlayer), ViewPlayer.ViewRotation);
		}
		if (CompanionComp.Player == nullptr)
			Restore();
	}

	UFUNCTION(CrumbFunction)
	void CrumbPlaceBehindCamera(FVector Location, FRotator Rotation)
	{
		if (IsActorValid(Owner)) // Don't teleport if ending play etc
			Owner.TeleportActor(Location, Rotation, this, false);
		Restore();
	}

	void Restore()
	{
		if (bVisible)
			return;
		bVisible = true;
		Owner.UnblockCapabilities(CapabilityTags::Movement, this);
		if (CompanionComp.bSpecialCaseDelayVisibleAfterFallFromCompanionsCutscene)
		{
			Timer::SetTimer(this, n"MakeVisible", 0.1);
		}
		else
		{
			MakeVisible();
		}
	}

	UFUNCTION()
	void MakeVisible()
	{
		for (UNiagaraComponent Effect : AttachedEffects)
		{
			// Turn trail etc back on again
			if (Effect == nullptr)
				continue;
			Effect.ResetSystem();
			Effect.Activate();
		}
		Owner.RemoveActorVisualsBlock(this);
	}
};