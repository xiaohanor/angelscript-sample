UCLASS(Abstract)
class AMeltdownPhaseThreeDecimator : AHazeCharacter
{
	UPROPERTY(DefaultComponent)
	UHazeActionQueueComponent ActionQueue;

	UPROPERTY(DefaultComponent)
	UDamageTriggerComponent DamageTrigger;
	default DamageTrigger.bApplyKnockbackImpulse = true;
	default DamageTrigger.HorizontalKnockbackStrength = 2000.0;
	default DamageTrigger.VerticalKnockbackStrength = 1200.0;

	UPROPERTY(DefaultComponent, Attach = CharacterMesh0)
	UHealthBarInWorldComponent HealthBarComp;
	default HealthBarComp.MaxHealth = 150.0;
	default HealthBarComp.CurrentHealth = 150.0;

	UPROPERTY(DefaultComponent)
	UMeltdownGlitchShootingResponseComponent GlitchResponce;

	UPROPERTY(DefaultComponent, Attach = CharacterMesh0)
	UAutoAimTargetComponent AutoAim;

	UPROPERTY()
	TSubclassOf<AMeltdownPhaseThreeDecimatorSpear> SpearClass;
	UPROPERTY()
	TSubclassOf<AMeltdownPhaseThreeDecimatorBomb> BombClass;

	UPROPERTY()
	UAnimSequence StartSpinAnimation;
	UPROPERTY()
	UAnimSequence SpinAnimation;
	UPROPERTY()
	UAnimSequence SpinStopAnimation;
	UPROPERTY()
	UAnimSequence SpearsAnimation;
	UPROPERTY()
	UAnimSequence SpikeBombsAnimation;

	AMeltdownPhaseThreeBoss Rader;

	FVector StartLocation;
	FVector IdleLocation;

	const float EnterDuration = 0.5;
	const float SpearInterval = 0.25;

	bool bLaunchSpears = false;
	int AttackIndex = 0;

	TPerPlayer<float> SpearTimer;
	TPerPlayer<int> SpearsRemaining;
	TPerPlayer<AMeltdownPhaseThreeDecimatorSpear> PreviousSpear;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AddActorDisable(this);
		GlitchResponce.OnGlitchHit.AddUFunction(this, n"OnHit");

		HealthBarComp.SetHealthBarEnabled(false);
		AutoAim.Disable(this);
	}

	UFUNCTION()
	private void OnHit(FMeltdownGlitchImpact Impact)
	{
		UMeltdownPhaseThreeDecimatorEffectHandler::Trigger_HitByPlayerAttack(this, Impact);
		HealthBarComp.CurrentHealth -= Impact.Damage;
		if (HealthBarComp.CurrentHealth <= 0)
		{
			UMeltdownPhaseThreeDecimatorEffectHandler::Trigger_DestroyedByPlayerAttack(this);
			DestroyActor();
		}
	}

	UFUNCTION()
	void LaunchFromPortal()
	{
		RemoveActorDisable(this);

		IdleLocation = Rader.ActorLocation;
		IdleLocation += Rader.ActorForwardVector * 800.0;

		FVector LeftHand = Rader.Mesh.GetSocketLocation(n"LeftAttach");
		FVector RightHand = Rader.Mesh.GetSocketLocation(n"RightAttach");

		StartLocation = (LeftHand + RightHand) * 0.5;
		StartLocation.Z = IdleLocation.Z;

		SetActorLocationAndRotation(StartLocation, FRotator::MakeFromX(IdleLocation - StartLocation));

		PlaySlotAnimation(Animation = SpinAnimation, bLoop = true);

		ActionQueue.Duration(EnterDuration, this, n"SpinToCenter");
		ActionQueue.Event(this, n"StopSpinning");
		ActionQueue.Idle(0.7);

		ActionQueue.Event(this, n"StartSpearAnimation");
		ActionQueue.Idle(0.7);
		ActionQueue.Event(this, n"TriggerSpears");
		ActionQueue.Idle(3.0);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (ActionQueue.IsEmpty())
		{
			ActionQueue.Event(this, n"StartSpikeBombs");
			ActionQueue.Idle(1.15);
			ActionQueue.Event(this, n"LaunchSpikeBomb");
			ActionQueue.Event(this, n"LaunchSpikeBomb");
			ActionQueue.Event(this, n"LaunchSpikeBomb");
			ActionQueue.Idle(1.15);
			ActionQueue.Event(this, n"LaunchSpikeBomb");
			ActionQueue.Event(this, n"LaunchSpikeBomb");
			ActionQueue.Event(this, n"LaunchSpikeBomb");
			ActionQueue.Idle(1.15);
			ActionQueue.Event(this, n"LaunchSpikeBomb");
			ActionQueue.Event(this, n"LaunchSpikeBomb");
			ActionQueue.Event(this, n"LaunchSpikeBomb");
			ActionQueue.Idle(1.0);
			ActionQueue.Event(this, n"StartSpearAnimation");
			ActionQueue.Idle(0.7);
			ActionQueue.Event(this, n"TriggerSpears");
			ActionQueue.Idle(2.5);

			AttackIndex += 1;
		}

		if (bLaunchSpears)
		{
			for (AHazePlayerCharacter Player : Game::Players)
			{
				SpearTimer[Player] -= DeltaSeconds;
				if (SpearTimer[Player] <= 0.0 && SpearsRemaining[Player] > 0)
				{
					if (CanSpawnSpear(Player))
					{
						SpawnSpear(Player);
						SpearTimer[Player] = SpearInterval;
						SpearsRemaining[Player] -= 1;
					}
				}
			}
		}

		if (Rader.IsDead())
		{
			DestroyActor();
		}
	}


	UFUNCTION()
	private void GlitchAway()
	{
		UMeltdownPhaseThreeDecimatorEffectHandler::Trigger_OnDisappear(this);
		DestroyActor();
	}

	UFUNCTION()
	private void StartSpinningAway()
	{
		PlaySlotAnimation(Animation = StartSpinAnimation);
	}

	UFUNCTION()
	private void LaunchSpikeBomb()
	{
		FVector SpawnLocation = Mesh.GetSocketLocation(n"Jaw");
		
		AMeltdownPhaseThreeDecimatorBomb Bomb = SpawnActor(BombClass, SpawnLocation, ActorRotation);
		Bomb.Rader = Rader;

		FRandomStream Stream(Rader.BombCount);

		Bomb.LandLocation = SpawnLocation + ActorForwardVector * Stream.RandRange(800.0, 1200.0);
		Bomb.LandLocation.Z = Rader.ActorLocation.Z;

		Bomb.LandLocation.X += Stream.RandRange(-800.0, 800.0);
		Bomb.LandLocation.Y += Stream.RandRange(-800.0, 800.0);

		Bomb.TargetRadius = 0.45;
		Bomb.TargetRadius += 0.15/3.0 * (Math::IntegerDivisionTrunc(Rader.BombCount, 3) % 3);
		Bomb.TargetRadius += 0.15 * (Rader.BombCount % 3);
		Bomb.TargetRadius *= Rader.ArenaRadius;

		Bomb.TargetSpeed *= Stream.RandRange(0.9, 1.1);
		Bomb.bClockwise = (Rader.BombCount % 2) == 0;
		Bomb.TargetPlayer = (Rader.BombCount % 2 == 0) ? Game::Mio : Game::Zoe;

		UMeltdownPhaseThreeDecimatorEffectHandler::Trigger_SpawnSpikeBomb(this);

		Bomb.Launch();
		Rader.BombCount += 1;
	}

	UFUNCTION()
	private void StartSpikeBombs()
	{
		PlaySlotAnimation(Animation = SpikeBombsAnimation);
	}

	UFUNCTION()
	private void SpinToCenter(float Alpha)
	{
		float DistanceAlpha = Alpha;
		SetActorLocation(Math::Lerp(StartLocation, IdleLocation, DistanceAlpha));
	}

	UFUNCTION()
	private void StopSpinning()
	{
		PlaySlotAnimation(Animation = SpinStopAnimation);

		AutoAim.Enable(this);
		HealthBarComp.SetHealthBarEnabled(true);
	}

	UFUNCTION()
	private void StartSpearAnimation()
	{
		PlaySlotAnimation(Animation = SpearsAnimation);
		UMeltdownPhaseThreeDecimatorEffectHandler::Trigger_PreSpawnSpears(this);
	}

	UFUNCTION()
	private void TriggerSpears()
	{
		bLaunchSpears = true;

		SpearTimer[Game::Mio] = 0.0;
		SpearTimer[Game::Zoe] = 0.0;

		SpearsRemaining[Game::Mio] = 6;
		SpearsRemaining[Game::Zoe] = 6;
	}

	void SpawnSpear(AHazePlayerCharacter Player)
	{
		FVector SpearLocation = Player.ActorLocation;
		SpearLocation.Z = IdleLocation.Z;

		AMeltdownPhaseThreeDecimatorSpear PrevSpear = PreviousSpear[Player];
		if (IsValid(PrevSpear) && PrevSpear.bBlocksAttacks)
		{
			FVector PrevSpearLocation = PrevSpear.ActorLocation;
			FVector SpearDelta = (SpearLocation - PrevSpearLocation);
			SpearLocation = PrevSpearLocation + SpearDelta.GetClampedToSize(PrevSpear.BlockingRadius, MAX_flt);
		}
		
		AMeltdownPhaseThreeDecimatorSpear Spear = SpawnActor(SpearClass, SpearLocation);
		Spear.TargetPlayer = Player;
		Spear.Launch();

		UMeltdownPhaseThreeDecimatorEffectHandler::Trigger_SpawnSpear(this, FMeltdownPhaseThreeDecimatorSpearAttackSpawnParams(SpearLocation));
		PreviousSpear[Player] = Spear;
	}

	bool CanSpawnSpear(AHazePlayerCharacter Player)
	{
		AMeltdownPhaseThreeDecimatorSpear PrevSpear = PreviousSpear[Player];
		if (IsValid(PrevSpear) && PrevSpear.bBlocksAttacks)
		{
			if (PrevSpear.ActorLocation.Dist2D(Player.ActorLocation) < PrevSpear.DamageRadius)
				return false;
		}

		if (Player.ActorLocation.Dist2D(Rader.ActorLocation) >= Rader.ArenaRadius)
			return false;

		return true;
	}
};

struct FMeltdownPhaseThreeDecimatorSpearAttackSpawnParams
{
	UPROPERTY()
	FVector SpawnLocation;

	FMeltdownPhaseThreeDecimatorSpearAttackSpawnParams(FVector _SpawnLocation)
	{
		SpawnLocation = _SpawnLocation;
	}
}

UCLASS(Abstract)
class UMeltdownPhaseThreeDecimatorEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDisappear() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void HitByPlayerAttack(FMeltdownGlitchImpact GlitchImpact) {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void DestroyedByPlayerAttack() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void PreSpawnSpears() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void SpawnSpear(FMeltdownPhaseThreeDecimatorSpearAttackSpawnParams Params) {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void SpawnSpikeBomb() {}
}