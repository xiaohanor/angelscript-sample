class AMeltdownBossBaseOneSearchlight : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UEditorBillboardComponent Billboard;
#endif

	UPROPERTY(DefaultComponent)
	UHazeSplineComponent Path;

	UPROPERTY(DefaultComponent)
	USceneComponent CurrentPosition;

	UPROPERTY(DefaultComponent, NotEditable, Attach = CurrentPosition)
	UMeltdownBossCubeGridDisplacementComponent TelegraphDisplacement;
	default TelegraphDisplacement.Type = EMeltdownBossCubeGridDisplacementType::Shape;
	default TelegraphDisplacement.bInfiniteHeight = true;
	default TelegraphDisplacement.Redness = -1.0;
	default TelegraphDisplacement.Displacement = FVector(0, 0, 1);
	default TelegraphDisplacement.LerpDistance = 150.0;

	UPROPERTY(EditAnywhere)
	float Speed = 500.0;
	UPROPERTY(EditAnywhere)
	float Radius = 350.0;
	UPROPERTY(EditAnywhere)
	float LingerDuration = 2.5;

	UPROPERTY(EditAnywhere, Category = "Missile Attack")
	AMeltdownBossPhaseOneMissileAttack MissileToTrigger;

	UPROPERTY(EditAnywhere, Category = "Smash Attack")
	AMeltdownBossPhaseOneSmashAttack SmashAttackToTrigger;
	UPROPERTY(EditAnywhere, Category = "Smash Attack")
	float SmashAttackTelegraphTime = 2.0;
	UPROPERTY(EditAnywhere, Category = "Smash Attack")
	float SmashAttackTrackDuration = 0.0;

	private FSplinePosition SplinePosition;
	private bool bTriggered = false;
	private float LingerTimer = 0.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AddActorDisable(this);
	}

	UFUNCTION(DevFunction)
	void StartSearchlight()
	{
		SplinePosition = Path.GetSplinePositionAtSplineDistance(0.0);
		LingerTimer = 0.0;
		bTriggered = false;

		TelegraphDisplacement.Shape = FHazeShapeSettings::MakeSphere(Radius);
		TelegraphDisplacement.ActivateDisplacement();
		RemoveActorDisable(this);
	}

	void Trigger(AHazePlayerCharacter Player)
	{
		if (bTriggered)
			return;

		bTriggered = true;
		LingerTimer = LingerDuration;

		if (MissileToTrigger != nullptr)
		{
			FVector Offset = MissileToTrigger.TelegraphRoot.WorldLocation - MissileToTrigger.ActorLocation;
			MissileToTrigger.ActorLocation = CurrentPosition.WorldLocation - Offset;
			MissileToTrigger.FireMissile();
		}
		else if (SmashAttackToTrigger != nullptr)
		{
			SmashAttackToTrigger.ActorLocation = CurrentPosition.WorldLocation;
			SmashAttackToTrigger.StartAttack(SmashAttackTelegraphTime, Player, SmashAttackTrackDuration);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bTriggered)
		{
			LingerTimer -= DeltaSeconds;
			if (LingerTimer <= 0.0)
				AddActorDisable(this);
		}
		else
		{
			bool bCouldMove = SplinePosition.Move(DeltaSeconds * Speed);
			CurrentPosition.WorldLocation = SplinePosition.WorldLocation;

			if (!bCouldMove)
				AddActorDisable(this);

			for (auto Player : Game::Players)
			{
				if (Player.ActorLocation.Dist2D(CurrentPosition.WorldLocation) < Radius)
				{
					Trigger(Player);
					break;
				}
			}
		}
	}
};