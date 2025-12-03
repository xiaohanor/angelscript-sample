UCLASS(Abstract)
class AGameShowArenaFlameThrower : AGameShowArenaDynamicObstacleBase
{
	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent FlameThrowerFX;
	default FlameThrowerFX.bAutoActivate = false;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent KillCollision;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent PlatformMesh;

	UPROPERTY(EditInstanceOnly, meta = (EditCondition = "!bAlwaysActive"))
	float EmitFireDuration = 2;

	// How long the platform does nothing between cooling down and heating up
	UPROPERTY(EditInstanceOnly, meta = (EditCondition = "!bAlwaysActive"))
	float DoNothingDuration = 2;

	UPROPERTY(DefaultComponent)
	UHazeActionQueueComponent ActionQueueComp;

	UPROPERTY(EditInstanceOnly)
	bool bAlwaysActive = false;

	// How long the platform cools down after emitting fire
	UPROPERTY(EditInstanceOnly, meta = (EditCondition = "!bAlwaysActive"))
	float CoolDownDuration = 2;

	// How long the platform warms up before emitting fire
	UPROPERTY(EditInstanceOnly, meta = (EditCondition = "!bAlwaysActive"))
	float HeatUpDuration = 2;

	bool bIsActive = false;

	UPROPERTY(EditAnywhere)
	FVector FullIntensityRedColor = FVector(150, 0, 0);

	UPROPERTY(EditAnywhere)
	FVector CooledDownRedColor = FVector(0, 0, 1);

	UPROPERTY(EditInstanceOnly)
	AGameShowArenaBombHolder ConnectedBombHolder;

	UPROPERTY(EditInstanceOnly)
	AGameShowArenaPlatformArm AttachmentArm;

	UPROPERTY(EditInstanceOnly)
	float InitialActivationDelay = 2.0;

	UPROPERTY()
	TSubclassOf<UDamageEffect> FlameThrowerDamageEffect;
	UPROPERTY()
	TSubclassOf<UDeathEffect> FlameThrowerDeathEffect;

	// UPROPERTY(DefaultComponent, ShowOnActor)
	// UGameShowArenaHeightAdjustableComponent HeightComp;

	FVector LastColor = FVector::ZeroVector;

	float CollisionActivationTimerDuration = 0.5;
	bool bKillCollisionActive = false;

	TPerPlayer<bool> PlayersInsideFire;

	int MaterialIndex;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		KillCollision.OnComponentBeginOverlap.AddUFunction(this, n"OnKillCollisionBeginOverlap");
		KillCollision.OnComponentEndOverlap.AddUFunction(this, n"OnKillCollisionEndOverlap");
		KillCollision.CollisionEnabled = ECollisionEnabled::NoCollision;

		AttachmentArm.OnMovementFinished.AddUFunction(this, n"OnArmMovementFinished");
		AttachmentArm.OnMovementStarted.AddUFunction(this, n"OnArmMovementStarted");

		MaterialIndex = PlatformMesh.GetMaterialIndex(n"GameShowPanel_01");
		if (!bAlwaysActive)
		{
			ConnectedBombHolder.OnBombPickedUp.AddUFunction(this, n"OnBombPickedUp");
			ConnectedBombHolder.ConnectedBomb.OnBombExploded.AddUFunction(this, n"OnBombExploded");
			SetActorTickEnabled(false);
			PlatformMesh.SetVectorParameterValueOnMaterialIndex(MaterialIndex, n"EnvBasic_EmissiveColor", CooledDownRedColor);
		}
	}

	UFUNCTION()
	private void OnArmMovementStarted()
	{
		DeactivateFlameThrower();
	}

	UFUNCTION()
	private void OnArmMovementFinished()
	{
		if (bAlwaysActive)
		{
			ActivateFlameThrower();
			ActivateKillCollision();
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnActorEnabled()
	{
		AttachmentArm.AttachActorToPlatformPosition(this);
		ActorRelativeRotation = FRotator(90, 0, 0);
	}

	UFUNCTION(BlueprintOverride)
	void OnActorDisabled()
	{
		AttachmentArm.DetachActorFromPlatform(this);
	}

	UFUNCTION()
	private void OnBombExploded(AGameShowArenaBomb Bomb)
	{
		if (bAlwaysActive)
			return;

		PlayersInsideFire[Game::Mio] = false;
		PlayersInsideFire[Game::Zoe] = false;
		bKillCollisionActive = false;
		ActionQueueComp.Empty();
		ActionQueueComp.SetLooping(false);
		PlatformMesh.SetVectorParameterValueOnMaterialIndex(MaterialIndex, n"EnvBasic_EmissiveColor", CooledDownRedColor);
		DeactivateFlameThrower();
	}

	UFUNCTION()
	private void OnBombPickedUp()
	{
		ActionQueueComp.Idle(InitialActivationDelay);
		ActionQueueComp.Event(this, n"InitialWaitFinished");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bAlwaysActive)
		{
			BurnPlayersInFire(DeltaSeconds);
			return;
		}
	}

	UFUNCTION()
	private void InitialWaitFinished()
	{
		ActionQueueComp.Empty();
		ActionQueueComp.Duration(HeatUpDuration, this, n"HeatPlatform");
		ActionQueueComp.Event(this, n"ActivateFlameThrower");
		ActionQueueComp.Duration(EmitFireDuration, this, n"EmitFire");
		ActionQueueComp.Event(this, n"DeactivateFlameThrower");
		ActionQueueComp.Duration(CoolDownDuration, this, n"CoolDownPlatform");
		ActionQueueComp.Idle(DoNothingDuration);
		ActionQueueComp.SetLooping(true);
	}

	UFUNCTION()
	private void EmitFire(float Alpha)
	{
		float CollisionTimerAlpha = Math::Saturate((CollisionActivationTimerDuration / EmitFireDuration));
		if (!bKillCollisionActive && Alpha > CollisionTimerAlpha)
		{
			ActivateKillCollision();
		}

		float DeltaSeconds = Time::GetActorDeltaSeconds(this);
		BurnPlayersInFire(DeltaSeconds);
	}

	UFUNCTION()
	private void CoolDownPlatform(float Alpha)
	{
		auto CurrentColor = Math::Lerp(FullIntensityRedColor, CooledDownRedColor, Math::SinusoidalOut(0, 1, Alpha));
		PlatformMesh.SetVectorParameterValueOnMaterialIndex(MaterialIndex, n"EnvBasic_EmissiveColor", CurrentColor);
	}

	UFUNCTION()
	private void HeatPlatform(float Alpha)
	{
		auto CurrentColor = Math::Lerp(CooledDownRedColor, FullIntensityRedColor, Math::SinusoidalIn(0, 1, Alpha));
		PlatformMesh.SetVectorParameterValueOnMaterialIndex(MaterialIndex, n"EnvBasic_EmissiveColor", CurrentColor);
		UGameShowArenaFlameThrowerEffectHandler::Trigger_OnHeatPlatform(this);
	}

	void BurnPlayersInFire(float DeltaSeconds)
	{
		bool bBurnedAPlayer = false;
		for (auto Player : Game::Players)
		{
			if (PlayersInsideFire[Player])
			{
				Player.DealBatchedDamageOverTime(2.0 * DeltaSeconds, FPlayerDeathDamageParams(), FlameThrowerDamageEffect, FlameThrowerDeathEffect);
				UGameShowArenaBombTossEventHandler::Trigger_OnPlayerHurtByFlames(Player, FGameShowArenaPlayerHurtByFlamesParams(Player));
				bBurnedAPlayer = true;
			}
		}
		if (bBurnedAPlayer)
		{
			FGameShowArenaFlameThrowerBurnPlayerParams Params;
			Params.FlameThrower = this;
			UGameShowArenaFlameThrowerEffectHandler::Trigger_OnFlamesBurnPlayer(this, Params);
		}
	}

	UFUNCTION()
	private void OnKillCollisionBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
									 UPrimitiveComponent OtherComp, int OtherBodyIndex,
									 bool bFromSweep, const FHitResult&in SweepResult)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		PlayersInsideFire[Player] = true;
	}

	UFUNCTION()
	void DeactivateFlameThrower()
	{
		FlameThrowerFX.Deactivate();
		KillCollision.CollisionEnabled = ECollisionEnabled::NoCollision;
		bKillCollisionActive = false;
		FGameShowArenaFlameThrowerDeactivationParams Params;
		Params.FlameThrower = this;
		UGameShowArenaFlameThrowerEffectHandler::Trigger_OnFlamesDeactivated(this, Params);
	}

	UFUNCTION()
	void ActivateFlameThrower()
	{
		FlameThrowerFX.Activate();
		FGameShowArenaFlameThrowerActivationParams Params;
		Params.FlameThrower = this;
		UGameShowArenaFlameThrowerEffectHandler::Trigger_OnFlamesActivated(this, Params);
	}

	UFUNCTION()
	private void OnKillCollisionEndOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
								   UPrimitiveComponent OtherComp, int OtherBodyIndex)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		PlayersInsideFire[Player] = false;
	}

	void ActivateKillCollision()
	{
		KillCollision.CollisionEnabled = ECollisionEnabled::QueryOnly;
		bKillCollisionActive = true;
	}
}