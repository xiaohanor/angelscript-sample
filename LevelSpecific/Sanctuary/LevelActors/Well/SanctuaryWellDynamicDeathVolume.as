class ASanctuaryWellDynamicDeathVolume : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent BillboardComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UDeathTriggerComponent DeathTriggerComp;

	UPROPERTY(EditInstanceOnly)
	ASplineActor SplineActor;

	UPROPERTY(EditInstanceOnly)
	EHazePlayer Player;

	UPROPERTY(EditAnywhere)
	float SplineRadius = 500.0;

	UPROPERTY(EditAnywhere)
	float DeathVolumeHeightOffset = -500.0;

	UPROPERTY(EditInstanceOnly)
	bool bDebugging = false;

	float ProgressionAlongSpline = 0.0;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if (SplineActor != nullptr)
		{
			DeathTriggerComp.SetWorldLocation(ActorLocation);
		}
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorTickEnabled(false);
		SetActorControlSide(Game::GetPlayer(Player));

		if (Player == EHazePlayer::Mio)
			DeathTriggerComp.bKillsZoe = false;
		else
			DeathTriggerComp.bKillsMio = false;
	}

	UFUNCTION()
	void ActivateDeathVolume()
	{
		if (SplineActor != nullptr)
			SetActorTickEnabled(true);
		else
			PrintToScreen("Spline Actor Not Set!!", 10.0, FLinearColor::Red);
	}

	UFUNCTION()
	void DeactivateDeathVolume()
	{
		if (SplineActor != nullptr)
		{
			SetActorTickEnabled(false);
			DeathTriggerComp.DisableDeathTrigger(this);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		//Calculate Zoe Death Trigger

		FVector PlayerLocation = Game::GetPlayer(Player).ActorLocation;

		float DistanceToClosestSplinePoint = (SplineActor.Spline.GetClosestSplineWorldLocationToWorldLocation(PlayerLocation) - PlayerLocation).Size();

		if (DistanceToClosestSplinePoint < SplineRadius)
		{
			ProgressionAlongSpline = SplineActor.Spline.GetClosestSplineDistanceToWorldLocation(PlayerLocation);

			float DeathTriggerWorldZ = SplineActor.Spline.GetWorldLocationAtSplineDistance(ProgressionAlongSpline).Z + DeathVolumeHeightOffset;

			if (DeathTriggerWorldZ < ActorLocation.Z)
			{
				DeathTriggerComp.SetWorldLocation(FVector(ActorLocation.X, ActorLocation.Y, DeathTriggerWorldZ));
			}	
		}
		
		if (bDebugging)
		{
			Debug::DrawDebugSolidBox(DeathTriggerComp.WorldLocation, 
								DeathTriggerComp.Shape.BoxExtents * DeathTriggerComp.WorldScale, 
								DeathTriggerComp.WorldRotation, 
								FLinearColor(0.0, 1.0, 0.0, 0.2));
		}
	}
};