class ADentistBossToothPasteGlob : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent)
	UHazeMovablePlayerTriggerComponent PlayerTriggerComp;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedActorComp;

	USceneComponent Target;
	FVector CurrentVelocity;
	FVector InitialScale;	
	const FVector FiredScale = FVector(0.01, 0.01, 0.01); 
	bool bIsMoving = false;
	bool bActive = false;
	bool bTargetIsInner = false;
	float TimeLastLobbed = -MAX_flt;

	TPerPlayer<bool> IsStuck;
	TPerPlayer<bool> AddedAsDrillTarget;
	TPerPlayer<float> TimeLastStuck;

	ADentistBoss Dentist;
	ADentistBossToolDrill Drill;
	UDentistBossTargetComponent TargetComp;
	UDentistBossSettings Settings;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Drill = TListedActors<ADentistBossToolDrill>().Single;
		InitialScale = ActorScale3D;

		PlayerTriggerComp.OnPlayerEnter.AddUFunction(this, n"OnPlayerEnteredTrigger");

		Dentist = TListedActors<ADentistBoss>().Single;
		if(Dentist == nullptr)
			return;
		TargetComp = UDentistBossTargetComponent::GetOrCreate(Dentist);
		Settings = UDentistBossSettings::GetSettings(Dentist);

		AddActorDisable(Dentist);
	}

	UFUNCTION(CrumbFunction, NotBlueprintCallable)
	void CrumbGetLobbed(USceneComponent Start, USceneComponent InTarget, bool bInnerRing)
	{
		DetachFromActor();
		RemoveActorDisable(Dentist);
		SetActorLocation(Start.WorldLocation);
		SetActorScale3D(FiredScale);
		
		Target = InTarget;

		bTargetIsInner = bInnerRing;

		CurrentVelocity = Trajectory::CalculateVelocityForPathWithHorizontalSpeed(Start.WorldLocation, Target.WorldLocation, Settings.ToothPasteGlobGravityAmount, Settings.ToothPasteGlobHorizontalSpeed);
		bIsMoving = true;
		bActive = true;

		TimeLastLobbed = Time::GameTimeSeconds;

		FDentistBossEffectHandlerOnToothPasteShotParams EffectParams;
		EffectParams.ToothPasteMuzzle = Start;
		UDentistBossEffectHandler::Trigger_OnToothPasteShot(Dentist, EffectParams);
	}

	UFUNCTION()
	private void OnPlayerEnteredTrigger(AHazePlayerCharacter Player)
	{
		if(bIsMoving)
			return;

		GetStuck(Player);
	}	

	private void GetStuck(AHazePlayerCharacter Player)
	{
		if(IsStuck[Player])
			return;

		IsStuck[Player] = true;
		TimeLastStuck[Player] = Time::GameTimeSeconds;

		if(Settings.bDrillPlayersStuckInToothPaste)
		{
			TargetComp.DrillTargets.AddUnique(Player);
			AddedAsDrillTarget[Player] = true;
			TargetComp.DrillTelegraphDelay = Settings.TimeStuckInToothPasteGlobBeforeDrill;
			Drill.OnHitPlayer.AddUFunction(this, n"OnDrillHitPlayer");
			Drill.OnStopped.AddUFunction(this, n"OnDrillStopped");
		}

		Player.PlayForceFeedback(ForceFeedback::Default_Medium_Short, this);

		if(Player.IsMio())
			Player.StartStickWiggle(Settings.ToothPasteGlobStickWiggleSettings, this, FOnStickWiggleCompleted(this, n"OnMioCompletedStickWiggle"));
		else
			Player.StartStickWiggle(Settings.ToothPasteGlobStickWiggleSettings, this, FOnStickWiggleCompleted(this, n"OnZoeCompletedStickWiggle"));
	}

	UFUNCTION()
	private void OnDrillHitPlayer(AHazePlayerCharacter Player)
	{
		Player.StopStickWiggle(this);
		AddedAsDrillTarget[Player] = false;

		Drill.OnHitPlayer.Unbind(this, n"OnDrillHitPlayer");
	}

	UFUNCTION()
	private void OnDrillStopped(AHazePlayerCharacter Player)
	{
		GetRemoved();

		Drill.OnStopped.Unbind(this, n"OnDrillStopped");
	}

	UFUNCTION()
	private void OnMioCompletedStickWiggle()
	{
		IsStuck[Game::Mio] = false;
		GetRemoved();
		TargetComp.DrillTargets.RemoveSingleSwap(Game::Mio);
		AddedAsDrillTarget[Game::Mio] = false;
	}

	UFUNCTION()
	private void OnZoeCompletedStickWiggle()
	{
		IsStuck[Game::Zoe] = false;
		GetRemoved();
		TargetComp.DrillTargets.RemoveSingleSwap(Game::Zoe);
		AddedAsDrillTarget[Game::Zoe] = false;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(Dentist == nullptr)
		{
			Dentist = TListedActors<ADentistBoss>().Single;
			if(Dentist == nullptr)
				return;
			TargetComp = UDentistBossTargetComponent::GetOrCreate(Dentist);
			Settings = UDentistBossSettings::GetSettings(Dentist);
		}

		if(bIsMoving)
		{
			CurrentVelocity += FVector::DownVector * Settings.ToothPasteGlobGravityAmount * DeltaSeconds;
			FVector Delta = CurrentVelocity * DeltaSeconds;
			AddActorWorldOffset(Delta);

			if(ActorLocation.Z < Target.WorldLocation.Z)
				Land();
		}

		float ScaleUpAlpha = Time::GetGameTimeSince(TimeLastLobbed) / Settings.ToothPasteScaleUpTime;
		if(ScaleUpAlpha < 1.0)
			ScaleUp(ScaleUpAlpha);

		for(auto Player : Game::Players)
		{
			if(!IsStuck[Player])
				continue;

			MovePlayerTowardsCenter(Player, DeltaSeconds);
		}
	}

	void Land()
	{
		bIsMoving = false;

		FVector NewActorLocation = ActorLocation;
		NewActorLocation.Z = Target.WorldLocation.Z;
		SetActorLocation(NewActorLocation);

		if(bTargetIsInner)
			AttachToComponent(Dentist.Cake.InnerCakeRoot, AttachmentRule = EAttachmentRule::KeepWorld);
		else
			AttachToComponent(Dentist.Cake.OuterCakeRoot, AttachmentRule = EAttachmentRule::KeepWorld);

		for(auto Player : Game::Players)
		{
			if(PlayerTriggerComp.IsPlayerInTrigger(Player))
				GetStuck(Player);
		}

		FDentistBossEffectHandlerOnToothPasteLandedParams LandParams;
		LandParams.LandLocation = ActorLocation;
		UDentistBossEffectHandler::Trigger_OnToothPasteLanded(Dentist, LandParams);
	}

	void GetRemoved()
	{
		for(auto Player : Game::Players)
		{
			if(!IsStuck[Player])
				continue;

			Player.StopStickWiggle(this);
			IsStuck[Player] = false;
			if(AddedAsDrillTarget[Player])
			{
				TargetComp.DrillTargets.RemoveSingleSwap(Player);
				AddedAsDrillTarget[Player] = false;
			}

		}

		Dentist.Cake.ReturnGlobTarget(Target);
		Dentist.ToothPasteGetDespawned(this);
		bActive = false;
	}

	void MovePlayerTowardsCenter(AHazePlayerCharacter Player, float DeltaTime)
	{
		Player.ActorLocation = Math::VInterpTo(Player.ActorLocation, ActorLocation, DeltaTime, Settings.ToothPasteGlobSuckInPlayerSpeed);
	}

	void ScaleUp(float ScaleUpAlpha)
	{
		float ClampedAlpha = Math::Saturate(ScaleUpAlpha);
		FVector NewScale = Math::Lerp(FiredScale, InitialScale, ClampedAlpha);
		SetActorScale3D(NewScale);
	}
};