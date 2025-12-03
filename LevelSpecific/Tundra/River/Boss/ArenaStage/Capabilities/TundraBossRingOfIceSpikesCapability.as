class UTundraBossRingOfIceSpikesCapability : UTundraBossChildCapability
{
	float Duration;
	bool bWindowOpen = false;
	int RingOfIceSpikeIndex = 0;
	FVector2D OpeningWindow = FVector2D(4.2, 6.25);

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(Boss.State != ETundraBossStates::RingsOfIceSpikes)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(ActiveDuration > Duration)
			return true;

		if(Boss.State != ETundraBossStates::RingsOfIceSpikes)
			return true;
		
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Duration = Boss.AnimInstance.GetTundraBossAnimationDuration(ETundraBossAttackAnim::RingsOfIce);
		Boss.RequestAnimation(ETundraBossAttackAnim::RingsOfIce);
		Boss.SpawnRingOfIce.AddUFunction(this, n"HandleSpawnRingOfIce");
		UTundraBossRingOfIceSpikesActor_EffectHandler::Trigger_RingOfIceAttackStarted(Boss);
		Boss.OnAttackEventHandler(Duration);

		if(!HasControl())
			return;
		
		bWindowOpen = false;		
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Boss.CapabilityStopped(ETundraBossStates::RingsOfIceSpikes);
		Boss.SpawnRingOfIce.Unbind(this, n"HandleSpawnRingOfIce");
		
		if(HasControl())
		{
			// If window is open it means we grabbed him and pushed another state. Deactivating the visuals on the interaction but not disabling the interaction itself
			if(bWindowOpen)
				CrumbDeactivateChestInteraction(true, false);
		}

		if(ActiveDuration > Duration)
		{
			UTundraBossRingOfIceSpikesActor_EffectHandler::Trigger_RingOfIceAttackStoppedAfterCharge(Boss);
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!HasControl())
			return;

		if(bWindowOpen == false)
		{
			if(ActiveDuration > OpeningWindow.X && ActiveDuration < OpeningWindow.Y)
			{
				CrumbActivateChestInteraction();
				bWindowOpen = true;
			}
		}
		else if(ActiveDuration > OpeningWindow.Y)
		{
			CrumbDeactivateChestInteraction(false, true);
			bWindowOpen = false;
		}
	}

	UFUNCTION()
	private void HandleSpawnRingOfIce()
	{
		FVector RingSpawnLocation = Math::Lerp(Boss.Mesh.GetSocketLocation(n"RightPaw"), Boss.Mesh.GetSocketLocation(n"LeftPaw"), 0.5);
		Boss.RingOfIceSpikeActors[RingOfIceSpikeIndex].TriggerRingOfIceSpikesActor(FVector(RingSpawnLocation.X, RingSpawnLocation.Y, Boss.IceHeight.GetActorLocation().Z), Boss);
		RingOfIceSpikeIndex++;
		
		if(!Boss.RingOfIceSpikeActors.IsValidIndex(RingOfIceSpikeIndex))
		{
			RingOfIceSpikeIndex = 0;
		}
	}
	
	UFUNCTION(CrumbFunction)
	void CrumbActivateChestInteraction()
	{
		Boss.RangedTreeInteractionTargetComp.Enable(Boss);
		Boss.RangedTreeInteractionTargetComp.OnCommitInteract.AddUFunction(this, n"HandleOnStartTreeInteraction");
		
		UTundraBossRingOfIceSpikesActor_EffectHandler::Trigger_RingOfIceAttackStartedCharging(Boss);
		
		FTundraBossChestBeltData InData;
		InData.Scene = Boss.RangedTreeInteractionTargetComp;
		UTundraBoss_EffectHandler::Trigger_ChestBeltActivating(Boss, InData);
		
		//ApplyPoi();
	}

	UFUNCTION(CrumbFunction)
	void CrumbDeactivateChestInteraction(bool bVisualsOnly, bool bMissedWindow)
	{
		FTundraBossChestBeltData InData;
		InData.Scene = Boss.RangedTreeInteractionTargetComp;
		UTundraBoss_EffectHandler::Trigger_ChestBeltDeactivating(Boss, InData);		

		// If we grab him, we're keeping this enabled
		if(!bVisualsOnly)
			Boss.RangedTreeInteractionTargetComp.Disable(Boss);

		if(bMissedWindow)
			UTundraBossRingOfIceSpikesActor_EffectHandler::Trigger_RingOfIceAttackStartedAfterCharge(Boss);
	}

	UFUNCTION()
	void HandleOnStartTreeInteraction()
	{	
		UTundraBossRingOfIceSpikesActor_EffectHandler::Trigger_RingOfIceAttackStoppedDuringCharge(Boss);
		
		FTundraBossChestBeltData Data;
		Data.Scene = Boss.RangedTreeInteractionTargetComp;
		UTundraBoss_EffectHandler::Trigger_ChestBeltGrabbed(Boss, Data);
		
		Boss.RangedTreeInteractionTargetComp.OnCommitInteract.Unbind(this, n"HandleOnStartTreeInteraction");
		Game::Zoe.ClearPointOfInterestByInstigator(this);

		if(!HasControl())
			return;

		Boss.PushAttack(ETundraBossStates::Grabbed);
	}

	UFUNCTION()
	void ApplyPoi()
	{
		FHazePointOfInterestFocusTargetInfo Poi;
		//Poi.SetFocusToMeshComponent(Boss.Mesh, n"TreeInteractionSocket");
		Poi.SetFocusToActor(Boss);
		//Poi.WorldOffset = FVector(0, 0, 1500);
		FApplyPointOfInterestSettings Settings;
		Settings.Duration = 0.5;
		
		Game::GetZoe().ApplyPointOfInterest(this, Poi, Settings);
	}
};