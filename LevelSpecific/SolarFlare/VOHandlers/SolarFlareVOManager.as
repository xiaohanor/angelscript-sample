class ASolarFlareVOManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent VisualComp;
	default VisualComp.SetWorldScale3D(FVector(5.0));
#endif

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListComp;

	void TriggerSolarHitVO(AHazePlayerCharacter Player)
	{
		Print("TriggerSolarHitVO");
		FSolarFlareVOControlRoomHitParams Params;
		Params.Player = Player;
		USolarFlareVOControlRoomSolarHitEffectHandler::Trigger_OnFlareHit(this, Params);
	}

	void TriggerDoubleInteractStarted(AHazePlayerCharacter Player)
	{
		Print("TriggerDoubleInteractStarted");
		FSolarFlareVOControlRoomDoubleInteractStartedParams Params;
		Params.InteractingPlayer = Player;
		USolarFlareVOControlRoomDoubleInteractEffectHandler::Trigger_OnDoubleInteractStarted(Player, Params);
	}

	void TriggerDoubleInteractCompleted()
	{
		Print("TriggerDoubleInteractCompleted");
		USolarFlareVOControlRoomDoubleInteractEffectHandler::Trigger_OnDoubleInteractCompleted(this);
	}

	void TriggerGrappleFailedAttempt()
	{
		Print("TriggerGrappleFailedAttempt");
		USolarFlareVOGreenhouseLiftDoubleInteractEffectHandler::Trigger_GrappleFailedAttempt(Game::GetMio());
	}

	//Calls from level blueprint
	UFUNCTION()
	void TriggerGreenhouseExplosion()
	{
		Print("TriggerGreenhouseExplosion");
		USolarFlareVOGreenhouseDestructionEffectHandler::Trigger_GreenhouseExplosion(this);
	}

	void TriggerSidescrollLiftStarted()
	{
		Print("TriggerSidescrollLiftStarted");
		USolarFlareVOSidescrollLiftFallingEffectHandler::Trigger_OnLiftStarted(this);
	}

	void TriggerSidescrollLiftImpact()
	{
		Print("TriggerSidescrollLiftImpact");
		USolarFlareVOSidescrollLiftFallingEffectHandler::Trigger_OnLiftImpact(this);
	}

	//Calls from level blueprint
	UFUNCTION()
	void TriggerBridgeBreakSequenceStarted(AHazePlayerCharacter Player)
	{
		Print("TriggerBridgeBreakSequenceStarted");
		FOnSolarFlareVOBridgeBreakParams Params;
		Params.Player = Player;
		USolarFlareVOBridgeBreakEffectHandler::Trigger_OnSolarPanelBreak(Player, Params);
	}

	void TriggerSidescrollPoleInteract()
	{
		Print("TriggerSidescrollPoleInteract");
		USolarFlareVOControlPanelSingleInteract::Trigger_OnPanelInteracted(this);
	}
	
	//Calls from level blueprint
	UFUNCTION()
	void TriggerTunnelZiplineStarted()
	{
		Print("TriggerTunnelZiplineStarted");
		USolarFlareVOTunnleZiplineEffectHandler::Trigger_OnTunnelZiplineStarted(this);
	}

	//Calls from level blueprint
	UFUNCTION()
	void TriggerTunnelZiplineImpact()
	{
		Print("TriggerTunnelZiplineImpact");
		USolarFlareVOTunnleZiplineEffectHandler::Trigger_OnTunnelZiplineImpact(this);
	}

	void TriggerDeathEvent(AHazePlayerCharacter Player)
	{
		// Print("TriggerDeathEvent");
		FOnSolarFlareDeathParams Params;
		Params.Player = Player;
		USolarFlareVODeathEffectHandler::Trigger_OnSolarFlareDeath(this, Params);
	}

	//Calls from level blueprint
	UFUNCTION()
	void TriggerIntroSequenceFinished()
	{
		USolarFlareVOIntroSequenceFinish::Trigger_OnSequenceIntroFinished(Game::GetMio());
	}

	void TriggerQuickCoverButtonMashing(AHazePlayerCharacter Player)
	{
		FOnQuickCoverButtonMash Params;
		Params.PlayerMashing = Player;
		USolarFlareVOQuickCoverEffectHandler::Trigger_OnPlayerButtonMashing(this, Params);
	}
};