event void FRedSpaceAnomalyAnomalized();
event void FRedSpaceAnomalyRestored();

class ARedSpaceAnomaly : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent AnomalyRoot;
	
	UPROPERTY(DefaultComponent, Attach = AnomalyRoot)
	USphereComponent KillTrigger;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedActorComp;

	UPROPERTY(DefaultComponent)
	URedSpaceAnomalyVisualizerComponent VisualizerComp;

	UPROPERTY(EditAnywhere)
	float AffectDistance = 600.0;

	UPROPERTY(EditAnywhere)
	ERedSpaceAnomalyMode Mode;

	UPROPERTY(EditAnywhere, Meta = (EditCondition = "Mode == ERedSpaceAnomalyMode::Spread", EditConditionHides))
	ERedSpaceAnomalySpreadMode SpreadMode;

	UPROPERTY(EditAnywhere, Meta = (EditCondition = "Mode == ERedSpaceAnomalyMode::Spread", EditConditionHides))
	FVector2D SpreadRange = FVector2D(500.0, 550.0);

	UPROPERTY(EditAnywhere, Meta = (EditCondition = "Mode == ERedSpaceAnomalyMode::Contract", EditConditionHides))
	FVector2D ContractRange = FVector2D(10.0, 50.0);

	UPROPERTY(EditDefaultsOnly)
	UNiagaraSystem SpreadEffectSystem;
	TArray<UNiagaraComponent> SpreadEffectComps;

	UPROPERTY(EditAnywhere)
	float AnomalizeSpeed = 5.0;

	UPROPERTY()
	FRedSpaceAnomalyAnomalized OnAnomalized;

	UPROPERTY()
	FRedSpaceAnomalyRestored OnRestored;

	bool bAnomalized = false;
	bool bModeSet = false;

	bool bPermanentlyRestored = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		KillTrigger.OnComponentBeginOverlap.AddUFunction(this, n"PlayerEnter");

		Anomalize();
	}

	UFUNCTION()
	private void PlayerEnter(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep, const FHitResult&in SweepResult)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		if (bAnomalized && Mode == ERedSpaceAnomalyMode::Contract)
			Player.KillPlayer();
	}

	UFUNCTION()
	void Restore()
	{
		if (bPermanentlyRestored)
			return;

		if (!bAnomalized)
			return;

		bAnomalized = false;
		
		for (ARedSpaceAnomalyPiece Piece : GetPieces())
		{
			Piece.Restore();
			Piece.PieceMeshComp.AddTag(ComponentTags::Walkable);
		}

		BP_Restore();

		for (UNiagaraComponent EffectComp : SpreadEffectComps)
			EffectComp.DestroyComponent(this);

		SpreadEffectComps.Empty();

		OnRestored.Broadcast();
	}

	UFUNCTION(BlueprintEvent)
	void BP_Restore() {}

	UFUNCTION()
	void PermanentlyRestore()
	{
		Restore();
		bPermanentlyRestored = true;
	}

	UFUNCTION()
	void Anomalize()
	{
		if (bPermanentlyRestored)
			return;

		if (bAnomalized)
			return;

		bAnomalized = true;

		if (!bModeSet)
		{
			bModeSet = true;
			for (ARedSpaceAnomalyPiece Piece : GetPieces())
			{
				Piece.Mode = Mode;
				Piece.Speed = AnomalizeSpeed;
			}
		}

		for (ARedSpaceAnomalyPiece Piece : GetPieces())
		{
			FTransform Transform;
			Transform.Rotation = FQuat(Math::GetRandomRotation());

			if (Mode == ERedSpaceAnomalyMode::Contract)
			{
				Transform.Location = Math::GetRandomPointInSphere() * Math::RandRange(ContractRange.X, ContractRange.Y);
		
				for (AHazePlayerCharacter Player : Game::GetPlayers())
				{
					if (Player.IsOverlappingActor(this))
						Player.KillPlayer();
				}
			}
			else
			{
				FVector OffsetDirection;
				if (SpreadMode == ERedSpaceAnomalySpreadMode::Sphere)
					OffsetDirection = Math::GetRandomPointInSphere();
				else if (SpreadMode == ERedSpaceAnomalySpreadMode::XAxis)
				{
					FVector2D Circle = Math::GetRandomPointOnCircle();
					OffsetDirection.Y = Circle.X;
					OffsetDirection.Z = Circle.Y;
				}
				else if (SpreadMode == ERedSpaceAnomalySpreadMode::YAxis)
				{
					FVector2D Circle = Math::GetRandomPointOnCircle();
					OffsetDirection.X = Circle.X;
					OffsetDirection.Z = Circle.Y;
				}
				else if (SpreadMode == ERedSpaceAnomalySpreadMode::ZAxis)
				{
					FVector2D Circle = Math::GetRandomPointOnCircle();
					OffsetDirection.X = Circle.X;
					OffsetDirection.Y = Circle.Y;
				}

				Transform.Location = (OffsetDirection * Math::RandRange(SpreadRange.X, SpreadRange.Y));

				UNiagaraComponent EffectComp = Niagara::SpawnLoopingNiagaraSystemAttached(SpreadEffectSystem, Piece.RootComp);
				SpreadEffectComps.Add(EffectComp);
			}
			
			Piece.Anomalize(Transform);
			Piece.PieceMeshComp.RemoveTag(ComponentTags::Walkable);
		}

		OnAnomalized.Broadcast();

		BP_Anomalize();
	}

	UFUNCTION(BlueprintEvent)
	void BP_Anomalize() {}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (Mode == ERedSpaceAnomalyMode::Spread)
		{
			if (bAnomalized)
			{
				int Index = 0;
				for (ARedSpaceAnomalyPiece Piece : GetPieces())
				{
					SpreadEffectComps[Index].SetNiagaraVariableVec3("BeamStart", Piece.ActorLocation);
					SpreadEffectComps[Index].SetNiagaraVariableVec3("BeamEnd", ActorLocation);
					Index++;
				}
			}
		}
	}

	TArray<ARedSpaceAnomalyPiece> GetPieces()
	{
		TArray<ARedSpaceAnomalyPiece> Pieces;

		TArray<AActor> Actors;
		GetAttachedActors(Actors, true);
		for (AActor Actor : Actors)
		{
			ARedSpaceAnomalyPiece Piece = Cast<ARedSpaceAnomalyPiece>(Actor);
			if (Piece != nullptr)
				Pieces.Add(Piece);
		}

		return Pieces;
	}
}

enum ERedSpaceAnomalyMode
{
	Contract,
	Spread
}

enum ERedSpaceAnomalySpreadMode
{
	Sphere,
	XAxis,
	YAxis,
	ZAxis
}

class URedSpaceAnomalyVisualizerComponent : UActorComponent
{

}

class UUVillageOgreCompComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = URedSpaceAnomalyVisualizerComponent;

    UFUNCTION(BlueprintOverride)
    void VisualizeComponent(const UActorComponent Component)
    {
		URedSpaceAnomalyVisualizerComponent Comp = Cast<URedSpaceAnomalyVisualizerComponent>(Component);
		if (Comp != nullptr)
		{
			ARedSpaceAnomaly Anomaly = Cast<ARedSpaceAnomaly>(Comp.Owner);
			if (Anomaly != nullptr)
			{
				FLinearColor Color = Anomaly.Mode == ERedSpaceAnomalyMode::Contract ? FLinearColor::Red : FLinearColor::Green;
				DrawWireSphere(Anomaly.ActorLocation, Anomaly.AffectDistance, Color, 2.0);
			}
		}
	}
}