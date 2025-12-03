UCLASS(Abstract)
class ABounceBubble : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent BubbleRoot;

	UPROPERTY(DefaultComponent, Attach = BubbleRoot)
	UStaticMeshComponent BubbleMesh;

	UPROPERTY(DefaultComponent, Attach = BubbleRoot)
	USphereComponent BounceTrigger;

	bool bMoving = true;

	ABounceBubbleSpawner BubbleSpawner = nullptr;
	ASplineActor TargetSpline;
	UHazeSplineComponent SplineComp;
	float SplineDistance = 0.0;
	float SplineSpeed = 400.0;

	bool bInitialized = false;

	bool bBursted = false;

	float BounceVelocity = 2500.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		BounceTrigger.OnComponentBeginOverlap.AddUFunction(this, n"EnterTrigger");
	}

	UFUNCTION()
	private void EnterTrigger(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep, const FHitResult&in SweepResult)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		if (Player.HasControl())
		{
			UPlayerPigRainbowFartComponent PlayerFartComp = UPlayerPigRainbowFartComponent::Get(Player);
			if(PlayerFartComp != nullptr)
			{
				PlayerFartComp.ResetCanFart();

				if(PlayerFartComp.IsFarting())
				{
					FVector NewVelocity = Player.GetActorVerticalVelocity();
					NewVelocity.Z = Math::Clamp(NewVelocity.Z + Pig::RainbowFart::BounceBubbleExtraVerticalVelocity, 0.0, Pig::RainbowFart::BounceBubbleMaxVerticalVelocity);
					Player.SetActorVerticalVelocity(NewVelocity);
				}
				else
				{
					Player.SetActorVerticalVelocity(FVector(0.0, 0.0, BounceVelocity));
				}
			}
			else 
			{
				Player.SetActorVerticalVelocity(FVector(0.0, 0.0, BounceVelocity));
			}

			Net_BurstBubble(Player);
		}
	}

	void SpawnBubble(float Speed, float Dist, ASplineActor Spline = nullptr, ABounceBubbleSpawner Spawner = nullptr)
	{
		if (Spline != nullptr)
		{
			TargetSpline = Spline;
			SplineComp = TargetSpline.Spline;
			SplineDistance = Dist;
		}

		BubbleSpawner = Spawner;
		SplineSpeed = Speed;
		bInitialized = true;

		BP_SpawnBubble();

		UBounceBubbleEffectEventHandler::Trigger_BubbleSpawned(this);
	}

	UFUNCTION(BlueprintEvent)
	void BP_SpawnBubble() {}

	UFUNCTION()
	void DestroyBubble()
	{
		DestroyActor();
	}

	UFUNCTION(BlueprintEvent)
	void BP_BurstBubble() {}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (!bInitialized)
			return;

		if (bBursted)
			return;

		if (!bMoving)
			return;

		if (SplineComp != nullptr)
		{
			SplineDistance += SplineSpeed * DeltaTime;
			SetActorLocation(SplineComp.GetWorldLocationAtSplineDistance(SplineDistance));

			if (SplineDistance >= SplineComp.SplineLength)
			{
				BurstBubble();
				UBounceBubbleEffectEventHandler::Trigger_BubbleBurstOnWall(this);
			}
		}
	}

	void BurstBubble()
	{
		if (bBursted)
			return;

		bBursted = true;

		BP_BurstBubble();

		SetActorEnableCollision(false);
		SetActorHiddenInGame(true);

		Timer::SetTimer(this, n"DestroyBubble", 0.5);
	}

	UFUNCTION(NetFunction)
	void Net_BurstBubble(AHazePlayerCharacter Player)
	{
		BurstBubble();

		// Trigger spawner event
		if (BubbleSpawner != nullptr)
		{
			FBubbleHintEventHandlerParams EventParams;
			EventParams.Player = Player;
			UBounceBubbleSpawnerEventHandler::Trigger_BounceOnBubble(BubbleSpawner, EventParams);
		}

		// Trigger bubble event
		UBounceBubbleEffectEventHandler::Trigger_PlayerBounced(this);
	}
}