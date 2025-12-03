class AMedallionHydraSidescrollerSpamAttackActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent HeadRoot;
	FVector HeadRootRelativeLocation;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent BodyRoot;

	UPROPERTY(DefaultComponent)
	UCameraShakeForceFeedbackComponent 	CameraShakeForceFeedbackComponent;
	
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

	const float ForwardsOffset = 1500.0;
	const float LerpDuration = 2.0;
	const int ProjectilesToLaunch = 20;
	const float ProjectileInterval = 0.3;
	const float PlayerLerpDuration = 2.0;

	//Recoil
	const float RecoilStiff = 15.0;
	const float RecoilDamp = 0.8;
	const float RecoilImpulse = 5000.0;
	const float AimHeight = 2000.0;
	
	float PlayerSign = 1.0;
	bool bActive = false;

	FHazeAcceleratedFloat AccSplineProgress;
	FHazeAcceleratedRotator AccHeadRot;
	FHazeAcceleratedFloat AccRecoil;

	UMedallionPlayerReferencesComponent RefsComp;

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

		HeadRootRelativeLocation = HeadRoot.RelativeLocation;
		RefsComp = UMedallionPlayerReferencesComponent::GetOrCreate(Game::Mio);

	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bActive)
		{
			float PlayerSplineLocation = SplineComp.GetClosestSplineDistanceToWorldLocation(Player.ActorLocation);
			float TargetSplineLocation = PlayerSplineLocation + ForwardsOffset * PlayerSign;
			AccSplineProgress.AccelerateTo(TargetSplineLocation, 2.0, DeltaSeconds);

			FVector Location = SplineComp.GetWorldLocationAtSplineDistance(AccSplineProgress.Value);
			Location.Z = Math::Lerp(BaseZ, Player.ActorLocation.Z, 0.5);

			FQuat Rotation = SplineComp.GetWorldRotationAtSplineDistance(AccSplineProgress.Value);

			SetActorLocationAndRotation(Location, Rotation);

			FVector HeadDirection = ((Player.ActorCenterLocation + FVector::UpVector * AimHeight) - HeadRoot.WorldLocation).GetSafeNormal();
			FRotator HeadRot = FRotator::MakeFromXZ(HeadDirection, FVector::UpVector);
			AccHeadRot.AccelerateTo(HeadRot, 1.0, DeltaSeconds);

			HeadRoot.SetWorldRotation(AccHeadRot.Value);

			AccRecoil.SpringTo(0.0, RecoilStiff, RecoilDamp, DeltaSeconds);

			FVector HeadRootLocation = ActorTransform.TransformPositionNoScale(HeadRootRelativeLocation);
			HeadRootLocation -= AccHeadRot.Value.ForwardVector * AccRecoil.Value;
			HeadRoot.SetWorldLocation(HeadRootLocation);

			PrintToScreen("Recoil = " + AccRecoil.Value);
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

		BP_StartTelegraph();

		HealthComp.OnStartDying.AddUFunction(this, n"HandlePlayerDeath");

		bActive = true;

		float PlayerSplineLocation = SplineComp.GetClosestSplineDistanceToWorldLocation(Player.ActorLocation);
		float TargetSplineLocation = PlayerSplineLocation + ForwardsOffset * PlayerSign;
		AccSplineProgress.SnapTo(TargetSplineLocation);

		//Setup transforms

		FVector Location = SplineComp.GetWorldLocationAtSplineDistance(AccSplineProgress.Value);
		Location.Z = ActorLocation.Z;

		FQuat Rotation = SplineComp.GetWorldRotationAtSplineDistance(AccSplineProgress.Value);

		SetActorLocationAndRotation(Location, Rotation);

		FVector HeadDirection = (Player.ActorCenterLocation - HeadRoot.WorldLocation).GetSafeNormal();
		FRotator HeadRot = FRotator::MakeFromXZ(HeadDirection, FVector::UpVector);
		AccHeadRot.SnapTo(HeadRot);

		HeadRoot.SetWorldRotation(AccHeadRot.Value);

		Hydra = HydraActor;
		Hydra.BlockLaunchProjectiles(this, true);

		// --------

		Hydra.MoveActorComp.ApplyTransform(this, BodyRoot, 
			EMedallionHydraMovePivotPriority::High, 
			LerpDuration);
		Hydra.MoveHeadPivotComp.ApplyHeadPivot(this, HeadRoot, 
			EMedallionHydraMovePivotPriority::High, 
			LerpDuration);

		Hydra.EnterMhAnimation(EFeatureTagMedallionHydra::MachineGun);

		QueueComp.Idle(2.0);

		QueueComp.Event(this, n"StopTelegraph");

		for (int i = 0; i < ProjectilesToLaunch; i++)
		{
			QueueComp.Event(this, n"LaunchProjectile");
			QueueComp.Idle(ProjectileInterval);
		}

		QueueComp.Event(this, n"Deactivate");

		Hydra.Refs.HydraAttackManager.OnPhaseChanged.AddUFunction(this, n"HandlePhaseChanged");

		FSanctuaryBossMedallionManagerEventPlayerAttackData Params;
		Params.AttackType = EMedallionHydraAttack::SidescrollerSpam;
		Params.Hydra = HydraActor;
		Params.TargetPlayer = Player;

		UMedallionHydraAttackManagerEventHandler::Trigger_OnMoveToSidescrollerSpamAttack(RefsComp.Refs.HydraAttackManager, Params);
	}

	UFUNCTION()
	private void LaunchProjectile()
	{
		Hydra.CallLaunchProjectileSpam(Player);
		CameraShakeForceFeedbackComponent.ActivateCameraShakeAndForceFeedback();
		AccRecoil.SnapTo(AccRecoil.Value, AccRecoil.Velocity + RecoilImpulse);
	}

	UFUNCTION()
	private void Deactivate()
	{
		Hydra.ExitMhAnimation(EFeatureTagMedallionHydra::MachineGun);
		Hydra.MoveActorComp.Clear(this);
		Hydra.MoveHeadPivotComp.Clear(this);
		bActive = false;

		Hydra.ClearBlockLaunchProjectiles(this);

		HealthComp.OnStartDying.UnbindObject(this);

		FSanctuaryBossMedallionManagerEventPlayerAttackData Params;
		Params.AttackType = EMedallionHydraAttack::SidescrollerSpam;
		Params.Hydra = Hydra;
		Params.TargetPlayer = Player;

		UMedallionHydraAttackManagerEventHandler::Trigger_OnSpamAttackStop(RefsComp.Refs.HydraAttackManager, Params);
	}

	UFUNCTION()
	private void HandlePlayerDeath()
	{
		QueueComp.Empty();
		QueueComp.Event(this, n"Deactivate");
	}

	UFUNCTION()
	private void HandlePhaseChanged(EMedallionPhase Phase, bool bNaturalProgression)
	{
		if (Phase == EMedallionPhase::Merge1 ||
			Phase == EMedallionPhase::Merge2 ||
			Phase == EMedallionPhase::Merge3)
		{
			if (bActive)
			{
				QueueComp.Empty();
				QueueComp.Event(this, n"Deactivate");
			}
		}
	}

	UFUNCTION()
	private void StopTelegraph()
	{
		BP_StopTelegraph();
		
		FSanctuaryBossMedallionManagerEventPlayerAttackData Params;
		Params.AttackType = EMedallionHydraAttack::SidescrollerSpam;
		Params.Hydra = Hydra;
		Params.TargetPlayer = Player;

		UMedallionHydraAttackManagerEventHandler::Trigger_OnSpamAttackStart(RefsComp.Refs.HydraAttackManager, Params);
	}

	UFUNCTION(BlueprintEvent)
	private void BP_StartTelegraph(){}

	UFUNCTION(BlueprintEvent)
	private void BP_StopTelegraph(){}
};