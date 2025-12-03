struct FSanctuaryGhostSplineVolume
{
	UPROPERTY()
	float StartDistance = 0.0;

	UPROPERTY()
	float Speed = 500.0;

	FSplinePosition SplinePosition;
	float BaseWidth = 0.0;

	UPROPERTY()
	FVector2D Width = FVector2D(-1.0, 1.0);

	UPROPERTY()
	FVector2D Height = FVector2D(-1.0, 1.0);

	UPROPERTY()
	FVector2D Length = FVector2D(0.0, 500.0);


	UNiagaraComponent NiagaraComponent;
	
	

	void Initialize(UHazeSplineComponent Spline, float InBaseWidth)
	{
		BaseWidth = InBaseWidth;
		SplinePosition =  Spline.GetSplinePositionAtSplineDistance(StartDistance);	
		
	}

	void Move(float DeltaSeconds)
	{
		float RemainingDistance = 0.0;
		if (!SplinePosition.Move(Speed * DeltaSeconds, RemainingDistance))
			SplinePosition = SplinePosition.CurrentSpline.GetSplinePositionAtSplineDistance(RemainingDistance);
	
		if (NiagaraComponent == nullptr)
			return;

		NiagaraComponent.WorldTransform = NiagaraTransform;
		NiagaraComponent.SetNiagaraVariableFloat("LifeTime", (Math::Abs(Length.X) / Speed) * 2.0);
		NiagaraComponent.SetNiagaraVariableVec3("Size", FVector(500.0, (Width.Y - Width.X) * BaseWidth, (Height.Y - Height.X) * BaseWidth));

		// let niagara know where on the spline it is.
		float CurrentSplineFraction = 0.0;
		const float CurrentSplineLength = SplinePosition.CurrentSpline.SplineLength;
		if(CurrentSplineLength > KINDA_SMALL_NUMBER)
			CurrentSplineFraction = Math::Saturate(SplinePosition.CurrentSplineDistance / CurrentSplineLength);
		NiagaraComponent.SetNiagaraVariableFloat("CurrentSplineFraction", CurrentSplineFraction);
		NiagaraComponent.SetNiagaraVariableFloat("WalkingSpeed", Speed);

//		NiagaraComponent.SetNiagaraVariableFloat("Scale", SplinePosition.WorldScale3D.Size() * 0.5);
	}

	bool IsInsideVolume(FVector WorldLocation, float Radius = 0.0)
	{
		FVector Location = GetSplineRelativeLocation(WorldLocation);
		FTransform TransformAtLocation = SplinePosition.CurrentSpline.GetWorldTransformAtSplineDistance(Location.X);

//		PrintToScreen("Location: " + Location, 0.0, FLinearColor::Green);

		float Distance = SplinePosition.CurrentSplineDistance;

		if (Location.X > Distance + Length.X - Radius && Location.X < Distance + Length.Y + Radius)
			if (Location.Y > Width.X * TransformAtLocation.Scale3D.Y * BaseWidth - Radius && Location.Y < Width.Y * TransformAtLocation.Scale3D.Y * BaseWidth + Radius)
				if (Location.Z > Height.X * TransformAtLocation.Scale3D.Z * BaseWidth - Radius && Location.Z < Height.Y * TransformAtLocation.Scale3D.Z * BaseWidth + Radius)
					return true;

		return false;
	}

	FVector GetSplineRelativeLocation(FVector WorldLocation)
	{
		float SplineDistance = SplinePosition.CurrentSpline.GetClosestSplineDistanceToWorldLocation(WorldLocation);
		FTransform Transform = SplinePosition.CurrentSpline.GetWorldTransformAtSplineDistance(SplineDistance);

		FVector Location = Transform.InverseTransformPositionNoScale(WorldLocation);
		Location.X = SplineDistance + Location.X;

		return Location;
	}

	FTransform GetNiagaraTransform() property
	{
		FTransform FrontTransform = SplinePosition.CurrentSpline.GetWorldTransformAtSplineDistance(SplinePosition.CurrentSplineDistance + Length.Y);
		FVector Center = FVector(0.0, (Width.X + Width.Y) * 0.5, (Height.X + Height.Y) * 0.5) * BaseWidth;

		FTransform Transform = FrontTransform;
		Transform.Location = FrontTransform.TransformPosition(Center);

//		Debug::DrawDebugPoint(FrontTransform.TransformPosition(Center), 50.0, FLinearColor::Blue, 0.0);		

		return Transform;
	}

	void GetFrontAndBackLocations(FVector& Front, FVector& Back) const
	{
		Front = SplinePosition.CurrentSpline.GetWorldLocationAtSplineDistance(SplinePosition.CurrentSplineDistance + Length.Y);
		Back = SplinePosition.CurrentSpline.GetWorldLocationAtSplineDistance(SplinePosition.CurrentSplineDistance + Length.X);
	}

/*
	void DrawDebug()
	{
		Debug::DrawDebugPoint(SplinePosition.WorldLocation, 10.0, FLinearColor::Red, 0.0);		

		FTransform FrontTransform = SplinePosition.CurrentSpline.GetWorldTransformAtSplineDistance(SplinePosition.CurrentSplineDistance + Length.Y);
		FTransform BackTransform = SplinePosition.CurrentSpline.GetWorldTransformAtSplineDistance(SplinePosition.CurrentSplineDistance + Length.X);

		FVector TL = FVector(0.0, Width.X, Height.Y) * BaseWidth;
		FVector TR = FVector(0.0, Width.Y, Height.Y) * BaseWidth;
		FVector BL = FVector(0.0, Width.X, Height.X) * BaseWidth;
		FVector BR = FVector(0.0, Width.Y, Height.X) * BaseWidth;

		Debug::DrawDebugLine(BackTransform.TransformPosition(TL), BackTransform.TransformPosition(TR), FLinearColor::Red, 5.0, 0.0);
		Debug::DrawDebugLine(BackTransform.TransformPosition(BL), BackTransform.TransformPosition(BR), FLinearColor::Red, 5.0, 0.0);
		Debug::DrawDebugLine(FrontTransform.TransformPosition(TL), FrontTransform.TransformPosition(TR), FLinearColor::Red, 5.0, 0.0);
		Debug::DrawDebugLine(FrontTransform.TransformPosition(BL), FrontTransform.TransformPosition(BR), FLinearColor::Red, 5.0, 0.0);

		Debug::DrawDebugLine(BackTransform.TransformPosition(TL), BackTransform.TransformPosition(BL), FLinearColor::Red, 5.0, 0.0);
		Debug::DrawDebugLine(BackTransform.TransformPosition(TR), BackTransform.TransformPosition(BR), FLinearColor::Red, 5.0, 0.0);
		Debug::DrawDebugLine(FrontTransform.TransformPosition(TL), FrontTransform.TransformPosition(BL), FLinearColor::Red, 5.0, 0.0);
		Debug::DrawDebugLine(FrontTransform.TransformPosition(TR), FrontTransform.TransformPosition(BR), FLinearColor::Red, 5.0, 0.0);

		float LineLength = (Length.Y - Length.X);
		float LineStart = SplinePosition.CurrentSplineDistance + Length.X;

		DrawDebugSplineLine(TL, LineStart, LineLength);
		DrawDebugSplineLine(TR, LineStart, LineLength);
		DrawDebugSplineLine(BL, LineStart, LineLength);
		DrawDebugSplineLine(BR, LineStart, LineLength);
	}*/

	void DrawDebugSplineLine(FVector Offset, float LineStartDistance, float LineLength)
	{
		float SegmentLenght = 50.0;
		int Segments = Math::FloorToInt(LineLength / SegmentLenght);
		SegmentLenght = LineLength / Segments;

		for (int i = 0; i < Segments; i++)
		{
			FVector LineStart;
			FVector LineEnd;

			LineStart = SplinePosition.CurrentSpline.GetWorldTransformAtSplineDistance(LineStartDistance + i * SegmentLenght).TransformPosition(Offset);
			LineEnd = SplinePosition.CurrentSpline.GetWorldTransformAtSplineDistance(LineStartDistance + (i + 1) * SegmentLenght).TransformPosition(Offset);
			Debug::DrawDebugLine(LineStart, LineEnd, FLinearColor::Red, 5.0, 0.0);
		}
	}
}

class ASanctuaryGhostSpline : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeSplineComponent Spline;
	default Spline.EditingSettings.bEnableVisualizeScale = true;
	default Spline.EditingSettings.VisualizeScale = 100.0;

	UPROPERTY(DefaultComponent)
	UBoxComponent Trigger;

	TArray<AHazePlayerCharacter> Players;

	UPROPERTY(EditAnywhere)
	TArray<FSanctuaryGhostSplineVolume> SplineVolumes;

	UPROPERTY(EditAnywhere)
	float BaseWidth = 100.0;

	
	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UDeathEffect> DeathEffect;

	UPROPERTY(EditAnywhere)
	UNiagaraSystem GhostVFX;
	TArray<UNiagaraComponent> NiagaraComponents;

	// Used by ASanctuaryBelowMusicTrainManager
	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComponent;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		// Find the widest part of the spline
		float MaxScale = 0.0;
		for (auto SplinePoint : Spline.SplinePoints)
		{
			float SplinePointMaxScale = Math::Max(SplinePoint.RelativeScale3D.Y, SplinePoint.RelativeScale3D.Z);
			if (SplinePointMaxScale > MaxScale)
				MaxScale = SplinePointMaxScale;
		}

		// Add margin to trigger based on widest part
		Spline.PositionBoxComponentToContainEntireSpline(Trigger, MaxScale * BaseWidth);
	
		Trigger.OnComponentBeginOverlap.AddUFunction(this, n"HandleBeginOverlap");
		Trigger.OnComponentEndOverlap.AddUFunction(this, n"HandleEndOverlap");

		for (auto& SplineVolume : SplineVolumes)
		{
			SplineVolume.Initialize(Spline, BaseWidth);
			auto NiagaraComponent = Niagara::SpawnLoopingNiagaraSystemAttachedAtLocation(GhostVFX, Spline, SplineVolume.NiagaraTransform.Location);
			SplineVolume.NiagaraComponent = NiagaraComponent;
			NiagaraComponents.Add(NiagaraComponent);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
//		DrawDebug();

		for (auto& SplineVolume : SplineVolumes)
		{
			SplineVolume.Move(DeltaSeconds);
			//SplineVolume.DrawDebug();

			for (auto Player : Players)
			{
				 //Debug::DrawDebugSphere(Player.ActorCenterLocation, Player.CapsuleComponent.CapsuleRadius, 12, FLinearColor::Green, 1.0, 0.0);		

				if (SplineVolume.IsInsideVolume(Player.ActorCenterLocation, Player.CapsuleComponent.CapsuleRadius))
				{
					//Debug::DrawDebugCapsule(Player.CapsuleComponent.GetBoundsOrigin(), Player.CapsuleComponent.CapsuleHalfHeight, Player.CapsuleComponent.CapsuleRadius, Player.CapsuleComponent.WorldRotation, FLinearColor::Red, 5.0, 0.0);	
					Player.KillPlayer(DeathEffect = DeathEffect);
				}
			}
		}
	}

	UFUNCTION()
	private void HandleBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep, const FHitResult&in SweepResult)
	{
		auto Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		Players.Add(Player);
	}

	UFUNCTION()
	private void HandleEndOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComp, int OtherBodyIndex)
	{
		auto Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		Players.Remove(Player);
	}

/*
	void DrawDebug()
	{
		Debug::DrawDebugBox(Trigger.WorldLocation, Trigger.BoxExtent, Trigger.WorldRotation, FLinearColor::Red, 5.0, 0.0);

		float SegmentLenght = 50.0;
		int Segments = Math::FloorToInt(Spline.SplineLength / SegmentLenght);
		SegmentLenght = Spline.SplineLength / Segments;

		for (int i = 0; i <= Segments; i++)
		{
			FVector LineStart;
			FVector LineEnd;

			LineStart = Spline.GetWorldTransformAtSplineDistance(i * SegmentLenght).Location;
			LineEnd = Spline.GetWorldTransformAtSplineDistance((i + 1) * SegmentLenght).Location;
			Debug::DrawDebugLine(LineStart, LineEnd, FLinearColor::Yellow, 5.0, 0.0);
		}
	}*/

	FVector GetSplineRelativeLocation(FVector WorldLocation)
	{
		float SplineDistance = Spline.GetClosestSplineDistanceToWorldLocation(WorldLocation);
		FTransform Transform = Spline.GetWorldTransformAtSplineDistance(SplineDistance);

		FVector Location = Transform.InverseTransformPositionNoScale(WorldLocation);
		Location.X = SplineDistance;

		return Location;
	}
};