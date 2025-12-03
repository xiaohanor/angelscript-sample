class UTundraWalkingStickChargeScreamCapability : UTundraWalkingStickBaseCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default TickGroup = EHazeTickGroup::Gameplay;

	FHazeAcceleratedFloat AccFF;

	const bool bDebug = true;

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if(!bDebug)
			return;

		if(!IsActive())
			return;

		// Debug::DrawDebugSphere(Game::Zoe.ActorLocation, 100.0, 12, ActiveDuration >= WalkingStick.ScreamChargeUpDuration ? FLinearColor::Green : FLinearColor::Red);
	}
#endif

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!WalkingStick.bGameplaySpider)
			return false;

		if(!WalkingStick.LifeGivingActorRef.LifeReceivingComp.bCurrentlyInteractingDuringLifeGive)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FTundraWalkingStickChargeScreamDeactivatedParams& Params) const
	{
		if(!WalkingStick.bGameplaySpider)
			return true;

		if(!WalkingStick.LifeGivingActorRef.LifeReceivingComp.bCurrentlyInteractingDuringLifeGive)
		{
			Params.bShouldScream = (ActiveDuration >= WalkingStick.ScreamChargeUpDuration) && !Owner.bIsControlledByCutscene;
			return true;
		}

		// Check this after the above so scream will be unleashed when attacked by gnapes while fully charged
		if(!WalkingStick.bTreeGuardianInteracting)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FHazeFrameForceFeedback ForceFeedback;
		AccFF.AccelerateTo(0.3, WalkingStick.ScreamChargeUpDuration, DeltaTime);
		ForceFeedback.LeftTrigger = AccFF.Value;
		Game::Zoe.SetFrameForceFeedback(ForceFeedback, 1);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		WalkingStick.TimeOfStartChargingScream.Set(Time::GetGameTimeSeconds());
		UTundraWalkingStickEffectHandler::Trigger_OnStartChargingScream(WalkingStick);
		AccFF.SnapTo(0);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FTundraWalkingStickChargeScreamDeactivatedParams Params)
	{
		WalkingStick.TimeOfStartChargingScream.Reset();

		FTundraWalkingStickStopChargingScreamEffectParams EffectParams;
		EffectParams.bScreamSuccessful = Params.bShouldScream;
		UTundraWalkingStickEffectHandler::Trigger_OnStopChargingScream(WalkingStick, EffectParams);

		if(Params.bShouldScream)
		{
			WalkingStick.PlayScream();
			UTundraWalkingStickEffectHandler::Trigger_OnScream(WalkingStick);
		}
		else
			UTundraWalkingStickEffectHandler::Trigger_OnFailScream(WalkingStick);
	}
}

struct FTundraWalkingStickChargeScreamDeactivatedParams
{
	bool bShouldScream = false;
}