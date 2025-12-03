class AMedallionHydraArcSprayAttackActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent RotationRoot;

	UPROPERTY(DefaultComponent, Attach = RotationRoot)
	USceneComponent HeadRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent BodyRoot;

	UPROPERTY(DefaultComponent, Attach = HeadRoot)
	UGodrayComponent GodrayComp;

	UPROPERTY(DefaultComponent, Attach = HeadRoot)
	USceneComponent ProjectileLaunchRoot;

	ASanctuaryBossMedallionHydra Hydra;

	UPROPERTY(DefaultComponent)
	UHazeActionQueueComponent MovementQueueComp;

	UPROPERTY(DefaultComponent)
	UHazeActionQueueComponent ProjectilesQueueComp;

	UPROPERTY(DefaultComponent)
	USanctuaryBossSplineMovementComponent SplineComp;

	UPROPERTY()
	TSubclassOf<AMedallionHydra2DProjectile> ProjectileClass;

	UPROPERTY(EditInstanceOnly)
	EHazePlayer TargetPlayer;
	AHazePlayerCharacter Player;

	//Settings
	const float ProjectileInterval = 0.35;
	const int ProjectilesToSpawn = 9;
	const float RetractDuration = 1.0;
	const float Scale = 1.75;
	const float ProjectileSpeed = 1500.0;
	const float ForwardsOffset = 3000.0;
	const int Bursts = 2;

	float PlayerSign = 1.0;
	bool bActive = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (TargetPlayer == EHazePlayer::Zoe)
			PlayerSign = -1.0;

		Player = Game::GetPlayer(TargetPlayer);
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

		float PlayerXLocation = SplineComp.ConvertWorldLocationToSplineLocation(Player.ActorLocation).X;
		float TargetXLocation = PlayerXLocation + ForwardsOffset * PlayerSign;
		FVector2D TargetLocation = FVector2D(TargetXLocation, SplineComp.GetSplineLocation().Y);
		SplineComp.SetSplineLocation(TargetLocation);
		SetActorRotation(SplineComp.Spline.GetWorldRotationAtSplineDistance(TargetXLocation));

		Hydra = HydraActor;

		Hydra.BlockLaunchProjectiles(this);

		Hydra.MoveHeadPivotComp.ApplyHeadPivot(this, HeadRoot, EMedallionHydraMovePivotPriority::High, 1.0);
		Hydra.MoveActorComp.ApplyTransform(this, BodyRoot, EMedallionHydraMovePivotPriority::High, 1.0);

		GodrayComp.SetGodrayOpacity(1.0);

		for (int i = 0; i < Bursts; i++)
		{
			float ForwardMovementDuration = (ProjectilesToSpawn - 1) * ProjectileInterval;
			MovementQueueComp.Event(this, n"Roar", ForwardMovementDuration);
			MovementQueueComp.Duration(ForwardMovementDuration, this, n"MovementUpdate");

			if (i < Bursts -1)
			{
				MovementQueueComp.ReverseDuration(RetractDuration, this, n"MovementUpdate");
			}

			for (int a = 0; a < ProjectilesToSpawn; a++)
			{
				ProjectilesQueueComp.Event(this, n"LaunchProjectile");
				ProjectilesQueueComp.Idle(ProjectileInterval);
			}

			ProjectilesQueueComp.Idle(RetractDuration - ProjectileInterval);
		}

		MovementQueueComp.Event(this, n"Deactivate");
	}

	UFUNCTION()
	private void Roar(float Duration = -1.0)
	{
		Hydra.OneshotAnimation(EFeatureTagMedallionHydra::Roar, AnimationDuration = Duration);
	}

	UFUNCTION()
	private void LaunchProjectile()
	{
		auto Projectile = SpawnActor(ProjectileClass, ProjectileLaunchRoot.WorldLocation, ProjectileLaunchRoot.WorldRotation, bDeferredSpawn = true);
		Projectile.SetActorScale3D(FVector::OneVector * Scale);
		Projectile.Speed = ProjectileSpeed;
		FinishSpawningActor(Projectile);
	}

	UFUNCTION()
	private void MovementUpdate(float Alpha)
	{
		RotationRoot.SetRelativeRotation(FRotator(Math::Lerp(45.0 * PlayerSign, -45.0 * PlayerSign, Alpha), 0.0, 0.0));
	}

	UFUNCTION()
	private void Deactivate()
	{
		Hydra.ClearBlockLaunchProjectiles(this);
		Hydra.MoveHeadPivotComp.Clear(this);
		Hydra.MoveActorComp.Clear(this);

		bActive = false;

		GodrayComp.SetGodrayOpacity(0.0);
	}
};