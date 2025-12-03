class UMeltdownPhaseTwoLavaSwordAttackCapability : UHazeCapability
{
	default TickGroup = EHazeTickGroup::Movement;

	AMeltdownBossPhaseTwo Rader;
	AHazePlayerCharacter TrackPlayer;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Rader = Cast<AMeltdownBossPhaseTwo>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Rader.CurrentAttack == EMeltdownPhaseTwoAttack::LavaSword)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Rader.CurrentAttack != EMeltdownPhaseTwoAttack::LavaSword)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Rader.FireSword.SwordRoot.SetAbsolute(false, false, true);
		Rader.FireSword.SwordRoot.AttachToComponent(Rader.Mesh, n"RightAttach");
		Rader.FireSword.SwordRoot.SetRelativeRotation(FRotator(0, 90, -90));
		Rader.FireSword.RemoveActorDisable(Rader.FireSword);
		Rader.FireSword.TelegraphRoot.SetHiddenInGame(true, true);
		Rader.FireSword.TelegraphRoot.SetAbsoluteAndUpdateTransform(true, true, true, Rader.FireSword.TelegraphRoot.WorldTransform);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Rader.FireSword.SwordRoot.DetachFromParent(true);
		Rader.FireSword.AddActorDisable(this);
		Rader.ActionQueue.Empty();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (Rader.Mesh.CanRequestLocomotion())
			Rader.Mesh.RequestLocomotion(n"Lava", this);

		if (Rader.ActionQueue.IsEmpty())
		{
			Rader.ActionQueue.Event(this, n"StartRightSwing");
			Rader.ActionQueue.Idle(2.33);
			Rader.ActionQueue.Event(this, n"StopSwing");

			Rader.ActionQueue.Event(this, n"StartLeftSwing");
			Rader.ActionQueue.Idle(2.33);
			Rader.ActionQueue.Event(this, n"StopSwing");

			for (int i = 0; i < 3; ++i)
			{
				Rader.ActionQueue.Event(this, n"StartDownSwing");
				Rader.ActionQueue.Duration(0.70, this, n"TrackDownSwing");
				Rader.ActionQueue.Duration(0.54, this, n"TelegraphDownSwing");
				Rader.ActionQueue.Event(this, n"DownSwingHit");
				Rader.ActionQueue.Idle(1.33);
				Rader.ActionQueue.Event(this, n"FinishDownSwing");
			}
		}
	}

	UFUNCTION()
	private void StopSwing()
	{
		UMeltdownBossPhaseTwoFireSwordEffectHandler::Trigger_StopHorizontalSwing(Rader.FireSword);

	}

	UFUNCTION()
	private void StartLeftSwing()
	{
		Rader.LastLeftAttackFrame = GFrameNumber;
		for (AHazePlayerCharacter Player : Game::Players)
			Player.PlayWorldCameraShake(Rader.FireSword.SwordSweepShake,this, Rader.FireSword.SwordSweepShakeLocation.WorldLocation, 400, 900);

		Rader.FireSword.HitImpulse = Rader.ActorRightVector * -900 + FVector(0, 0, 1200);
		Rader.FireSword.bOnlyHitGroundedPlayers = true;
		UMeltdownBossPhaseTwoFireSwordEffectHandler::Trigger_StartHorizontalSwing(Rader.FireSword);
		UMeltdownBossPhaseTwoFireSwordEffectHandler::Trigger_StartHorizontalSwingLeft(Rader.FireSword);
	}

	UFUNCTION()
	private void StartRightSwing()
	{
		Rader.FireSword.SweepFF.Play();
		for (AHazePlayerCharacter Player : Game::Players)
			Player.PlayWorldCameraShake(Rader.FireSword.SwordSweepShake,this, Rader.FireSword.SwordSweepShakeLocation.WorldLocation, 400, 900);

		Rader.LastRightAttackFrame = GFrameNumber;
		Rader.FireSword.HitImpulse = Rader.ActorRightVector * 900 + FVector(0, 0, 1200);
		Rader.FireSword.bOnlyHitGroundedPlayers = true;

		UMeltdownBossPhaseTwoFireSwordEffectHandler::Trigger_StartHorizontalSwing(Rader.FireSword);
		UMeltdownBossPhaseTwoFireSwordEffectHandler::Trigger_StartHorizontalSwingRight(Rader.FireSword);
	}

	UFUNCTION()
	private void StartDownSwing()
	{
		Rader.LastDownAttackFrame = GFrameNumber;
		Rader.FireSword.TelegraphRoot.SetHiddenInGame(false, true);
		Rader.FireSword.HitImpulse = Rader.ActorRightVector * 900 + FVector(0, 0, 800);
		Rader.FireSword.bOnlyHitGroundedPlayers = false;

		if (TrackPlayer == nullptr)
			TrackPlayer = Game::Mio;
		else
			TrackPlayer = TrackPlayer.OtherPlayer;

		UMeltdownBossPhaseTwoFireSwordEffectHandler::Trigger_StartVerticalSwing(Rader.FireSword);
	}

	UFUNCTION()
	private void TrackDownSwing(float Alpha)
	{
		Rader.FireSword.SweepFF.Stop();
		FVector CenterLocation = Rader.FireSword.ActorLocation;
		Rader.TelegraphAttackPosition = Math::GetMappedRangeValueClamped(
			FVector2D(CenterLocation.Y+1100, CenterLocation.Y-1400),
			FVector2D(-1.0, 1.0),
			TrackPlayer.ActorLocation.Y
		);

		UpdateTelegraph();
	}

	UFUNCTION()
	private void TelegraphDownSwing(float Alpha)
	{
		UpdateTelegraph();
	}

	void UpdateTelegraph()
	{
		FVector TelegraphLocation = Rader.FireSword.TelegraphRoot.WorldLocation;
		TelegraphLocation.Y = Rader.FireSword.ActorLocation.Y + Math::GetMappedRangeValueClamped(
			FVector2D(-1.0, 1.0),
			FVector2D(1100, -1400),
			Rader.TelegraphAttackPosition
		);
		Rader.FireSword.TelegraphRoot.SetWorldLocation(TelegraphLocation);
	}

	UFUNCTION()
	private void DownSwingHit()
	{
		Rader.FireSword.TelegraphRoot.SetHiddenInGame(true, true);

		for (AHazePlayerCharacter Player : Game::Players)
		{
			Player.PlayCameraShake(Rader.FireSword.SlamShake,this);
			Player.PlayForceFeedback(Rader.FireSword.SlamForceFeedback, false, false, this);
		}

		FVector ShockwaveOrigin = Rader.FireSword.TelegraphRoot.WorldLocation;
		AMeltdownPhaseTwoLavaSwordShockwave ShockwaveLeft = SpawnActor(
			Rader.SwordShockwaveClass,
			ShockwaveOrigin,
			FRotator::MakeFromYZ(FVector(0, 1, 0), FVector::UpVector));
		ShockwaveLeft.Rader = Rader;
		ShockwaveLeft.Direction = FVector(0, 1, 0);

		AMeltdownPhaseTwoLavaSwordShockwave ShockwaveRight = SpawnActor(
			Rader.SwordShockwaveClass,
			ShockwaveOrigin,
			FRotator::MakeFromYZ(FVector(0, -1, 0), FVector::UpVector));
		ShockwaveRight.Rader = Rader;
		ShockwaveRight.Direction = FVector(0, -1, 0);

		FMeltdownBossPhaseTwoFireSwordHitParams HitParams;
		HitParams.HitLocation = Rader.FireSword.SwordRoot.WorldLocation;
		UMeltdownBossPhaseTwoFireSwordEffectHandler::Trigger_VerticalSwingHit(Rader.FireSword, HitParams);

		Rader.FireSword.CurrentShockwaves[0] = ShockwaveLeft;
		Rader.FireSword.CurrentShockwaves[1] = ShockwaveRight;
	}

	UFUNCTION()
	private void FinishDownSwing()
	{
	}
};

UCLASS(Abstract)
class AMeltdownPhaseTwoLavaSwordShockwave : AHazeActor
{
	UPROPERTY(DefaultComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeMovablePlayerTriggerComponent Trigger;

	UPROPERTY(EditAnywhere)
	TSubclassOf<UDamageEffect> SwordShockwaveDamage;

	float TravelSpeed = 500.0;
	float TravelAcceleration = 3000.0;
	float TravelTime = 2.0;
	FVector Direction;

	AMeltdownBossPhaseTwo Rader;

	float Timer = 0.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		Timer += DeltaSeconds;
		if (Timer > TravelTime)
		{
			DestroyActor();
			return;
		}

		SetActorLocation(
			ActorLocation + Direction * (TravelSpeed + TravelAcceleration * Timer) * DeltaSeconds
		);

		for (AHazePlayerCharacter Player : Game::Players)
		{
			if (Trigger.IsPlayerInTrigger(Player) && Player.IsOnWalkableGround())
			{
				Player.AddKnockbackImpulse(Direction, 900, 1200);
				Player.DamagePlayerHealth(0.5, DamageEffect = SwordShockwaveDamage);

				FMeltdownBossPhaseTwoSwordHitPlayerParams HitPlayerParams;
				HitPlayerParams.Player = Player;
				UMeltdownBossPhaseTwoFireSwordEffectHandler::Trigger_ShockwaveHitPlayer(Rader, HitPlayerParams);
			}
		}
	}
}