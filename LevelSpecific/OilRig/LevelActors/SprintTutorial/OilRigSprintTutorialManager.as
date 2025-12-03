event void FOilRigSprintTutorialManagerLightEvent(int Index);
event void FOilRigSprintTutorialManagerStatusChangedEvent();

UCLASS(Abstract)
class AOilRigSprintTutorialManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;
	UPROPERTY(DefaultComponent)
	UHazeActionQueueComponent ActionQueue;

	UPROPERTY(EditInstanceOnly)
	TArray<AHazeNiagaraActor> DangerEffects;

	UPROPERTY(EditInstanceOnly)
	APlayerTrigger PlayerTrigger;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UDeathEffect> DeathEffect;

	UPROPERTY()
	FOilRigSprintTutorialManagerLightEvent OnLightTurnedOn;

	UPROPERTY()
	FOilRigSprintTutorialManagerStatusChangedEvent OnSafetyActivated;

	UPROPERTY()
	FOilRigSprintTutorialManagerStatusChangedEvent OnDangerActivated;

	float SafeTime = 4.5;
	float DangerTime = 2.0;
	float DeathEffectForce = 10.0;

	bool bDangerActive = false;
	float StartPredictedTime = 0.0;

	int LightsOn = 0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PlayerTrigger.OnPlayerEnter.AddUFunction(this, n"PlayerEnter");
	}

	UFUNCTION()
	private void PlayerEnter(AHazePlayerCharacter Player)
	{
		if (bDangerActive)
			Player.KillPlayer(FPlayerDeathDamageParams(DangerEffects[0].ActorUpVector, DeathEffectForce), DeathEffect);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (!ActionQueue.IsEmpty())
			ActionQueue.ScrubTo(Time::PredictedGlobalCrumbTrailTime - StartPredictedTime);
	}

	UFUNCTION()
	void Activate()
	{
		if (Network::IsGameNetworked())
		{
			if (HasControl())
			{
				// The control side starts activating a half ping later, so that the actual activation
				// matches up more closely between both sides
				StartPredictedTime = Time::PredictedGlobalCrumbTrailTime + Network::PingOneWaySeconds;
				Timer::SetTimer(this, n"StartDangerLoop", Network::PingOneWaySeconds);
				NetActivateOnRemote(StartPredictedTime);
			}
		}
		else
		{
			StartPredictedTime = Time::PredictedGlobalCrumbTrailTime;
			StartDangerLoop();
		}
	}

	UFUNCTION(NetFunction)
	private void NetActivateOnRemote(float Time)
	{
		if (!HasControl())
		{
			StartPredictedTime = Time;
			StartDangerLoop();
		}
	}

	UFUNCTION()
	private void StartDangerLoop()
	{
		ActionQueue.SetLooping(true);
		ActionQueue.Event(this, n"ActivateDanger");
		ActionQueue.Idle(DangerTime);
		ActionQueue.Event(this, n"ActivateSafety");

		float LightInterval = (SafeTime - DangerTime) / 6.0;
		ActionQueue.Idle(1.0);
		ActionQueue.Event(this, n"StartActivatingLights");
		for (int i = 0; i < 6; ++i)
		{
			ActionQueue.Idle(LightInterval);
			ActionQueue.Event(this, n"ActivateLight");
		}

		ActionQueue.Idle(SafeTime - 1.0 - LightInterval*6.0);
	}

	UFUNCTION()
	private void ActivateDanger()
	{
		bDangerActive = true;

		for (AHazeNiagaraActor DangerEffect : DangerEffects)
		{
			DangerEffect.NiagaraComponent0.Activate(true);
		}

		for (AHazePlayerCharacter Player : Game::GetPlayers())
		{
			if (Player.IsOverlappingActor(PlayerTrigger))
			{
				Player.KillPlayer(FPlayerDeathDamageParams(DangerEffects[0].ActorUpVector, DeathEffectForce), DeathEffect);
			}
		}

		OnDangerActivated.Broadcast();
	}

	UFUNCTION()
	private void ActivateSafety()
	{
		bDangerActive = false;

		for (AHazeNiagaraActor DangerEffect : DangerEffects)
		{
			DangerEffect.NiagaraComponent0.Deactivate();
		}

		OnSafetyActivated.Broadcast();
	}

	UFUNCTION()
	private void StartActivatingLights()
	{
		LightsOn = 0;
	}

	UFUNCTION()
	private void ActivateLight()
	{
		OnLightTurnedOn.Broadcast(LightsOn);
		LightsOn++;
	}
}