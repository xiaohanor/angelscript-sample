class ASummitFlyingBirdFlockPosition : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent BirdSystem;
	UNiagaraSystem BirdSystemReference;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent Visual;
	default Visual.SetWorldScale3D(FVector(5.0));
#endif

	UPROPERTY(EditAnywhere)
	ASplineActor SplineActor;

	UPROPERTY(EditAnywhere)
	bool bScatterEnabled = true;
	
	UPROPERTY(EditAnywhere)
	bool bStartActive = true;

	UPROPERTY(EditAnywhere)
	float Speed = 1500.0;

	UPROPERTY()
	FHazeAcceleratedVector BirdMiddleLoc;

	UHazeSplineComponent Spline;
	FSplinePosition SplinePos;

	bool bActivated = true;
	
	float PlayerRadius = 2500.0;
	float FlockRadius = 3500.0;
	bool bPlayerIsIntersectingBirds = false;
	AHazePlayerCharacter ScatteringPlayer = nullptr;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (SplineActor != nullptr)
		{
			Spline = UHazeSplineComponent::Get(SplineActor);
			SplinePos = Spline.GetClosestSplinePositionToWorldLocation(ActorLocation);
		}

		if (!bStartActive)
			bActivated = false;

		BirdMiddleLoc.SnapTo(BirdSystem.WorldLocation);

		if(bScatterEnabled == false)
		{
			// disable niagara scatter
			BirdSystem.SetNiagaraVariableFloat("ScatterStrength", 0.0);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		// use the same spring as in Niagara to approximate the center location of the flock. 
		BirdMiddleLoc.SpringTo(BirdSystem.WorldLocation, 1.0, 0.6, DeltaSeconds);
		USummitFlyingBirdFlockEventHandler::Trigger_UpdateLocation(this, FSummitFlyingBirdFlockParams(BirdMiddleLoc.Value));

		if(!bActivated)
			return;

		// mimic niagara scatter behaviour for audio events.
		UpdateIntersectingEvents();
		
		if (SplineActor != nullptr)
		{
			SplinePos.Move(Speed * DeltaSeconds);	
			SetActorLocationAndRotation(SplinePos.WorldLocation, SplinePos.WorldRotation);
		}
	}

	void UpdateIntersectingEvents()
	{
		if(bScatterEnabled == false)
			return;

		bool bPlayerWasIntersectingBirds = bPlayerIsIntersectingBirds;

		// reset
		bPlayerIsIntersectingBirds = false;
		ScatteringPlayer = nullptr;

		for (AHazePlayerCharacter Player : Game::Players)
		{
			bool bIntersecting = Math::AreSpheresIntersecting(
				Player.ActorCenterLocation,
				PlayerRadius,
				BirdMiddleLoc.Value,
				FlockRadius	
			);

			// Debug::DrawDebugSphere(
			// 	Player.ActorCenterLocation,
			// 	PlayerRadius,
			// 	32,
			// 	bPlayerWasIntersectingBirds ? FLinearColor::Green : FLinearColor::Red,
			// 	20,
			// 	0.0
			// );

			// Debug::DrawDebugSphere(
			// 	BirdMiddleLoc.Value,
			// 	FlockRadius,
			// 	32,
			// 	bPlayerWasIntersectingBirds ? FLinearColor::Green : FLinearColor::Red,
			// 	20,
			// 	0.0
			// );

			if(bIntersecting)
			{
				bPlayerIsIntersectingBirds = true;
				ScatteringPlayer = Player;
				break;
			}
		}

		auto EventData = FSummitFlyingBirdFlockParams(BirdMiddleLoc.Value, ScatteringPlayer);
		// auto EventData = FSummitFlyingBirdFlockParams(BirdMiddleLoc.Value);

		if(bPlayerIsIntersectingBirds)
		{
			if(bPlayerWasIntersectingBirds == false)
			{
				USummitFlyingBirdFlockEventHandler::Trigger_StartScatter(this);
			}
		}
		else if(bPlayerWasIntersectingBirds)
		{
			USummitFlyingBirdFlockEventHandler::Trigger_StopScatter(this);
		}

	}

	UFUNCTION()
	void ActivateFlock()
	{
		bActivated = true;
	}

	UFUNCTION()
	void DeactivateFlock()
	{
		bActivated = false;
	}
}