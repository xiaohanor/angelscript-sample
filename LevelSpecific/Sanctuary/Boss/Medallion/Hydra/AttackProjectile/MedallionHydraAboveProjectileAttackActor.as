class AMedallionHydraAboveProjectileAttackActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent HeadRoot;

	UPROPERTY(DefaultComponent, Attach = HeadRoot)
	UGodrayComponent GodrayComp;

	UPROPERTY(DefaultComponent, Attach = HeadRoot)
	USceneComponent ProjectileLaunchRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent BodyRoot;
	
	UPROPERTY(EditInstanceOnly)
	ASplineActor SplineActor;
	UHazeSplineComponent SplineComp;

	UPROPERTY(EditInstanceOnly)
	EHazePlayer TargetPlayer;
	AHazePlayerCharacter Player;

	UPROPERTY(DefaultComponent)
	UHazeActionQueueComponent QueueComp;

	UPROPERTY()
	TSubclassOf<AMedallionHydra2DProjectile> ProjectileClass;

	ASanctuaryBossMedallionHydra Hydra;

	//Settings
	const float ForwardStartOffset = 3000.0;
	const float MovementSpeed = 700.0;
	const float ProjectileInterval = 0.6;
	const int ProjectilesToLaunch = 13;
	const float ProjectileSpeed = 5000.0;
	const float ProjectileScale = 2.0;
	
	float PlayerSign = 1.0;
	bool bActive = false;

	float SplineProgress;
	FHazeAcceleratedFloat AccSplineProgress;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (TargetPlayer == EHazePlayer::Zoe)
			PlayerSign = -1.0;

		Player = Game::GetPlayer(TargetPlayer);

		SplineComp = UHazeSplineComponent::Get(SplineActor);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bActive)
		{
			SplineProgress += -MovementSpeed * DeltaSeconds * PlayerSign;
			AccSplineProgress.AccelerateTo(SplineProgress, 2.0, DeltaSeconds);

			FVector Location = SplineComp.GetWorldLocationAtSplineDistance(AccSplineProgress.Value);
			Location.Z = ActorLocation.Z;

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

		bActive = true;

		float PlayerSplineLocation = SplineComp.GetClosestSplineDistanceToWorldLocation(Player.ActorLocation);
		float TargetSplineLocation = PlayerSplineLocation + ForwardStartOffset * PlayerSign;

		SplineProgress = TargetSplineLocation;
		AccSplineProgress.SnapTo(SplineProgress);

		FVector Location = SplineComp.GetWorldLocationAtSplineDistance(AccSplineProgress.Value);
		Location.Z = ActorLocation.Z;

		FQuat Rotation = SplineComp.GetWorldRotationAtSplineDistance(AccSplineProgress.Value);

		SetActorLocation(Location);
		SetActorRotation(Rotation);

		GodrayComp.SetGodrayOpacity(2.0);

		Hydra = HydraActor;

		Hydra.MoveActorComp.ApplyTransform(this, BodyRoot, 
			EMedallionHydraMovePivotPriority::High, 
			2.0);
		Hydra.MoveHeadPivotComp.ApplyHeadPivot(this, HeadRoot, 
			EMedallionHydraMovePivotPriority::High, 
			2.0);

		Hydra.EnterMhAnimation(EFeatureTagMedallionHydra::Roar);

		QueueComp.Idle(1.0);

		for (int i = 0; i < ProjectilesToLaunch; i++)
		{
			QueueComp.Idle(ProjectileInterval);
			QueueComp.Event(this, n"LaunchProjectile");
		}

		QueueComp.Idle(ProjectileInterval);
		QueueComp.Event(this, n"Deactivate");

		Hydra.Refs.HydraAttackManager.OnPhaseChanged.AddUFunction(this, n"HandlePhaseChanged");
	}
	
	UFUNCTION()
	private void LaunchProjectile()
	{
		auto Projectile = SpawnActor(ProjectileClass, 
			ProjectileLaunchRoot.WorldLocation, 
			ProjectileLaunchRoot.WorldRotation, 
			bDeferredSpawn = true);

		Projectile.SetActorScale3D(FVector::OneVector * ProjectileScale);
		Projectile.Speed = ProjectileSpeed;
		FinishSpawningActor(Projectile);

		float PlayerSplineLocation = SplineComp.GetClosestSplineDistanceToWorldLocation(Player.ActorLocation);

		if (PlayerSplineLocation * PlayerSign > (SplineProgress + 1000.0 * PlayerSign) * PlayerSign)
		{
			QueueComp.Empty();
			QueueComp.Idle(ProjectileInterval);
			QueueComp.Event(this, n"Deactivate");
		}
	}

	UFUNCTION()
	private void Deactivate()
	{
		Hydra.ExitMhAnimation(EFeatureTagMedallionHydra::Roar);
		Hydra.MoveActorComp.Clear(this);
		Hydra.MoveHeadPivotComp.Clear(this);
		bActive = false;

		GodrayComp.SetGodrayOpacity(0.0);
	}

	UFUNCTION()
	private void HandlePhaseChanged(EMedallionPhase Phase, bool bNaturalProgression)
	{
		if (Phase == EMedallionPhase::Merge1 ||
			Phase == EMedallionPhase::Merge2 ||
			Phase == EMedallionPhase::Merge3)
		{
			QueueComp.Empty();
			QueueComp.Idle(ProjectileInterval);
			QueueComp.Event(this, n"Deactivate");
		}
	}
};