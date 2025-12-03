class AMeltdownBossPhaseOneLineAttack : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UEditorBillboardComponent Billboard;
#endif

	UPROPERTY(DefaultComponent)
	UMeltdownBossCubeGridDisplacementComponent TelegraphDisplacement;
	default TelegraphDisplacement.Type = EMeltdownBossCubeGridDisplacementType::Line;
	default TelegraphDisplacement.bInfiniteHeight = true;

	UPROPERTY(DefaultComponent)
	UMeltdownBossCubeGridDisplacementComponent ChasmDisplacement;
	default ChasmDisplacement.Type = EMeltdownBossCubeGridDisplacementType::Line;
	default ChasmDisplacement.bInfiniteHeight = true;
	default ChasmDisplacement.bModifyCubeGridCollision = true;

	UPROPERTY(DefaultComponent, NotEditable)
	UMeltdownBossCubeGridDisplacementComponent AttackDisplacement;
	default AttackDisplacement.Type = EMeltdownBossCubeGridDisplacementType::None;
	default AttackDisplacement.bInfiniteHeight = true;

	UPROPERTY(DefaultComponent)
	UNiagaraComponent PulseTravelVFX;
	default PulseTravelVFX.bAutoActivate = false;

	UPROPERTY(EditAnywhere)
	float TelegraphTravelDuration = 0.2;

	UPROPERTY(EditAnywhere)
	float TelegraphDuration = 1.0;

	UPROPERTY(EditAnywhere)
	float AttackTravelDuration = 0.3;

	UPROPERTY(EditAnywhere, Meta = (EditCondition = "bFillEntireLine", EditConditionHides))
	float AttackDuration = 1.0;

	UPROPERTY(EditAnywhere)
	float FadeOutDelay = 2.0;

	UPROPERTY(EditAnywhere)
	float FadeOutDuration = 0.2;

	UPROPERTY(EditAnywhere)
	float Width = 100.0;

	UPROPERTY(EditAnywhere, Meta = (MakeEditWidget))
	FVector LineEnd = FVector(500.0, 0.0, 0.0);

	UPROPERTY(EditAnywhere)
	FVector Displacement = FVector(0.0, 0.0, 200.0);

	UPROPERTY(EditAnywhere)
	FVector ChasmDisplacementAmount = FVector(0.0, 0.0, -500.0);

	UPROPERTY(EditAnywhere)
	bool bFillEntireLine = false;

	UPROPERTY(EditAnywhere)
	bool bCreateChasm = true;

	UPROPERTY(EditAnywhere, Meta = (EditCondition = "!bFillEntireLine", EditConditionHides))
	float KillBumpLength = 200.0;

	UPROPERTY(EditAnywhere)
	bool bPreviewInEditor = true;

	UPROPERTY(EditAnywhere)
	TSubclassOf<UDamageEffect> LineDeath;

	bool bTriggered = false;
	float Timer = 0.0;

	AHazePlayerCharacter TrackPlayer;
	float TrackPlayerUntilTime = 0.0;

	TPerPlayer<float> PlayerTemporaryIgnoresUntil;

	default PrimaryActorTick.bStartWithTickEnabled = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TelegraphDisplacement.DeactivateDisplacement();
		AttackDisplacement.DeactivateDisplacement();
		ChasmDisplacement.DeactivateDisplacement();
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		for (auto Player : Game::Players)
		{
			if (PlayerTemporaryIgnoresUntil[Player] != 0)
			{
				auto MoveComp = UPlayerMovementComponent::Get(Player);
				MoveComp.RemoveMovementIgnoresActor(this);
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		TelegraphDisplacement.Type = EMeltdownBossCubeGridDisplacementType::Line;
		TelegraphDisplacement.LineEnd = LineEnd;
		TelegraphDisplacement.ThresholdDistance = Width;
		TelegraphDisplacement.LerpDistance = Width;
		TelegraphDisplacement.Displacement = Displacement;
		TelegraphDisplacement.bPreviewInEditor = bPreviewInEditor;
	}

	UFUNCTION()
	void HomeAttackOnPlayer(AHazePlayerCharacter Player, float TrackDuration = 0.0)
	{
		UpdatePlayerTracking(Player);

		if (TrackDuration > 0.0)
		{
			TrackPlayer = Player;
			TrackPlayerUntilTime = Time::GameTimeSeconds + TrackDuration;
		}
		else
		{
			TrackPlayer = nullptr;
		}
	}

	void UpdatePlayerTracking(AHazePlayerCharacter Player)
	{
		FVector WorldLineStart = ActorLocation;
		FVector WorldLineEnd = ActorTransform.TransformPosition(LineEnd);

		float LineLength = WorldLineEnd.Distance(WorldLineStart);
		FVector Direction = (Player.ActorLocation - WorldLineStart).GetSafeNormal2D();

		WorldLineEnd = WorldLineStart + Direction * LineLength;
		LineEnd = ActorTransform.InverseTransformPosition(WorldLineEnd);
	}

	UFUNCTION(DevFunction)
	void TriggerAttack()
	{
		bTriggered = true;
		Timer = 0.0;

		UMeltdownBossPhaseOneLineAttackEffectHandler::Trigger_AttackTriggered(this);

		SetActorTickEnabled(true);
	}

	void CheckKillPlayers()
	{
		// Check for players that are hit by the attack
		for (auto Player : Game::Players)
		{
			if (Player.IsPlayerDead())
				continue;

			FVector PlayerLocation = Player.ActorLocation;
			FVector WorldLineStart = AttackDisplacement.WorldLocation;
			FVector WorldLineEnd = AttackDisplacement.WorldTransform.TransformPosition(AttackDisplacement.LineEnd);
			FVector ClosestPoint = Math::ClosestPointOnLine(WorldLineStart, WorldLineEnd, PlayerLocation);

			float KillMin = -400;
			float KillMax = 0;

			// Debug::DrawDebugLine(
			// 	WorldLineStart + FVector(0, 0, KillMin), WorldLineStart + FVector(0, 0, KillMax),
			// 	FLinearColor::Red, 30,
			// 	bDrawInForeground = true
			// 	);

			float FlatDistance = PlayerLocation.Dist2D(ClosestPoint);
			if (Math::Abs(FlatDistance) < Width * 2.0)
			{
				if (PlayerLocation.Z >= WorldLineStart.Z + KillMin && PlayerLocation.Z <= WorldLineStart.Z + KillMax)
				{
					bool bPlayerIsAboveCubeGrid = false;
					
					TListedActors<AMeltdownBossCubeGrid> CubeGrids;
					AMeltdownBossCubeGrid HitGrid;
					for (AMeltdownBossCubeGrid Grid : CubeGrids)
					{
						if (Grid.IsLocationWithinGrid2D(Player.ActorLocation, Width))
						{
							bPlayerIsAboveCubeGrid = true;
							HitGrid = Grid;
							break;
						}
					}

					if (bPlayerIsAboveCubeGrid)
					{
						FMeltdownBossPhaseOneLineAttackHitPlayerParams PlayerParams;
						PlayerParams.Player = Player;
						UMeltdownBossPhaseOneLineAttackEffectHandler::Trigger_HitPlayer(this, PlayerParams);

						Player.DamagePlayerHealth(0.5, DamageEffect = LineDeath);
						Player.AddKnockbackImpulse(
							ActorForwardVector,
							900.0, 1200.0
						);
						
						if (PlayerTemporaryIgnoresUntil[Player] == 0)
						{
							auto MoveComp = UPlayerMovementComponent::Get(Player);
							MoveComp.AddMovementIgnoresActor(this, HitGrid);
						}
						PlayerTemporaryIgnoresUntil[Player] = Time::GameTimeSeconds + 0.2;
					}
				}
			}
		}

		// Check for players that fell down into the chasm
		if (ChasmDisplacement.IsDisplacementActive())
		{
			for (auto Player : Game::Players)
			{
				if (Player.IsPlayerDead())
					continue;

				FVector PlayerLocation = Player.ActorLocation;
				FVector WorldLineStart = ChasmDisplacement.WorldLocation;
				FVector WorldLineEnd = ChasmDisplacement.WorldTransform.TransformPosition(ChasmDisplacement.LineEnd);
				FVector ClosestPoint = Math::ClosestPointOnLine(WorldLineStart, WorldLineEnd, PlayerLocation);

				float FlatDistance = PlayerLocation.Dist2D(ClosestPoint);
				if (Math::Abs(FlatDistance) < Width*1.5 && PlayerLocation.Z < WorldLineStart.Z - 400)
				{
					Player.KillPlayer();
				}
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (!bTriggered)
		{
			SetActorTickEnabled(false);
			return;
		}

		if (TrackPlayer != nullptr)
		{
			if (Time::GameTimeSeconds < TrackPlayerUntilTime)
			{
				UpdatePlayerTracking(TrackPlayer);
			}
		}

		for (auto Player : Game::Players)
		{
			if (PlayerTemporaryIgnoresUntil[Player] != 0 && PlayerTemporaryIgnoresUntil[Player] < Time::GameTimeSeconds)
			{
				auto MoveComp = UPlayerMovementComponent::Get(Player);
				MoveComp.RemoveMovementIgnoresActor(this);
				PlayerTemporaryIgnoresUntil[Player] = 0;
			}
		}

		Timer += DeltaSeconds;

		if (Timer < TelegraphDuration)
		{
			float Alpha = Math::Saturate(Timer / TelegraphTravelDuration);

			TelegraphDisplacement.ActivateDisplacement();
			TelegraphDisplacement.WorldLocation = ActorLocation;
			TelegraphDisplacement.Type = EMeltdownBossCubeGridDisplacementType::Line;
			TelegraphDisplacement.LineEnd = Math::Lerp(FVector::ZeroVector, LineEnd, Alpha);
			TelegraphDisplacement.ThresholdDistance = Width;
			TelegraphDisplacement.LerpDistance = Width;

			float TelegraphPct = Math::Saturate(Timer / TelegraphDuration);
			TelegraphDisplacement.Displacement = FVector(0.0, 0.0, Math::Sin(Time::GameTimeSeconds * 15.0) * 10.0 + 30.0 * TelegraphPct);
			// TelegraphDisplacement.Displacement = FVector(0.0, 0.0, 10);
			TelegraphDisplacement.Redness = -TelegraphPct;
		}
		else if (Timer < TelegraphDuration + (bFillEntireLine ? AttackDuration : AttackTravelDuration))
		{
			float Alpha = Math::Saturate((Timer - TelegraphDuration) / AttackTravelDuration);

			TelegraphDisplacement.Displacement = FVector(0.0, 0.0, Math::Sin(Time::GameTimeSeconds * 15.0) * 10.0 * 3.0 + 30.0);

			if (bFillEntireLine)
			{
				AttackDisplacement.ActivateDisplacement();
				AttackDisplacement.WorldLocation = ActorLocation;
				AttackDisplacement.Type = EMeltdownBossCubeGridDisplacementType::Line;
				AttackDisplacement.LineEnd = Math::Lerp(FVector::ZeroVector, LineEnd, Alpha);
				AttackDisplacement.ThresholdDistance = Width;
				AttackDisplacement.LerpDistance = Width;
				AttackDisplacement.Displacement = Displacement;
			}
			else
			{
				FVector WorldLineStart = ActorLocation;
				FVector WorldLineEnd = ActorTransform.TransformPosition(LineEnd);

				float WidthInAlpha = KillBumpLength / WorldLineStart.Distance(WorldLineEnd);

				AttackDisplacement.ActivateDisplacement();
				AttackDisplacement.Type = EMeltdownBossCubeGridDisplacementType::Line;
				AttackDisplacement.WorldLocation = Math::Lerp(WorldLineStart, WorldLineEnd, Alpha);
				AttackDisplacement.LineEnd = AttackDisplacement.WorldTransform.InverseTransformPosition(
					Math::Lerp(WorldLineStart, WorldLineEnd, Alpha + WidthInAlpha));
				AttackDisplacement.ThresholdDistance = Width;
				AttackDisplacement.LerpDistance = Width;
				AttackDisplacement.Displacement = Displacement;

				TelegraphDisplacement.WorldLocation = AttackDisplacement.WorldLocation;
				TelegraphDisplacement.LineEnd = TelegraphDisplacement.WorldTransform.InverseTransformPosition(WorldLineEnd);

				if (bCreateChasm)
				{
					ChasmDisplacement.ActivateDisplacement();
					ChasmDisplacement.ThresholdDistance = Width * 1.5;
					ChasmDisplacement.LerpDistance = 0;
					ChasmDisplacement.Displacement = ChasmDisplacementAmount;
					ChasmDisplacement.WorldLocation = WorldLineStart;
					ChasmDisplacement.LineEnd = ChasmDisplacement.WorldTransform.InverseTransformPosition(
						AttackDisplacement.WorldLocation + (WorldLineStart - WorldLineEnd).GetSafeNormal() * Width);
				}
			}

			CheckKillPlayers();

			if (!PulseTravelVFX.IsActive())
				PulseTravelVFX.Activate();
			PulseTravelVFX.SetWorldLocation(AttackDisplacement.WorldLocation);
		}
		else if (Timer < TelegraphDuration + AttackDuration + FadeOutDuration + FadeOutDelay)
		{
			TelegraphDisplacement.DeactivateDisplacement();
			PulseTravelVFX.Deactivate();

			float Alpha = Math::Saturate((Timer - TelegraphDuration - AttackDuration - FadeOutDelay) / FadeOutDuration);
			if (bFillEntireLine)
				AttackDisplacement.Displacement = Math::Lerp(Displacement, FVector::ZeroVector, Alpha);
			if (bCreateChasm)
				ChasmDisplacement.Displacement = Math::Lerp(ChasmDisplacementAmount, FVector::ZeroVector, Alpha);

			CheckKillPlayers();
		}
		else
		{
			TelegraphDisplacement.DeactivateDisplacement();
			AttackDisplacement.DeactivateDisplacement();
			ChasmDisplacement.DeactivateDisplacement();
			PulseTravelVFX.Deactivate();
			bTriggered = false;
			UMeltdownBossPhaseOneLineAttackEffectHandler::Trigger_AttackOver(this);
		}
	}
};

struct FMeltdownBossPhaseOneLineAttackHitPlayerParams
{
	UPROPERTY()
	AHazePlayerCharacter Player;
}

UCLASS(Abstract)
class UMeltdownBossPhaseOneLineAttackEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void AttackTriggered() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void HitPlayer(FMeltdownBossPhaseOneLineAttackHitPlayerParams Params) {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void AttackOver() {}
}