UCLASS(Abstract)
class ARedSpaceTether : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComp;

	UPROPERTY(EditAnywhere)
	TSubclassOf<URedSpaceTetherWidget> WidgetClass;
	URedSpaceTetherWidget TetherWidget;

	UPROPERTY(EditDefaultsOnly)
	FLinearColor MinColor = FLinearColor::Green;
	UPROPERTY(EditDefaultsOnly)
	FLinearColor MaxColor = FLinearColor::Red;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UDeathEffect> DeathEffect;

	FName TargetSocket = n"Spine1";

	float MinDist = 600.0;
	float MaxDist = 1800.0;

	float DefaultMaxDist;

	UPROPERTY(BlueprintReadOnly)
	float DistanceAlpha = 0.0;

	bool bTetherEnabled = false;

	bool bPlayersDead = false;

	float GracePeriod = 1.0;
	float CurrentGraceTimeRemaining = 1.0;
	float CurrentRespawnInvulnerabilityTimeRemaining = 0.0;
	float GraceMaxDist;

	float FFThreshold = 0.4;

	bool bCanKillPlayers = true;

	float DeathForce = 2.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TeleportActor(Game::Mio.ActorLocation, Game::Mio.ActorRotation, this);

		DefaultMaxDist = MaxDist;
		GraceMaxDist = MaxDist * 2.0;

		UPlayerHealthComponent::Get(Game::Mio).OnDeathTriggered.AddUFunction(this, n"MioDied");
		UPlayerHealthComponent::Get(Game::Zoe).OnDeathTriggered.AddUFunction(this, n"ZoeDied");
	}

	UFUNCTION()
	private void MioDied()
	{
		if (!bTetherEnabled)
			return;

		if (Game::Zoe.IsPlayerDead())
			return;

		FVector DeathDir = (Game::Zoe.ActorCenterLocation - Game::Mio.ActorCenterLocation).GetSafeNormal();
		Game::Zoe.KillPlayer(FPlayerDeathDamageParams(DeathDir, DeathForce), DeathEffect);
	}

	UFUNCTION()
	private void ZoeDied()
	{
		if (!bTetherEnabled)
			return;
		
		if (Game::Mio.IsPlayerDead())
			return;

		FVector DeathDir = (Game::Mio.ActorCenterLocation - Game::Zoe.ActorCenterLocation).GetSafeNormal();
		Game::Mio.KillPlayer(FPlayerDeathDamageParams(DeathDir, DeathForce), DeathEffect);
	}

	FVector GetTeatherMidPoint() const
	{
		return (Game::Mio.Mesh.GetSocketLocation(n"Spine1") + Game::Zoe.Mesh.GetSocketLocation(n"Spine1")) * 0.5;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (!bTetherEnabled)
			return;

		FVector MidPoint = GetTeatherMidPoint();
		FRotator Rot = (Game::Mio.Mesh.GetSocketLocation(n"Spine1") - MidPoint).GetSafeNormal().Rotation();
		SetActorLocationAndRotation(MidPoint, Rot);

		float PlayerDist = Game::Mio.GetDistanceTo(Game::Zoe);
		DistanceAlpha = Math::GetMappedRangeValueClamped(FVector2D(MinDist, MaxDist), FVector2D(0.0, 1.0), PlayerDist);

		CurrentRespawnInvulnerabilityTimeRemaining -= DeltaTime;
		if (DistanceAlpha >= 1.0 && bCanKillPlayers && !bPlayersDead && CurrentRespawnInvulnerabilityTimeRemaining <= 0.0)
		{
			CurrentGraceTimeRemaining -= DeltaTime;
			if (CurrentGraceTimeRemaining <= 0.0 || PlayerDist >= GraceMaxDist)
			{
				for (AHazePlayerCharacter Player : Game::GetPlayers())
				{
					if (!Player.IsPlayerDead() && !Player.IsPlayerRespawning())
					{
						FVector DeathDir = (Player.ActorCenterLocation - Player.OtherPlayer.ActorCenterLocation).GetSafeNormal();
						Player.KillPlayer(FPlayerDeathDamageParams(DeathDir, DeathForce), DeathEffect);
					}
				}
			}
		}
		else
		{
			CurrentGraceTimeRemaining = GracePeriod;
		}

		if (!bPlayersDead)
		{
			float FFAlpha = Math::GetMappedRangeValueClamped(FVector2D(FFThreshold, 1.0), FVector2D(0.0, 1.0), DistanceAlpha);
			for (AHazePlayerCharacter Player : Game::GetPlayers())
			{
				float LeftFF = Math::Sin(Time::GameTimeSeconds * 20.0) * (0.2 * FFAlpha);
				float RightFF = Math::Sin(-Time::GameTimeSeconds * 20.0) * (0.2 * FFAlpha);
				Player.SetFrameForceFeedback(LeftFF, RightFF, 0.0, 0.0);
			}
		}

		if (Game::Mio.IsPlayerDead() || Game::Zoe.IsPlayerDead())
		{
			if (bPlayersDead)
				return;

			bPlayersDead = true;
			URedSpaceTetherEffectEventHandler::Trigger_TetherDisabled(this);
		}
		else
		{
			if (!bPlayersDead)
				return;

			bPlayersDead = false;
			CurrentRespawnInvulnerabilityTimeRemaining = 2.0;
			URedSpaceTetherEffectEventHandler::Trigger_TetherEnabled(this);
		}
	}

	UFUNCTION(BlueprintEvent)
	void BP_PlayersKilled() {}

	UFUNCTION(DevFunction)
	void EnableTether()
	{
		if (bTetherEnabled)
			return;

		bTetherEnabled = true;
		SetActorTickEnabled(true);
		URedSpaceTetherEffectEventHandler::Trigger_TetherEnabled(this);

		CreateWidget();
	}

	UFUNCTION(DevFunction)
	void DisableTether()
	{
		if (!bTetherEnabled)
			return;

		bTetherEnabled = false;
		SetActorTickEnabled(false);
		URedSpaceTetherEffectEventHandler::Trigger_TetherDisabled(this);

		RemoveWidget();
	}

	void CreateWidget()
	{
		TetherWidget =  Widget::AddFullscreenWidget(WidgetClass);
		TetherWidget.TetherActor = this;
	}

	void RemoveWidget()
	{
		Widget::RemoveFullscreenWidget(TetherWidget);
	}

	UFUNCTION()
	void ChangeMaxDistance(float NewDist)
	{
		MaxDist = NewDist;
	}

	UFUNCTION()
	void ResetMaxDistance()
	{
		MaxDist = DefaultMaxDist;
	}

	UFUNCTION()
	void SetCanKillPlayers(bool bKillPlayers)
	{
		bCanKillPlayers = bKillPlayers;
	}
}