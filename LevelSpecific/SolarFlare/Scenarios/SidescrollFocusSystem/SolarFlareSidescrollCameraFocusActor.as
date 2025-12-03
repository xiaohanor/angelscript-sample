class ASolarFlareSidescrollCameraFocusActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UEditorBillboardComponent Visual;
	default Visual.SpriteName = "S_Pawn";
#endif

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListComp;

	float AccelDuration = 1.75;	

	FHazeAcceleratedVector AccelVec;
	
	UHazeSplineComponent SplineComp;
	ASolarFlareSideScrollSplineActor SplineActor;

	AHazePlayerCharacter Mio;
	AHazePlayerCharacter Zoe;

	FVector WorldOffset;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Mio = Game::Mio;
		Zoe = Game::Zoe;
		SetActorTickEnabled(false);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		AccelVec.AccelerateTo(GetTargetPosition(), AccelDuration, DeltaSeconds);
		ActorLocation = AccelVec.Value;
		// Debug::DrawDebugSphere(ActorLocation, 40.0, 12, FLinearColor::Green, 5.0);
		// Debug::DrawDebugSphere(GetTargetPosition(), 20.0, 12, FLinearColor::Red, 5.0);
	}

	UFUNCTION()
	void ActivateFocusTarget()
	{
		AccelVec.SnapTo(GetTargetPosition());
		ActorLocation = AccelVec.Value;
		SetActorTickEnabled(true);
	}

	UFUNCTION()
	void DeactivateFocusTarget()
	{
		SetActorTickEnabled(false);
	}

	void SetSpline(ASolarFlareSideScrollSplineActor NewSplineActor)
	{
		SplineActor = NewSplineActor;
		SplineComp = NewSplineActor.Spline;
	}

	void ClearSpline()
	{
		SplineActor = nullptr;
		SplineComp = nullptr;
	}

	FVector GetTargetPosition()
	{
		FVector AverageLoc = (Mio.ActorLocation + Zoe.ActorLocation) / 2;
		AverageLoc += WorldOffset;

		if (SplineActor == nullptr)
			return AverageLoc;

		FVector SplineLocation = SplineComp.GetClosestSplineWorldLocationToWorldLocation(AverageLoc);
		
		if (AverageLoc.Z > SplineLocation.Z + SplineActor.MaxZ)
			AverageLoc.Z = SplineLocation.Z + SplineActor.MaxZ;
		else if (AverageLoc.Z < SplineLocation.Z + SplineActor.MinZ)
			AverageLoc.Z = SplineLocation.Z + SplineActor.MinZ;	

		float ForwardOffset = (Mio.ActorLocation - Zoe.ActorLocation).ConstrainToPlane(FVector::UpVector).Size() * 0.42;
		AverageLoc -= FVector::ForwardVector * ForwardOffset;
		AverageLoc += FVector::RightVector * 220.0; //So camera is a bit more ahead of the players

		return AverageLoc;
	}

	void SetFocusTargetWorldOffset(FVector NewOffset)
	{
		WorldOffset = NewOffset;
	}
};