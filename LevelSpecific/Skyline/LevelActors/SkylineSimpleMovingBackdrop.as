struct FSkylineBackdropComponent
{
	USceneComponent SceneComp;
	FVector RelativeLocation;
}

struct FSkylineBackdropSegment
{
	FVector RelativeLocation;
	TArray<FSkylineBackdropComponent> RapidMoveComponents;
	TArray<FSkylineBackdropComponent> NormalMoveComponents;
}

class ASkylineSimpleMovingBackdrop : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(EditAnywhere)
	TArray<AActor> Segments;

	UPROPERTY(EditAnywhere)
	float Speed = 5000.0;

	UPROPERTY(EditAnywhere)
	float SpeedMultiplier = 2.5;

	UPROPERTY(EditAnywhere)
	float SegmentLength = 50000.0;

	UPROPERTY(EditAnywhere)
	FVector MovingDirection = FVector::ForwardVector;

	UPROPERTY(EditAnywhere)
	bool bStartHidden = false;

	float Distance = 0.0;
	int WrapSegmentIndex = 0;
	int NumOfSegments = 0;

	TArray<AActor> Actors;
	TArray<FSkylineBackdropSegment> SegmentData;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Segments.Remove(nullptr);
		NumOfSegments = Segments.Num();

		// Set segments to Movable and disable all collisions
		for (int i = 0; i < NumOfSegments; i++)
		{
			Segments[i].RootComponent.SetMobility(EComponentMobility::Movable);
			TArray<AActor> AttachedActors;
			Segments[i].GetAttachedActors(AttachedActors, true, true);
			AttachedActors.Add(Segments[i]);
//			for (auto AttachedActor : AttachedActors)
//				AttachedActor.SetActorEnableCollision(false);

			SegmentData.Add(FSkylineBackdropSegment());
			FSkylineBackdropSegment& BackdropSegment = SegmentData.Last();

			FVector SegmentWorldLocation = Segments[i].RootComponent.WorldLocation;
			BackdropSegment.RelativeLocation = ActorTransform.InverseTransformPositionNoScale(SegmentWorldLocation);

			TArray<USceneComponent> SceneComps;
			for (auto Actor : AttachedActors)
			{
				if (Actor.IsA(AWorldSettings))
					continue;

				SceneComps.Reset();
				Actor.GetComponentsByClass(SceneComps);
				Actors.Add(Actor);

				for (auto SceneComp : SceneComps)
				{
					FSkylineBackdropComponent Backdrop;
					Backdrop.SceneComp = SceneComp;
					Backdrop.RelativeLocation = SceneComp.WorldLocation - SegmentWorldLocation;

					SceneComp.SetAbsolute(true, true, true);

					if (SceneComp.IsA(UNiagaraComponent))
						BackdropSegment.NormalMoveComponents.Add(Backdrop);
					else
						BackdropSegment.RapidMoveComponents.Add(Backdrop);
				}
			}
		}

		for (auto Actor : Actors)
			Actor.AddActorCollisionBlock(this);

		SetHidden(bStartHidden);
	}

	UFUNCTION()
	void SetHidden(bool bIsHidden)
	{
		for (auto Actor : Actors)
			Actor.SetActorHiddenInGame(bIsHidden);		
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (NumOfSegments == 0)
			return;

		float Delta = Speed * SpeedMultiplier * DeltaSeconds;

		Distance += Delta;

		if (Distance > SegmentLength)
		{
			Distance -= SegmentLength;
			SegmentData[WrapSegmentIndex].RelativeLocation += MovingDirection * SegmentLength * NumOfSegments;
			WrapSegmentIndex = Math::WrapIndex(WrapSegmentIndex + 1, 0, NumOfSegments);
		}

		FVector BobbingOffset = FVector::UpVector * Math::Sin(Time::GameTimeSeconds * 2.1) * 250.0; // 2.1 * 70.0
		BobbingOffset += FVector::RightVector * Math::Sin(Time::GameTimeSeconds * 2.7) * 50.0; // 0.7 * 60.0

		// Move all segments
		FTransform RootTransform = GetActorTransform();
		for (int i = 0; i < NumOfSegments; i++)
		{
			FSkylineBackdropSegment& Segment = SegmentData[i];
			Segment.RelativeLocation -= MovingDirection * Delta;

			FVector SegmentWorldLocation = RootTransform.TransformPositionNoScale(Segment.RelativeLocation + BobbingOffset);
			for (FSkylineBackdropComponent Backdrop : Segment.RapidMoveComponents)
			{
				SceneComponent::RapidChangeComponentLocation(
					Backdrop.SceneComp, SegmentWorldLocation + Backdrop.RelativeLocation
				);
			}
			for (FSkylineBackdropComponent Backdrop : Segment.NormalMoveComponents)
			{
				Backdrop.SceneComp.SetWorldLocation(SegmentWorldLocation + Backdrop.RelativeLocation);
			}
		}
	}
}