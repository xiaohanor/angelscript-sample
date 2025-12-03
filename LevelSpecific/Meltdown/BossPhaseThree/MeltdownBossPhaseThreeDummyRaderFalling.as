event void FOnObstacleHitVO();

class AMeltdownBossPhaseThreeDummyRaderFalling : AHazeCharacter
{
	default PrimaryActorTick.TickGroup = ETickingGroup::TG_HazeInput;
	default PrimaryActorTick.EndTickGroup = ETickingGroup::TG_HazeInput;

	default CapsuleComponent.SetCollisionEnabled(ECollisionEnabled::NoCollision);
	
	UPROPERTY(DefaultComponent, Attach = CharacterMesh0)
	UCapsuleComponent ObstacleReactCapsule;

	UPROPERTY(DefaultComponent)
	UMeltdownGlitchShootingResponseComponent GlitchResponseComp;
	UPROPERTY(DefaultComponent)
	UMeltdownBossHealthComponent HealthComponent;
	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComp;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilityClasses.Add(UMeltdownBossPhaseThreeDummyRaderAnimationCapability);

	UPROPERTY()
	FOnHitByGlitch GlitchHit();

	UPROPERTY()
	FOnObstacleHitVO OnObstacleHitReaction;

	bool bMashActive = false;
	FOnButtonMashCompleted ActiveMashCompleted;
	AHazeLevelSequenceActor MashSequence;

	FOnMeltdownBossHealthThreshold ThresholdReached;
	float HealthThreshold = -1.0;
	bool bThresholdActive = false;

	uint ObstacleHitFrame = 0;
	ERaderFallingHitReactType ObstacleHitType;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		GlitchResponseComp.OnGlitchHit.AddUFunction(this, n"OnGlitchHit");
	}

	UFUNCTION(BlueprintPure)
	float GetBossHealth()
	{
		return HealthComponent.CurrentHealth;
	}

	UFUNCTION()
	private void OnGlitchHit(FMeltdownGlitchImpact Impact)
	{
		auto Settings = UMeltdownGlitchShootingSettings::GetSettings(Impact.FiringPlayer);
		HealthComponent.Damage(Impact.Damage);
		HitReactWithParams(Impact);
		GlitchHit.Broadcast();
	}

	UFUNCTION(BlueprintEvent)
	void HitReactWithParams(FMeltdownGlitchImpact Impact)
	{
	}

	void ReactToObstacleHit(ERaderFallingHitReactType ReactType)
	{
		ObstacleHitFrame = GFrameNumber;
		ObstacleHitType = ReactType;
		OnObstacleHitReaction.Broadcast();
	}

	UFUNCTION()
	void SetCurrentBossHealth(float Health)
	{
		HealthComponent.SetCurrentHealth(Health);
	}

	UFUNCTION(Meta = (UseExecPins))
	void SetHealthThreshold(float Threshold, FOnMeltdownBossHealthThreshold OnThresholdReached)
	{
		HealthThreshold = Threshold;
		ThresholdReached = OnThresholdReached;
		bThresholdActive = true;
	}


	UFUNCTION()
	void StartGlitchButtonMash(
		AHazeLevelSequenceActor ScrubSequence,
		FButtonMashSettings Settings,
		FOnButtonMashCompleted OnCompleted)
	{
		bMashActive = true;
		MashSequence = ScrubSequence;
		MashSequence.SequencePlayer.Pause();
		ActiveMashCompleted = OnCompleted;

		ButtonMash::StartDoubleButtonMash(
			Settings, Settings, this,
			FOnButtonMashCompleted(this, n"OnCompleteMash")
		);
	}

	UFUNCTION()
	private void OnCompleteMash()
	{
		bMashActive = false;
		MashSequence.SequencePlayer.Stop();
		ActiveMashCompleted.ExecuteIfBound();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bMashActive && IsValid(MashSequence))
		{
			float Progress = 0.0;
			Progress += Game::Mio.GetButtonMashProgress(this) * 0.5;
			Progress += Game::Zoe.GetButtonMashProgress(this) * 0.5;

			FMovieSceneSequencePlaybackParams PlaybackParams;
			PlaybackParams.Time = MashSequence.GetDurationAsSeconds() * Progress;
			PlaybackParams.PositionType = EMovieScenePositionType::Time;
			PlaybackParams.UpdateMethod = EUpdatePositionMethod::Scrub;
			MashSequence.SequencePlayer.SetPlaybackPosition(PlaybackParams);
		}

		if (HealthThreshold >= 0 && GetBossHealth() <= HealthThreshold && bThresholdActive && HasControl())
		{
			NetReachedThreshold();
		}

		FVector NewActorLocation = GetActorLocation();
		auto SkydiveComp = UMeltdownSkydiveComponent::Get(Game::Mio);
		if (SkydiveComp.IsSkydiving())
			SkydiveComp.CurrentSkydiveHeight -= SkydiveComp.Settings.FallingVelocity * DeltaSeconds;
		NewActorLocation.Z = SkydiveComp.CurrentSkydiveHeight;
		UMeltdownSkydiveComponent::Get(Game::Zoe).CurrentSkydiveHeight = SkydiveComp.CurrentSkydiveHeight;

		SetActorLocation(NewActorLocation);
	}

	UFUNCTION(NetFunction)
	void NetReachedThreshold()
	{
		bThresholdActive = false;

		for (auto Player : Game::Players)
		{
			auto GlitchComp = UMeltdownGlitchShootingUserComponent::Get(Player);
			GlitchComp.DeactivateGlitchShooting();
		}

		ThresholdReached.ExecuteIfBound();
	}

};

class UMeltdownPhaseThreeFallingRaderReactionTrigger : UBoxComponent
{
	default PrimaryComponentTick.TickGroup = ETickingGroup::TG_HazeInput;
	default PrimaryComponentTick.EndTickGroup = ETickingGroup::TG_HazeInput;
	default PrimaryComponentTick.TickInterval = 0.1;

	default bGenerateOverlapEvents = false;
	default SetCollisionEnabled(ECollisionEnabled::NoCollision);

	UPROPERTY(EditAnywhere, Category = "Rader Trigger")
	ERaderFallingHitReactType ReactType;

	float LastHit = 0.0;
	AMeltdownBossPhaseThreeDummyRaderFalling Rader;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (IsValid(Rader))
		{
			if (Time::GetGameTimeSince(LastHit) > 1.0)
			{
				if (Overlap::QueryShapeOverlap(
					FCollisionShape::MakeBox(ScaledBoxExtent),
					WorldTransform,
					Rader.ObstacleReactCapsule.GetCollisionShape(),
					Rader.ObstacleReactCapsule.WorldTransform
				))
				{
					LastHit = Time::GameTimeSeconds;
					Rader.ReactToObstacleHit(ReactType);
				}
			}
		}
		else
		{
			Rader = TListedActors<AMeltdownBossPhaseThreeDummyRaderFalling>().GetSingle();
		}
	}
}

class UMeltdownBossPhaseThreeDummyRaderAnimationCapability : UHazeCapability
{
	default TickGroup = EHazeTickGroup::Movement;
	AMeltdownBossPhaseThreeDummyRaderFalling Rader;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Rader = Cast<AMeltdownBossPhaseThreeDummyRaderFalling>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (Rader.Mesh.CanRequestLocomotion())
			Rader.Mesh.RequestLocomotion(n"FinalFall", this);
	}
}