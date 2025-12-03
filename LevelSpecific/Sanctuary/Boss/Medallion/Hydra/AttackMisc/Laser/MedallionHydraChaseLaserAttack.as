class AMedallionHydraChaseLaserAttack : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent HeadRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent BodyRoot;
	
	UPROPERTY(EditInstanceOnly)
	ASplineActor SplineActor;
	UHazeSplineComponent SplineComp;

	UPROPERTY(EditInstanceOnly)
	EHazePlayer TargetPlayer;
	AHazePlayerCharacter Player;
	UPlayerHealthComponent HealthComp;

	UPROPERTY(DefaultComponent)
	UHazeActionQueueComponent QueueComp;

	ASanctuaryBossMedallionHydra Hydra;	

	const float ForwardsOffset = 500.0;
	const float LerpDuration = 2.0;
	
	float PlayerSign = 1.0;
	bool bActive = false;
	bool bLasering = false;

	float RespawnTimeStamp;
	const float NiceTargetingAfterRespawnDuration = 1.0;

	FHazeAcceleratedFloat AccSplineProgress;
	const float TelegraphDuration = 1.0;

	float BaseZ;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (TargetPlayer == EHazePlayer::Zoe)
			PlayerSign = -1.0;

		Player = Game::GetPlayer(TargetPlayer);
		HealthComp = UPlayerHealthComponent::Get(Player);

		SplineComp = UHazeSplineComponent::Get(SplineActor);

		BaseZ = ActorLocation.Z;

		HealthComp.OnReviveTriggered.AddUFunction(this, n"HandlePlayerRespawned");
	}

	UFUNCTION()
	private void HandlePlayerRespawned()
	{
		RespawnTimeStamp = Time::GameTimeSeconds;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bActive)
		{
			float PlayerSplineLocation = SplineComp.GetClosestSplineDistanceToWorldLocation(Player.ActorLocation);
			float TargetSplineLocation = PlayerSplineLocation;// + ForwardsOffset * PlayerSign;
			float FollowSpeed = 6.0;

			if (Player.IsPlayerDead() || Time::GameTimeSeconds < RespawnTimeStamp + NiceTargetingAfterRespawnDuration)
			{
				TargetSplineLocation -= 500.0 * PlayerSign;
			}

			if (TargetSplineLocation * PlayerSign < AccSplineProgress.Value * PlayerSign)
			{
				FollowSpeed = 1.0;
			}

			AccSplineProgress.AccelerateTo(TargetSplineLocation, FollowSpeed, DeltaSeconds);

			FVector Location = SplineComp.GetWorldLocationAtSplineDistance(AccSplineProgress.Value);
			Location.Z = Math::Lerp(BaseZ, Player.ActorLocation.Z, 0.2);

			FQuat Rotation = SplineComp.GetWorldRotationAtSplineDistance(AccSplineProgress.Value);

			SetActorLocation(Location);
			SetActorRotation(Rotation);
		}
	}

	UFUNCTION()
	void Activate(ASanctuaryBossMedallionHydra HydraActor)
	{
		if (bActive)
		{
			PrintToScreenScaled("Already Active", 3.0, FLinearColor::Red);
			return;
		}
		
		HealthComp.OnStartDying.AddUFunction(this, n"HandlePlayerDeath");

		bActive = true;
		bLasering = true;

		float PlayerSplineLocation = SplineComp.GetClosestSplineDistanceToWorldLocation(Player.ActorLocation);
		float TargetSplineLocation = PlayerSplineLocation + ForwardsOffset * PlayerSign;
		AccSplineProgress.SnapTo(TargetSplineLocation);

		FVector Location = SplineComp.GetWorldLocationAtSplineDistance(AccSplineProgress.Value);
		Location.Z = ActorLocation.Z;

		FQuat Rotation = SplineComp.GetWorldRotationAtSplineDistance(AccSplineProgress.Value);

		SetActorLocation(Location);
		SetActorRotation(Rotation);

		Hydra = HydraActor;
		Hydra.BlockLaunchProjectiles(this, true);

		Hydra.MoveActorComp.ApplyTransform(this, BodyRoot, 
			EMedallionHydraMovePivotPriority::High, 
			LerpDuration);
		Hydra.MoveHeadPivotComp.ApplyHeadPivot(this, HeadRoot, 
			EMedallionHydraMovePivotPriority::High, 
			LerpDuration);

		Hydra.EnterMhAnimation(EFeatureTagMedallionHydra::LaserOver);

		QueueComp.Duration(2.0, this, n"HeadAppearUpdate");
		QueueComp.Event(this, n"ActivateLaser");
		QueueComp.Idle(TelegraphDuration);
		QueueComp.Event(this, n"EventHandlerStartLaser");
		QueueComp.Idle(6.5);
		QueueComp.Event(this, n"DeactivateLaser");
		QueueComp.Idle(0.5);
		QueueComp.Event(this, n"ExitLaserAnimation");
		QueueComp.ReverseDuration(1.0, this, n"HeadAppearUpdate");
		QueueComp.Event(this, n"Deactivate");

		Hydra.Refs.HydraAttackManager.OnPhaseChanged.AddUFunction(this, n"HandlePhaseChanged");
		
		FSanctuaryBossMedallionHydraEventPlayerAttackData Params;
		Params.PlayerTarget = Player;
		Params.AttackedHydra = Hydra;
		Params.AttackType = EMedallionHydraAttack::ChaseLaser;
		UMedallionHydraAttackManagerEventHandler::Trigger_OnMoveToSidescrollerLaser(Hydra.Refs.HydraAttackManager, Params);
	}

	UFUNCTION()
	private void HandlePlayerDeath()
	{
		//I OPTED FOR MAKING THE LASER FOLLOW BETTER INSTEAD
		// if (bLasering)
		// {
		// 	QueueComp.Empty();
		// 	QueueComp.Event(this, n"DeactivateLaser");
		// 	QueueComp.ReverseDuration(1.0, this, n"HeadAppearUpdate");
		// 	QueueComp.Event(this, n"Deactivate");
		// }
	}

	UFUNCTION()
	private void HandlePhaseChanged(EMedallionPhase Phase, bool bNaturalProgression)
	{
		if (Phase == EMedallionPhase::Merge1 ||
			Phase == EMedallionPhase::Merge2 ||
			Phase == EMedallionPhase::Merge3)
		{
			if (bLasering)
			{
				QueueComp.Empty();
				QueueComp.Event(this, n"DeactivateLaser");
				QueueComp.Idle(0.5);
				QueueComp.Event(this, n"ExitLaserAnimation");
				QueueComp.ReverseDuration(1.0, this, n"HeadAppearUpdate");
				QueueComp.Event(this, n"Deactivate");
			}
		}
	}

	UFUNCTION()
	private void HeadAppearUpdate(float Alpha)
	{
		float CurrentValue = Math::EaseOut(1.0, 0.0, Alpha, 2.0);
		HeadRoot.SetRelativeLocation(FVector::UpVector * 3000.0 * CurrentValue);
	}

	UFUNCTION()
	private void ActivateLaser()
	{
		Hydra.ActivateAboveLaser(TelegraphDuration);
		FSanctuaryBossMedallionHydraEventPlayerAttackData Params;
		Params.PlayerTarget = Player;
		Params.AttackedHydra = Hydra;
		Params.AttackType = EMedallionHydraAttack::ChaseLaser;
		UMedallionHydraAttackManagerEventHandler::Trigger_OnTelegraphSidescrollerLaser(Hydra.Refs.HydraAttackManager, Params);
	}

	UFUNCTION()
	private void EventHandlerStartLaser()
	{
		FSanctuaryBossMedallionHydraEventPlayerAttackData Params;
		Params.PlayerTarget = Player;
		Params.AttackedHydra = Hydra;
		Params.AttackType = EMedallionHydraAttack::ChaseLaser;
		UMedallionHydraAttackManagerEventHandler::Trigger_OnSidescrollerLaserStart(Hydra.Refs.HydraAttackManager, Params);
	}

	UFUNCTION()
	private void DeactivateLaser()
	{
		Hydra.DeactivateAboveLaser();
		bLasering = false;
		FSanctuaryBossMedallionHydraEventPlayerAttackData Params;
		Params.PlayerTarget = Player;
		Params.AttackedHydra = Hydra;
		Params.AttackType = EMedallionHydraAttack::ChaseLaser;
		UMedallionHydraAttackManagerEventHandler::Trigger_OnSidescrollerLaserStop(Hydra.Refs.HydraAttackManager, Params);
	}

	UFUNCTION()
	private void ExitLaserAnimation()
	{
		if (Hydra.AnimationComponent.GetFeatureTag() == EFeatureTagMedallionHydra::LaserOver)
			Hydra.ExitMhAnimation(EFeatureTagMedallionHydra::LaserOver);
		FSanctuaryBossMedallionHydraEventPlayerAttackData Params;
		Params.PlayerTarget = Player;
		Params.AttackedHydra = Hydra;
		Params.AttackType = EMedallionHydraAttack::ChaseLaser;
		UMedallionHydraAttackManagerEventHandler::Trigger_OnSidescrollerLaserExitAnimation(Hydra.Refs.HydraAttackManager, Params);
	}

	UFUNCTION()
	private void Deactivate()
	{
		Hydra.MoveActorComp.Clear(this);
		Hydra.MoveHeadPivotComp.Clear(this);
		bActive = false;

		Hydra.ClearBlockLaunchProjectiles(this);

		HealthComp.OnStartDying.UnbindObject(this);

		FSanctuaryBossMedallionHydraEventPlayerAttackData Params;
		Params.PlayerTarget = Player;
		Params.AttackedHydra = Hydra;
		Params.AttackType = EMedallionHydraAttack::ChaseLaser;
		UMedallionHydraAttackManagerEventHandler::Trigger_OnSidescrollerLaserDeactivate(Hydra.Refs.HydraAttackManager, Params);
	}
};