enum EPinballBossTargetState
{
	// We have not yet been triggered
	Idle,

	// We have been triggered, but are waiting for TriggerDelay to pass
	WaitingForTriggerDelay,

	// We have waited past the trigger, but there is some additional delay put on us
	WaitingForRandomDelay,

	// The countdown has started, we are now displaying a targeting laser and crosshair
	CountDownStarted,

	// A rocket has been launched, change color of the target
	RocketLaunched,

	// The rocket has hit, exploding the targeted actors
	RocketHit,

	Disabled,
};

/**
 * A target for the Pinball Boss to fire missiles at.
 * Works in a stateless way, by simply syncing an initial time and delays from that time.
 * All states are derived from time passed since the initial time, and what delays we have passed since then.
 * @see APinballBossRocket
 */
UCLASS(Abstract, HideCategories = "Rendering Actor Cooking DataLayers Replication ActorTick")
class APinballBossTarget : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent LaserNiagaraComp;

	UPROPERTY(DefaultComponent)
	UHazeMovablePlayerTriggerComponent PlayerTriggerComp;

	UPROPERTY(DefaultComponent)
	UPinballBossTargetExplosionRadiusComponent ExplosionRadiusComp;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 10000;

	UPROPERTY(DefaultComponent)
	UPinballGlobalResetComponent GlobalResetComp;

	UPROPERTY(EditDefaultsOnly, Category = "Boss Target")
	TSubclassOf<APinballBossRocket> RocketClass;

	UPROPERTY(EditDefaultsOnly, Category = "Boss Target")
	TSubclassOf<UPinballBossTargetWidget> WidgetClass;

	UPROPERTY(EditAnywhere, Category = "Boss Target|Trigger")
	const bool bUsePlayerTrigger = true;

	UPROPERTY(EditAnywhere, Category = "Boss Target|Trigger")
	const bool bSnapPlayerTrigger = true;

	UPROPERTY(EditAnywhere, Category = "Boss Target|Trigger")
	const float TriggerDelay = 3.0;

	UPROPERTY(EditAnywhere, Category = "Boss Target|Trigger")
	const float TriggerRadius = 600;

	UPROPERTY(EditInstanceOnly, Category = "Boss Target|Countdown")
	const bool bImmediate = false;

	UPROPERTY(EditInstanceOnly, Category = "Boss Target|Countdown", Meta = (EditCondition = "!bImmediate"))
	const float DefaultCountdownDuration = 1.0;

	UPROPERTY(EditAnywhere, Category = "Boss Target|Explosion")
	const float AS_ExplosionRadius = 300;

	UPROPERTY(EditAnywhere, Category = "Boss Target|Explosion")
	const float AS_ExplosionImpulse = 1000;

	UPROPERTY(EditAnywhere, Category = "Boss Target|Explosion")
	const bool bCanHitIfPlayerLaunched = false;

	UPROPERTY(EditAnywhere, Category = "Boss Target|Explosion")
	const bool bKillPlayer = false;

	UPROPERTY(EditInstanceOnly, Category = "Boss Target|Explosion")
	const TArray<AHazeActor> ActorsToDestroy;

	UPROPERTY(EditInstanceOnly, Category = "Boss Target|Explosion")
	const TArray<APinballBossTarget> NextTargets;

	UPROPERTY(EditDefaultsOnly, Category = "Boss Target|Explosion")
	TSubclassOf<UDeathEffect> ExplosionDeathEffect;

	private APinballBoss Boss;
	private UPinballBossTargetWidget Widget;

	private EPinballBossTargetState CurrentState = EPinballBossTargetState::Idle;
	private float StartTime = -1;
	private float WaitingForTriggerDelay = -1;
	private float RandomDelay = -1;
	private float CountdownDuration = -1;
	private const float RocketLaunchDuration = 1;

	APinballBossRocket Rocket;
	FVector RocketInitialLocation;

	UPROPERTY(EditDefaultsOnly, Category = "Boss Target|Audio")
	UHazeAudioEvent LaserActivatedEvent;
	private UHazeAudioEmitter AudioEmitter;

#if !RELEASE
	private EPinballBossTargetState PreviousState;
#endif

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		PlayerTriggerComp.Shape.InitializeAsSphere(TriggerRadius);

		if (bSnapPlayerTrigger)
			PlayerTriggerComp.SetWorldLocation(FVector(0, PlayerTriggerComp.GetWorldLocation().Y, PlayerTriggerComp.GetWorldLocation().Z));

		ExplosionRadiusComp.Radius = AS_ExplosionRadius;
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorControlSide(Pinball::GetBallPlayer());

		if(bUsePlayerTrigger)
			PlayerTriggerComp.OnPlayerEnter.AddUFunction(this, n"OnPlayerEnter");
		else
			PlayerTriggerComp.DisableTrigger(this);

		Boss = APinballBoss::Get();

		FHazeAudioEmitterAttachmentParams EmitterParams;
		EmitterParams.Attachment = Boss.RootComp;
		EmitterParams.Owner = this;
		EmitterParams.Instigator = this;
		
#if TEST
		EmitterParams.EmitterName = FName(f"{GetName()}_LaserEmitter");
#endif

		AudioEmitter = Audio::GetPooledEmitter(EmitterParams);

		GlobalResetComp.PreActivateProgressPoint.AddUFunction(this, n"PreActivateProgressPoint");

#if !RELEASE
		const FTemporalLog TemporalLog = TEMPORAL_LOG(this).Section("Settings");
		TemporalLog.PersistentValue("bUsePlayerTrigger", bUsePlayerTrigger);
		TemporalLog.PersistentValue("bSnapPlayerTrigger", bSnapPlayerTrigger);
		TemporalLog.PersistentValue("TriggerDelay", TriggerDelay);
		TemporalLog.PersistentValue("TriggerRadius", TriggerRadius);
		TemporalLog.PersistentValue("AS_ExplosionRadius", AS_ExplosionRadius);
		TemporalLog.PersistentValue("AS_ExplosionImpulse", AS_ExplosionImpulse);
		TemporalLog.PersistentValue("bKillPlayer", bKillPlayer);
		TemporalLog.PersistentValue("bImmediate", bImmediate);
		TemporalLog.PersistentValue("ActorsToDestroy Count", ActorsToDestroy.Num());
		TemporalLog.PersistentValue("NextTargets Count", NextTargets.Num());
#endif
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		const EPinballBossTargetState NewState = GetState();

		if(CurrentState != NewState)
		{
			if(NewState == EPinballBossTargetState::Disabled)
			{
				// If we were disabled, just jump straight to disabled
				TransitionToState(CurrentState, EPinballBossTargetState::Disabled, false);
			}
			else
			{
				// We only change the state if the new state is further ahead than we are
				// In network, time can go backwards, meaning that the new state is lower than the current state, this is not valid unless disabled
				if(int(NewState) > int(CurrentState))
				{
					// If we were not disabled, we must transition through all the states in order to not skip any state
					for(int i = int(CurrentState); i < int(NewState); i++)
					{
						EPinballBossTargetState TransitionState = EPinballBossTargetState(i + 1);
						TransitionToState(CurrentState, TransitionState, false);
					}
					check(CurrentState == NewState);
				}
			}
		}

		switch(CurrentState)
		{
			case EPinballBossTargetState::Idle:
			case EPinballBossTargetState::WaitingForTriggerDelay:
			case EPinballBossTargetState::WaitingForRandomDelay:
				break;

			case EPinballBossTargetState::CountDownStarted:
			{
				// While the countdown is active, lower the scale of the target billboard
				const float CountdownStartTime = GetCountDownStartTime();
				const float CountdownEndTime = GetCountDownEndTime();
				const float Alpha = Math::GetPercentageBetweenClamped(CountdownStartTime, CountdownEndTime, Time::PredictedGlobalCrumbTrailTime);

				if(Rocket == nullptr)
					SpawnRocket();

				Widget.UpdateCountdown(Alpha);
				break;
			}

			case EPinballBossTargetState::RocketLaunched:
			{
				// While the rocket is launched, lerp it to the target
				const float RocketLaunchTime = GetRocketLaunchStartTime();
				const float RocketHitTime = GetRocketLaunchEndTime();
				const float Alpha = Math::GetPercentageBetweenClamped(RocketLaunchTime, RocketHitTime, Time::PredictedGlobalCrumbTrailTime);

				FVector Location = Math::Lerp(RocketInitialLocation, ActorLocation, Alpha);
				FQuat Rotation = FQuat::MakeFromX(ActorLocation - RocketInitialLocation);
				Rocket.SetActorTransform(FTransform(Rotation, Location));
				break;
			}

			case EPinballBossTargetState::RocketHit:
			case EPinballBossTargetState::Disabled:
				break;
		}

		if(IsLaserActiveInState(CurrentState))
		{
			LaserNiagaraComp.SetNiagaraVariableVec3("BeamStart", FVector(0, ActorLocation.Y, ActorLocation.Z));
			LaserNiagaraComp.SetNiagaraVariableVec3("BeamEnd", Boss.BP_GetLaserStartLocation());

			// Audio panning
			float X = 0;
			float Y = 0;
			FVector2D Previous = FVector2D::ZeroVector;
			if(Audio::GetScreenPositionRelativePanningValue(Boss.ActorLocation, Previous, X, Y))
				AudioEmitter.SetRTPC(Audio::Rtpc_SpeakerPanning_LR, X, 0.0);
		}

#if !RELEASE
		FTemporalLog TemporalLog = TEMPORAL_LOG(this).Section("Tick");
		TemporalLog.Value("CurrentState", CurrentState);
		TemporalLog.Value("PreviousState", PreviousState);

		TemporalLog.Value("PredictedGlobalCrumbTrailTime", Time::PredictedGlobalCrumbTrailTime);

		TemporalLog.Value("StartTime", StartTime);
		TemporalLog.Value("WaitingForPlayerTriggerDuration", WaitingForTriggerDelay);
		TemporalLog.Value("CountdownDuration", CountdownDuration);

		TemporalLog.Value("Rocket", Rocket);
		TemporalLog.Point("RocketInitialLocation", RocketInitialLocation);

		TemporalLog.Value("IsTargetVisibleInState", ShouldShowWidgetInState(CurrentState));
		TemporalLog.Value("IsLaserActiveInState", IsLaserActiveInState(CurrentState));
		PreviousState = CurrentState;
#endif
	}

	UFUNCTION()
	private void PreActivateProgressPoint()
	{
		if(CurrentState != EPinballBossTargetState::Idle)
		{
			TransitionToState(CurrentState, EPinballBossTargetState::Idle, true);
			CurrentState = EPinballBossTargetState::Idle;
		}
	}

	EPinballBossTargetState GetState() const
	{
		if(IsActorDisabled())
			return EPinballBossTargetState::Disabled;

		if(StartTime < 0)
			return EPinballBossTargetState::Idle;

		const float CurrentTime = Time::PredictedGlobalCrumbTrailTime;
		if(CurrentTime < GetWaitingForTriggerDelayEndTime())
		{
			return EPinballBossTargetState::WaitingForTriggerDelay;
		}
		else if(CurrentTime < GetWaitingForRandomDelayEndTime())
		{
			return EPinballBossTargetState::WaitingForRandomDelay;
		}
		else if(CurrentTime < GetCountDownEndTime())
		{
			return EPinballBossTargetState::CountDownStarted;
		}
		else if(CurrentTime < GetRocketLaunchEndTime())
		{
			return EPinballBossTargetState::RocketLaunched;
		}
		else
		{
			return EPinballBossTargetState::RocketHit;
		}
	}

	float GetWaitingForTriggerDelayEndTime() const
	{
		check(StartTime > 0);
		check(WaitingForTriggerDelay >= 0);
		return StartTime + WaitingForTriggerDelay;
	}

	float GetWaitingForRandomDelayEndTime() const
	{
		check(RandomDelay >= 0);
		return GetWaitingForTriggerDelayEndTime() + RandomDelay;
	}

	float GetCountDownStartTime() const
	{
		return GetWaitingForRandomDelayEndTime();
	}

	float GetCountDownEndTime() const
	{
		check(CountdownDuration >= 0);
		return GetCountDownStartTime() + CountdownDuration;
	}

	float GetRocketLaunchStartTime() const
	{
		return GetCountDownEndTime();
	}

	float GetRocketLaunchEndTime() const
	{
		check(RocketLaunchDuration >= 0);
		return GetRocketLaunchStartTime() + RocketLaunchDuration;
	}

	UFUNCTION()
	private void OnPlayerEnter(AHazePlayerCharacter Player)
	{
		if(!HasControl())
			return;

		// Only trigger in the idle state
		if(GetState() != EPinballBossTargetState::Idle)
			return;

		const float InTriggerTime = Time::PredictedGlobalCrumbTrailTime + Network::PingOneWaySeconds;
		const float InRandomDelay = CalculateRandomDelay();
		const float InCountdownDuration = CalculateCountdownDuration();

		NetTrigger(
			InTriggerTime,
			InRandomDelay,
			InCountdownDuration
		);
	}

	UFUNCTION(BlueprintCallable)
	void AS_StartCountdown(bool bInitial)
	{
		const float InStartCountdownTime = Time::PredictedGlobalCrumbTrailTime + Network::PingOneWaySeconds;
		const float InDuration = CalculateCountdownDuration();

		if(bInitial)
		{
			LocalStartCountdown(InStartCountdownTime, InDuration);
			return;
		}

		if(!HasControl())
			return;

		NetStartCountdown(
			InStartCountdownTime,
			InDuration
		);
	}

	UFUNCTION(BlueprintCallable)
	void AS_ActivateRocket(bool bInitial)
	{
		const float InLaunchTime = Time::PredictedGlobalCrumbTrailTime + Network::PingOneWaySeconds;

		if(bInitial)
		{
			LocalLaunchRocket(InLaunchTime);
			return;
		}

		if(!HasControl())
			return;

		NetLaunchRocket(InLaunchTime);
	}

	UFUNCTION(BlueprintCallable)
	void AS_Deactivate(bool bInitial)
	{
		if(bInitial)
		{
			LocalDeactivate(bInitial);
			return;
		}

		if(!HasControl())
			return;

		NetDeactivate();
	}

	private float CalculateRandomDelay() const
	{
		check(HasControl());
		return Math::RandRange(0, 0.75);
	}

	private float CalculateCountdownDuration() const
	{
		if(bImmediate)
			return 0;

		return DefaultCountdownDuration;
	}

	UFUNCTION(NetFunction)
	private void NetTrigger(float InTriggerTime, float InRandomDelay, float InCountdownDuration)
	{
		if(GetState() >= EPinballBossTargetState::WaitingForTriggerDelay)
			return;
		
		SetActorTickEnabled(true);
		StartTime = InTriggerTime;
		WaitingForTriggerDelay = TriggerDelay;
		RandomDelay = InRandomDelay;
		CountdownDuration = InCountdownDuration;
	}

	UFUNCTION(NetFunction)
	private void NetStartCountdown(float InStartCountdownTime, float InCountdownDuration)
	{
		LocalStartCountdown(InStartCountdownTime, InCountdownDuration);
	}

	private void LocalStartCountdown(float InStartCountdownTime, float InCountdownDuration)
	{
		if(GetState() >= EPinballBossTargetState::CountDownStarted)
			return;

		if(Rocket == nullptr)
			SpawnRocket();

		SetActorTickEnabled(true);
		StartTime = InStartCountdownTime;
		WaitingForTriggerDelay = 0;
		RandomDelay = 0;
		CountdownDuration = InCountdownDuration;
	}

	UFUNCTION(NetFunction)
	private void NetLaunchRocket(float InLaunchTime)
	{
		LocalLaunchRocket(InLaunchTime);
	}

	private void LocalLaunchRocket(float InLaunchTime)
	{
		if(GetState() >= EPinballBossTargetState::RocketLaunched)
			return;

		SetActorTickEnabled(true);
		StartTime = InLaunchTime;
		WaitingForTriggerDelay = 0;
		RandomDelay = 0;
		CountdownDuration = 0;
	}

	UFUNCTION(NetFunction)
	private void NetDeactivate()
	{
		LocalDeactivate(false);
	}

	private void LocalDeactivate(bool bInitial)
	{
		if(!bInitial)
		{
			if(GetState() >= EPinballBossTargetState::Disabled)
				return;
		}

		DisableDestroyedActors(bInitial);
		AddActorDisable(this);
	}

	void SpawnRocket()
	{


		RocketInitialLocation = Boss.RocketLauncherComp.WorldLocation;
		Rocket = SpawnActor(RocketClass, RocketInitialLocation);
		Rocket.AttachToComponent(Boss.MissileBoxRoot);
		Rocket.SetActorRelativeLocation(Boss.RocketLauncherComp.RelativeLocation);

		Boss.OnLaunchRocket.Broadcast();


	}

	void TransitionToState(EPinballBossTargetState OldState, EPinballBossTargetState NewState, bool bInitial)
	{
#if !RELEASE
		TEMPORAL_LOG(this).Event(f"Transition from {OldState:n} to {NewState:n}");
#endif
		check(CurrentState == OldState);

		if(!ensure(OldState != NewState))
			return;

		if(ShouldShowWidgetInState(NewState))
			ShowWidget();

		switch(NewState)
		{
			case EPinballBossTargetState::Idle:
				Reset();
				break;

			case EPinballBossTargetState::WaitingForTriggerDelay:
				break;
				
			case EPinballBossTargetState::WaitingForRandomDelay:
				break;

			case EPinballBossTargetState::CountDownStarted:
				OnCountdownStarted();
				break;

			case EPinballBossTargetState::RocketLaunched:
				OnRocketLaunched();
				break;

			case EPinballBossTargetState::RocketHit:
				OnRocketHit();
				break;

			case EPinballBossTargetState::Disabled:
				OnDeactivated(bInitial);
				break;
		}

		if(!ShouldShowWidgetInState(NewState))
			RemoveWidget();

		if(!IsLaserActiveInState(OldState) && IsLaserActiveInState(NewState))
		{
			ActivateLaser();
		}
		else if(IsLaserActiveInState(OldState) && !IsLaserActiveInState(NewState))
		{
			DeactivateLaser(NewState);
		}

		CurrentState = NewState;
	}

	private void Reset()
	{
		StartTime = -1;

		ResetDestroyedActors();
		RemoveActorDisable(this);

		if(Rocket != nullptr)
		{
			UPinballBossRocketEventHandler::Trigger_OnReset(Rocket);
			Rocket.DestroyActor();
			Rocket = nullptr;
		}
	}

	private void OnCountdownStarted()
	{
		Widget.OnCountdownStarted();
	}

	private void OnRocketLaunched()
	{
		if(Rocket == nullptr)
			SpawnRocket();

		Boss.OnRocketFired();

		LaserNiagaraComp.DeactivateImmediate();
		Widget.OnRocketLaunched();
		RocketInitialLocation = Rocket.ActorLocation;
		UPinballBossRocketEventHandler::Trigger_OnLaunched(Rocket);
		Rocket.DetachFromActor(EDetachmentRule::KeepWorld,EDetachmentRule::KeepWorld,EDetachmentRule::KeepWorld);
	}

	private void OnRocketHit()
	{
		if(Rocket != nullptr)
		{
			Rocket.SetActorLocation(ActorLocation);
			UPinballBossRocketEventHandler::Trigger_OnHit(Rocket);

			Rocket.DestroyActor();
			Rocket = nullptr;
		}

		DisableDestroyedActors(false);

		for(auto NextTarget : NextTargets)
		{
			NextTarget.AS_StartCountdown(false);
		}

		auto BallPlayer = Pinball::GetBallPlayer();

		if(CanHitPlayer(BallPlayer) && ExplosionRadiusComp.IsOverlappingPlayer(BallPlayer))
		{
			if(bKillPlayer)
			{
				BallPlayer.KillPlayer(DeathEffect = ExplosionDeathEffect);
			}
			else
			{
				FVector Impulse = BallPlayer.GetActorLocation() - GetActorLocation();
				Impulse.Normalize();
				Impulse *= AS_ExplosionImpulse;
				Impulse.Z = 1000;
				BallPlayer.AddMovementImpulse(Impulse);
			}
		}

		AudioEmitter.StopEvent(LaserActivatedEvent);

		Widget.OnRocketHit();

		AddActorDisable(this);
	}

	private bool CanHitPlayer(const AHazePlayerCharacter Player) const
	{
		if(!bCanHitIfPlayerLaunched)
		{
			const auto LaunchedComp = UPinballMagnetDroneLaunchedComponent::Get(Player);
			if(LaunchedComp.bIsLaunched)
				return false;
		}

		const auto RailComp = UPinballMagnetDroneRailComponent::Get(Player);
		if(RailComp.IsInAnyRail())
			return false;

		return true;
	}

	private void OnDeactivated(bool bInitial)
	{
		DisableDestroyedActors(bInitial);
	}

	private bool ShouldShowWidgetInState(EPinballBossTargetState InState) const
	{
		switch(InState)
		{
			case EPinballBossTargetState::WaitingForRandomDelay:
				return true;

			case EPinballBossTargetState::CountDownStarted:
				return true;

			case EPinballBossTargetState::RocketLaunched:
				return true;

			default:
				return false;
		}
	}

	private void ShowWidget()
	{
		if(Widget != nullptr)
			return;

		Widget = SceneView::FullScreenPlayer.AddWidget(WidgetClass);
		Widget.AttachWidgetToActor(this);
		Widget.BossTarget = this;
	}

	private void RemoveWidget()
	{
		if(Widget == nullptr)
			return;

		SceneView::FullScreenPlayer.RemoveWidget(Widget);
		Widget = nullptr;
	}

	private bool IsLaserActiveInState(EPinballBossTargetState InState) const
	{
		switch(InState)
		{
			case EPinballBossTargetState::WaitingForRandomDelay:
				return true;

			case EPinballBossTargetState::CountDownStarted:
				return true;

			default:
				return false;
		}
	}

	private void ActivateLaser()
	{
		Boss.ActivateLaser();
		LaserNiagaraComp.Activate(true);

		if(LaserActivatedEvent != nullptr)
			AudioEmitter.PostEvent(LaserActivatedEvent);
	}

	private void DeactivateLaser(EPinballBossTargetState NewState)
	{
		Boss.DeactivateLaser();

		if(LaserActivatedEvent != nullptr)
		{
			if(NewState == EPinballBossTargetState::RocketLaunched)
			{
				AudioEmitter.StopEvent(LaserActivatedEvent, 500);
			}
			else
			{
				AudioEmitter.StopEvent(LaserActivatedEvent);
			}
		}
	}

	private void DisableDestroyedActors(bool bInitial)
	{
		TArray<UHazeSplineComponent> Splines;
		TArray<AHazeActor> Actors;
		for(auto Actor : ActorsToDestroy)
		{
			APropLine PropLine = Cast<APropLine>(Actor);
			if (PropLine != nullptr && PropLine.bGameplaySpline)
			{
				UHazeSplineComponent SplineComp = UHazeSplineComponent::Get(PropLine);
				if (SplineComp != nullptr)
					Splines.Add(SplineComp);
			}
			else
				Actors.Add(Actor); 
		}

		if(!bInitial)
		{
			FPinballTargetEventHandlerParams Params;
			Params.Splines = Splines;
			Params.Actors = Actors;
			UPinballTargetEventHandler::Trigger_EventSegmentDestroyed(this, Params);
		}

		for(auto Actor : ActorsToDestroy)
		{
			if(!IsValid(Actor))
				continue;

			Actor.AddActorDisable(this);

			TArray<AActor> AttachedActors;
			Actor.GetAttachedActors(AttachedActors, bRecursivelyIncludeAttachedActors = true);
			for(auto AttachedActor : AttachedActors)
			{
				if(!IsValid(AttachedActor))
					continue;

				AttachedActor.AddActorDisable(this);
			}
		}
	}

	private void ResetDestroyedActors()
	{
		for(auto Actor : ActorsToDestroy)
		{
			if(!IsValid(Actor))
				continue;

			Actor.RemoveActorDisable(this);
			Actor.SetActorHiddenInGame(false);
			Actor.SetActorEnableCollision(true);

			TArray<AActor> AttachedActors;
			Actor.GetAttachedActors(AttachedActors, bRecursivelyIncludeAttachedActors = true);
			for(auto AttachedActor : AttachedActors)
			{
				if(!IsValid(AttachedActor))
					continue;

				AttachedActor.AddActorDisable(this);
				AttachedActor.SetActorHiddenInGame(false);
				AttachedActor.SetActorEnableCollision(true);
			}
		}
	}
};
