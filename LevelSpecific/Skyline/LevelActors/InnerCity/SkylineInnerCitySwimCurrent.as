
class ASkylineInnerCitySwimCurrent : AVolume
{
	default BrushColor = FLinearColor(0.0, 1.0, 0.5);
	default BrushComponent.LineThickness = 4.0;
	default BrushComponent.SetCollisionProfileName(n"TriggerOnlyPlayer");

	default SetActorTickEnabled(false);

	UPROPERTY(DefaultComponent)
	UArrowComponent CurrentDirection;
	default CurrentDirection.SetbAbsoluteScale(true);
	default CurrentDirection.SetRelativeScale3D(FVector(5.0, 5.0, 5.0));

	UPROPERTY(DefaultComponent)
	USceneComponent EntryLocationOuter;

	UPROPERTY(DefaultComponent)
	USceneComponent EntryLocationInner;

	UPROPERTY(Category = Settings, EditAnywhere)
	float CurrentStrength = 1000.0;

	TPerPlayer<UPlayerSwimmingComponent> OverlappingSwimComps;
	TPerPlayer<bool> StartedCurrent;

	UFUNCTION(BlueprintOverride)
	void ActorBeginOverlap(AActor OtherActor)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		UPlayerSwimmingComponent SwimComp = UPlayerSwimmingComponent::GetOrCreate(Player);
		OverlappingSwimComps[Player] = SwimComp;

		//SetActorTickEnabled(true);
	}

	UFUNCTION(BlueprintOverride)
	void ActorEndOverlap(AActor OtherActor)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		if (StartedCurrent[Player])
		{
			StartedCurrent[Player] = false;
			//SpeedEffect::ClearSpeedEffect(Player, this);
		}

		OverlappingSwimComps[Player] = nullptr;

		if (OverlappingSwimComps[Player.OtherPlayer] == nullptr)
			SetActorTickEnabled(false);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		for (AHazePlayerCharacter Player : Game::Players)
		{
			if (!Player.HasControl())
				continue;

			if (OverlappingSwimComps[Player] == nullptr)
				continue;

			if (OverlappingSwimComps[Player].InstigatedSwimmingState.Get() != EPlayerSwimmingActiveState::Active)
				continue;

			FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::ECC_Visibility);
			Trace.UseSphereShape(50.0);
			// Trace.DebugDrawOneFrame();
			Trace.IgnorePlayers();
			FHitResult HitResult = Trace.QueryTraceSingle(Player.ActorCenterLocation, EntryLocationInner.WorldLocation);
			if (HitResult.bBlockingHit)
			{
				FVector ToPipeCenter = (ActorLocation - Player.ActorCenterLocation).VectorPlaneProject(ActorForwardVector).GetSafeNormal();
				Player.AddMovementImpulse(ToPipeCenter * CurrentStrength * DeltaSeconds);
			}
			else
			{
				Player.AddMovementImpulse(CurrentDirection.ForwardVector * CurrentStrength * DeltaSeconds);
			}

			if (!StartedCurrent[Player])
			{
				//SpeedEffect::RequestSpeedEffect(Player, 1.0, this, EInstigatePriority::Normal);
				StartedCurrent[Player] = true;
			}
		}
	}
}