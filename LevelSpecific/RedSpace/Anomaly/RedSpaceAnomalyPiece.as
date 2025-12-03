class ARedSpaceAnomalyPiece : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent PieceRoot;

	UPROPERTY(DefaultComponent, Attach = PieceRoot)
	UStaticMeshComponent PieceMeshComp;

	ERedSpaceAnomalyMode Mode;

	bool bOriginalTransformSaved = false;

	bool bAnomalized = false;
	FTransform TargetTransform;
	FTransform OriginalTransform;

	float Speed = 5.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SaveOriginalTransform();
	}

	void Anomalize(FTransform Target)
	{
		if (!bOriginalTransformSaved)
			SaveOriginalTransform();

		bAnomalized = true;
		TargetTransform = Target;
	}

	void Restore()
	{
		bAnomalized = false;
		TargetTransform = OriginalTransform;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{	
		FVector Loc = Math::VInterpTo(ActorRelativeLocation, TargetTransform.Location, DeltaTime, Speed);
		FRotator Rot = Math::RInterpTo(ActorRelativeRotation, TargetTransform.Rotator(), DeltaTime, Speed);

		SetActorRelativeLocation(Loc);
		SetActorRelativeRotation(Rot);

		if (bAnomalized)
		{
			float RotSpeedMultiplier = Mode == ERedSpaceAnomalyMode::Contract ? 1.0 : 0.2;
			PieceRoot.AddLocalRotation(FRotator(150.0,100.0, 200.0) * RotSpeedMultiplier * DeltaTime);
		}
		else
		{
			FRotator PieceRot = Math::RInterpShortestPathTo(PieceRoot.RelativeRotation, FRotator::ZeroRotator, DeltaTime, 8.0);
			PieceRoot.SetRelativeRotation(PieceRot);
		}
	}

	void SaveOriginalTransform()
	{
		if (bOriginalTransformSaved)
			return;

		bOriginalTransformSaved = true;
		OriginalTransform = ActorRelativeTransform;
		TargetTransform = OriginalTransform;
	}
}