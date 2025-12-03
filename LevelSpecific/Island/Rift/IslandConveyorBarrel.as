event void FIslandConveyorBarrelEvent(AIslandConveyorBarrel ExplodedBarrel);

class AIslandConveyorBarrel : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 20000.0;

	UPROPERTY(DefaultComponent)
	UBoxComponent TriggerBox;
	default TriggerBox.bGenerateOverlapEvents = false;
	default TriggerBox.CollisionEnabled = ECollisionEnabled::NoCollision;

	UPROPERTY(DefaultComponent, Attach = Root)
	UCameraShakeForceFeedbackComponent CamShakeFFComp;

	UPROPERTY(EditAnywhere)
	bool bDisableHook = false;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListComp;

	UPROPERTY()
	FIslandConveyorBarrelEvent OnExploded;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	UFUNCTION(BlueprintEvent)
	void BP_ResetBarrel()
	{
	}

	UFUNCTION(BlueprintEvent)
	void BP_RotateBarrel()
	{
	}

	UFUNCTION(BlueprintCallable)
	void BP_BarrelExploded()
	{
		OnExploded.Broadcast(this);

		CamShakeFFComp.ActivateCameraShakeAndForceFeedback();

		FHazeTraceSettings Trace = Trace::InitObjectType(EObjectTypeQuery::PlayerCharacter);
		Trace.UseSphereShape(300);
		FOverlapResultArray Overlaps = Trace.QueryOverlaps(ActorCenterLocation);
		for (FOverlapResult Overlap : Overlaps.OverlapResults)
		{
			if (Overlap.Actor == nullptr)
				continue;
			AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Overlap.Actor);
			if (Player == nullptr)
				continue;
		
			Player.DealTypedDamage(this, 0.5, EDamageEffectType::Explosion, EDeathEffectType::Explosion);			 

			float StumbleDistance = 300;
			float StumbleDuration = 0.5;
			if (StumbleDistance > 0.0)
			{
				FStumble Stumble;
				FVector StumbleMove = (Player.ActorLocation - ActorLocation).GetNormalizedWithFallback(-Player.ActorForwardVector).GetSafeNormal2D() * StumbleDistance;
				Stumble.Move = StumbleMove;
				Stumble.Duration = StumbleDuration;
				Player.ApplyStumble(Stumble);
			}
		}
	}
};

class AIslandConveyorBarrelTrigger : AHazeActor
{
	UPROPERTY(DefaultComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UBoxComponent Box;
	default Box.bGenerateOverlapEvents = false;
	default Box.CollisionEnabled = ECollisionEnabled::NoCollision;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 30000.0;

	UPROPERTY(EditAnywhere)
	bool bRotateBarrel = false;
	UPROPERTY(EditAnywhere)
	bool bResetBarrel = false;

	TArray<AIslandConveyorBarrel> OverlappingBarrels;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		FCollisionShape Shape = Box.GetCollisionShape();
		FTransform Transform = Box.WorldTransform;

		for (AIslandConveyorBarrel Barrel : TListedActors<AIslandConveyorBarrel>())
		{
			bool bOverlaps = Overlap::QueryShapeOverlap(
					Shape, Transform,
					Barrel.TriggerBox.GetCollisionShape(), Barrel.TriggerBox.WorldTransform
				);
			if (bOverlaps)
			{
				if (!OverlappingBarrels.Contains(Barrel))
				{
					if (bRotateBarrel)
						Barrel.BP_RotateBarrel();
					if (bResetBarrel)
						Barrel.BP_ResetBarrel();
					OverlappingBarrels.Add(Barrel);
				}
			}
			else
			{
				OverlappingBarrels.Remove(Barrel);
			}
		}
	}
}