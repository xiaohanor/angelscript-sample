class ASummitRollingBellows : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent BaseMeshComp;

	UPROPERTY(DefaultComponent)
	USceneComponent WindReleaseLocation;

	UPROPERTY(DefaultComponent)
	UFauxPhysicsTranslateComponent TranslateComp;
	default TranslateComp.bConstrainX = true;
	default TranslateComp.MaxX = 0.0;
	default TranslateComp.MinX = -1000.0;
	default TranslateComp.bConstrainY = true;
	default TranslateComp.bConstrainZ = true;
	default TranslateComp.ConstrainBounce = 0.2;
	default TranslateComp.SpringStrength = 20.0;

	UPROPERTY(DefaultComponent, Attach = TranslateComp)
	UStaticMeshComponent RollHitMesh;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent BellowsMesh;

	UPROPERTY(DefaultComponent, Attach = RollHitMesh)
	UTeenDragonTailAttackResponseComponent ResponseComp;
	default ResponseComp.bIsPrimitiveParentExclusive = true;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 20000.0;

	UPROPERTY(DefaultComponent, Attach = WindReleaseLocation)
	UHazeMovablePlayerTriggerComponent WindVolume;
	default WindVolume.TriggeredByPlayers = EHazeSelectPlayer::Mio;

#if EDITOR
	UPROPERTY(DefaultComponent)
	USummitRollingBellowsDummyComponent DummyComp;
#endif

	UPROPERTY(EditAnywhere, Category = "Setup")
	UNiagaraSystem WindEffect;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float BellowsMoveAmount = 500.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float TargetExtraHeight = 4000.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float WindBlowDuration = 1.5;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float ImpulseApplyDuration = 0.4;

	UPROPERTY(EditAnywhere, Category = "Settings")
	bool bShootConstantWind = false;

	bool bWindIsBlowing = false;
	float WindActivatedTime = 0.0; 

	TPerPlayer<bool> HasAppliedImpulse;
	TPerPlayer<bool> IsInVolume;
	TPerPlayer<FVector> InitialImpulse;
	TPerPlayer<FVector> ImpulseRemainingToApply;
	TPerPlayer<float> LastTimeStartedApplyingImpulse;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{	
		ResponseComp.OnHitByRoll.AddUFunction(this, n"OnHitByRoll");

		WindVolume.OnPlayerEnter.AddUFunction(this, n"OnPlayerEnteredWind");
		WindVolume.OnPlayerLeave.AddUFunction(this, n"OnPlayerExitedWind");

		if(bShootConstantWind)
			StartWind();
	}

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		TranslateComp.MinX = 0.0;
		TranslateComp.MaxX = BellowsMoveAmount;

		FVector RelativeLocation = RollHitMesh.RelativeLocation;
		RelativeLocation.X = -(BellowsMoveAmount + 50);
		RollHitMesh.RelativeLocation = RelativeLocation;

		// Scale up to hit mesh
		FVector BellowsScale = BellowsMesh.WorldScale;
		BellowsScale.Z = (BellowsMoveAmount) * 0.01;
		BellowsScale.Z = Math::Max(0.001, BellowsScale.Z);
		BellowsMesh.SetWorldScale3D(BellowsScale);

		FVector HalfwayToMaxWindHeight = WindReleaseLocation.WorldLocation + WindReleaseLocation.UpVector * TargetExtraHeight * 0.5;
		WindVolume.WorldLocation = HalfwayToMaxWindHeight;
		WindVolume.Shape.BoxExtents.Z = (TargetExtraHeight * 0.5) / WindVolume.WorldScale.Z;
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnHitByRoll(FRollParams Params)
	{
		if(Params.RollDirection.DotProduct(TranslateComp.ForwardVector) < 0)
			return;

		FVector Impulse = Params.RollDirection * Params.SpeedTowardsImpact;
		FauxPhysics::ApplyFauxImpulseToActorAt(this, Params.HitLocation, Impulse);

		StartWind();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		ScaleBellows();

		if(bWindIsBlowing)
		{
			for(auto Player : Game::Players)
			{
				if(IsInVolume[Player]
				&& !HasAppliedImpulse[Player])
					ApplyWindToPlayer(Player);

				if(Time::GetGameTimeSince(LastTimeStartedApplyingImpulse[Player]) < ImpulseApplyDuration)
					ApplyImpulse(Player, DeltaSeconds);
			}

			if(WindShouldStop())
				StopWind();
		}
	}

	private void ScaleBellows()
	{
		FVector AlphaBetweenConstraints = TranslateComp.GetCurrentAlphaBetweenConstraints();
		FVector BellowsScale = BellowsMesh.WorldScale;
		BellowsScale.Z = (BellowsMoveAmount * (AlphaBetweenConstraints.X + 1.0) * 0.01);
		BellowsScale.Z = Math::Max(0.001, BellowsScale.Z);
		BellowsMesh.SetWorldScale3D(BellowsScale);

		TEMPORAL_LOG(this)
			.Value("Alpha Between Constraints", AlphaBetweenConstraints)
		;
	}

	void StartWind()
	{
		bWindIsBlowing = true;
		WindActivatedTime = Time::GameTimeSeconds;

		for(auto Player : Game::Players)
		{
			if(IsInVolume[Player])
				ApplyWindToPlayer(Player);
		}

		Niagara::SpawnOneShotNiagaraSystemAtLocation(WindEffect, WindReleaseLocation.WorldLocation, WindReleaseLocation.WorldRotation);
	}

	void StopWind()
	{
		bWindIsBlowing = false;
		for(auto Player : Game::Players)
			HasAppliedImpulse[Player] = false;

		if(bShootConstantWind)
			StartWind();
	}

	bool WindShouldStop() const
	{
		return Time::GetGameTimeSince(WindActivatedTime) >= WindBlowDuration;
	}

	private void ApplyWindToPlayer(AHazePlayerCharacter Player)
	{
		if(HasAppliedImpulse[Player])
			return;
	
		float GravityMagnitude = 0.0;
		float TerminalVelocity = 0.0;

		auto GravitySettings = UMovementGravitySettings::GetSettings(Player);
		auto GlideComp = UTeenDragonAirGlideComponent::Get(Player);
		if(GlideComp != nullptr
		&& (GlideComp.bIsAirGliding || GlideComp.bInAirCurrent))
		{
			GravityMagnitude = GravitySettings.GravityAmount * GravitySettings.GravityScale;
			TerminalVelocity = GravitySettings.TerminalVelocity;
		}
		else
		{
			auto GlideSettings = UTeenDragonAirGlideSettings::GetSettings(Player);	
			GravityMagnitude = 2025.0;
			TerminalVelocity = GlideSettings.GlideMaxVerticalSpeed;
		}

		FVector StartLocation = Player.ActorLocation;
		FVector TargetLocation = StartLocation + FVector::ForwardVector * 500;
		TargetLocation.Z = WindReleaseLocation.WorldLocation.Z + TargetExtraHeight;
		FVector Impulse = Trajectory::CalculateVelocityForPathWithHeight(StartLocation, TargetLocation, GravityMagnitude, 0.0, TerminalVelocity);
		Impulse = Impulse.ConstrainToDirection(WindReleaseLocation.UpVector);
		FVector PlayerVelocityTowardsImpulse = Player.ActorVelocity.ConstrainToDirection(WindReleaseLocation.UpVector);
		Impulse -= PlayerVelocityTowardsImpulse;

		InitialImpulse[Player] = Impulse;
		ImpulseRemainingToApply[Player] = Impulse;
		LastTimeStartedApplyingImpulse[Player] = Time::GameTimeSeconds;

		HasAppliedImpulse[Player] = true;
	}

	private void ApplyImpulse(AHazePlayerCharacter Player, float DeltaTime)
	{
		float ImpulseApplicationSpeed = InitialImpulse[Player].Size() / ImpulseApplyDuration;
		FVector ImpulseDir = InitialImpulse[Player].GetSafeNormal();
		FVector ImpulseToApply = ImpulseDir * ImpulseApplicationSpeed * DeltaTime;
		Player.AddMovementImpulse(ImpulseToApply);
		ImpulseRemainingToApply[Player] -= ImpulseToApply;
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnPlayerEnteredWind(AHazePlayerCharacter Player)
	{
		IsInVolume[Player] = true;
		if(bWindIsBlowing)
			ApplyWindToPlayer(Player);
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnPlayerExitedWind(AHazePlayerCharacter Player)
	{
		IsInVolume[Player] = false;
	}
};

#if EDITOR
class USummitRollingBellowsDummyComponent : UActorComponent {};
class USummitRollingBellowsVisualizerComponent : UHazeScriptComponentVisualizer
{
	default VisualizedClass = USummitRollingBellowsDummyComponent;

	FVector SimulatedLocation;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto Comp = Cast<USummitRollingBellowsDummyComponent>(Component);
		if(Comp == nullptr)
			return;
		auto Bellows = Cast<ASummitRollingBellows>(Comp.Owner);
		if(Bellows == nullptr)
			return;
		
		float WindTriggerRadius = Bellows.WindVolume.Shape.BoxExtents.X;
		FVector TargetHeightLocation = Bellows.WindReleaseLocation.WorldLocation + Bellows.WindReleaseLocation.UpVector * Bellows.TargetExtraHeight;
		DrawSolidBox(this, TargetHeightLocation, FQuat::MakeFromZ(Bellows.WindReleaseLocation.UpVector), FVector(WindTriggerRadius, WindTriggerRadius, 1), FLinearColor::LucBlue , 1.0);
	}
}
#endif