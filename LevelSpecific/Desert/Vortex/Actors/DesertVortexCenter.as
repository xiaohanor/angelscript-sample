struct FDesertVortexSpinningCenterLayer
{
	UPROPERTY(EditAnywhere)
	ADesertVortexSpinningCenter SpinningCenter;

	UPROPERTY(EditAnywhere)
	float EndDistance = 1000;

	// UPROPERTY(VisibleAnywhere)
	// TArray<AActor> Actors;

#if EDITOR
	UPROPERTY(EditAnywhere)
	FLinearColor Color = FLinearColor::White;
#endif

	int opCmp(const FDesertVortexSpinningCenterLayer Other) const
	{
		if(EndDistance > Other.EndDistance)
			return 1;
		else if(EndDistance < Other.EndDistance)
			return -1;

		return 0;
	}
}

UCLASS(NotBlueprintable)
class ADesertVortexCenter : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(EditInstanceOnly)
	TArray<FDesertVortexSpinningCenterLayer> SpinningLayers;

	// UPROPERTY(EditInstanceOnly)
	// TArray<TSubclassOf<AActor>> IgnoredActorClasses;
	// default IgnoredActorClasses.Add(ADesertVortexCenter);
	// default IgnoredActorClasses.Add(ADesertVortexSpinningCenter);
	// default IgnoredActorClasses.Add(AVortexSandFish);
	// default IgnoredActorClasses.Add(ALandscape);
	// default IgnoredActorClasses.Add(ARespawnPoint);
	// default IgnoredActorClasses.Add(ARespawnPointVolume);

	// UPROPERTY(EditInstanceOnly)
	// TArray<AActor> IgnoredActors;

	// UPROPERTY(EditInstanceOnly)
	// FHazeRange HeightRange = FHazeRange(30000, 50000);

#if EDITOR
	UPROPERTY(DefaultComponent)
	UEditorBillboardComponent BillboardComp;
	default BillboardComp.WorldScale3D = FVector(10);

	UPROPERTY(DefaultComponent)
	UDesertVortexCenterComponent VortexCenterComp;

	UPROPERTY(EditInstanceOnly)
	bool bVisualizeMovement = false;

	UPROPERTY(EditInstanceOnly, Meta = (EditCondition = "bVisualizeMovement"))
	bool bMoveAutomatically = true;

	UPROPERTY(EditInstanceOnly, Meta = (EditCondition = "bVisualizeMovement && bMoveAutomatically"))
	float VisualizeSpeedMultiplier = 5;

	UPROPERTY(EditInstanceOnly, Meta = (EditCondition = "bVisualizeMovement && !bMoveAutomatically", UIMin = "0", UIMax = "360", ClampMin = "0", ClampMax = "360"))
	float VisualizeAngle = 0;
#endif

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnActorModifiedInEditor()
	{
		SpinningLayers.Sort();
	}
#endif

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		// for(auto SpinningLayer :SpinningLayers)
		// {
		// 	if(SpinningLayer.SpinningCenter == nullptr)
		// 		continue;

		// 	for(auto Actor : SpinningLayer.Actors)
		// 	{
		// 		Actor.AttachToActor(SpinningLayer.SpinningCenter);
		// 	}
		// }
	}

// #if EDITOR
// 	UFUNCTION(CallInEditor)
// 	private void AddActorsToLayers()
// 	{
// 		for(auto& Layer : SpinningLayers)
// 		{
// 			Layer.Actors.Reset();
// 		}

// 		SpinningLayers.Sort();

// 		TArray<AActor> AllActors = Editor::GetAllEditorWorldActorsOfClass(AActor);
// 		for(auto Actor : AllActors)
// 		{
// 			if(Actor.GetActorNameOrLabel().Contains("KineticSplineFollowActor"))
// 				Print("Test");

// 			if(Actor.Level != Level)
// 				continue;

// 			if(!Math::IsWithin(Actor.ActorLocation.Z, HeightRange.Min, HeightRange.Max))
// 				continue;

// 			if(Actor.RootComponent.Mobility != EComponentMobility::Movable)
// 			{
// 				//Warning(f"AddActorsToLayers(): Actor {Actor.GetActorNameOrLabel()} is {Actor.RootComponent.Mobility}, and was skipped when adding to spinning layers.");
// 				continue;
// 			}

// 			if(Actor.AttachParentActor != nullptr)
// 			{
// 				//Warning(f"AddActorsToLayers(): Actor {Actor.GetActorNameOrLabel()} is attached to {Actor.AttachParentActor}, and was skipped when adding to spinning layers.");
// 				continue;
// 			}

// 			for(auto IgnoredClass : IgnoredActorClasses)
// 			{
// 				if(Actor.Class.IsChildOf(IgnoredClass))
// 					continue;
// 			}

// 			if(Actor.ActorNameOrLabel.Contains("Respawn"))
// 				continue;

// 			if(IgnoredActors.Contains(Actor))
// 				continue;

// 			if(Actor == this)
// 				continue;

// 			AddToLayer(Actor);
// 		}
// 	}

// 	void AddToLayer(AActor Actor)
// 	{
// 		const float Distance = Actor.ActorLocation.Dist2D(ActorLocation);

// 		for(auto& SpinningLayer : SpinningLayers)
// 		{
// 			if(Distance < SpinningLayer.EndDistance)
// 			{
// 				SpinningLayer.Actors.Add(Actor);
// 				return;
// 			}
// 		}

// 		SpinningLayers[SpinningLayers.Num() - 1].Actors.Add(Actor);
// 	}
// #endif
};

#if EDITOR
UCLASS(NotBlueprintable, NotPlaceable)
class UDesertVortexCenterComponent : UActorComponent
{
};

UCLASS(NotBlueprintable, NotPlaceable)
class UDesertVortexCenterComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UDesertVortexCenterComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto VortexCenter = Cast<ADesertVortexCenter>(Component.Owner);
		if(VortexCenter == nullptr)
			return;

		if(VortexCenter.bVisualizeMovement)
		{
			for(int i = 0; i < VortexCenter.SpinningLayers.Num(); i++)
			{
				auto SpinningCenter = VortexCenter.SpinningLayers[i].SpinningCenter;
				if(SpinningCenter == nullptr)
					continue;

				float YawAngle = 0;
				if(VortexCenter.bMoveAutomatically)
					YawAngle = Math::Wrap(Time::GameTimeSeconds * SpinningCenter.GetSpinSpeed() * VortexCenter.VisualizeSpeedMultiplier, 0, 360);
				else
					YawAngle = VortexCenter.VisualizeAngle;

				const FTransform VortexTransform = SpinningCenter.ActorTransform;

				TArray<AActor> AttachedActors;
				SpinningCenter.GetAttachedActors(AttachedActors, false, false);

				for(auto Actor : AttachedActors)
				{
					auto DistanceActor = Cast<ADesertDistanceFromVortexCenter>(Actor);
					if(DistanceActor == nullptr)
						continue;

					const FTransform SpinningTransform(FQuat(FVector::UpVector, Math::DegreesToRadians(YawAngle - DistanceActor.DistanceComp.GetYawOffset())) * SpinningCenter.ActorQuat, SpinningCenter.ActorLocation);

					{
						FHazeRuntimeSpline Spline = ConstructRuntimeSplineFromDistances(DistanceActor.DistanceComp, 50);

						for(int j = 0; j < 50; j++)
						{
							float Alpha = j / float(50);
							float Angle = Alpha * 360;
							FVector Location = DistanceActor.DistanceComp.GetLocationFromYawAngle(Angle);
							Location.Z = Desert::GetLandscapeHeightByLevel(Location, ESandSharkLandscapeLevel::Upper);
							DrawPoint(Location, FLinearColor::Red, 20);
						}

						Spline.VisualizeSplineSimple(this, 150, 20, VortexCenter.SpinningLayers[i].Color);
					}

					const FQuat DistanceRelativeRotation = VortexTransform.InverseTransformRotation(DistanceActor.ActorQuat);
					FVector NewDistanceActorLocation = Desert::GetLandscapeLocation(DistanceActor.DistanceComp.GetLocationFromYawAngle(YawAngle));
					FQuat NewDistanceActorRotation = SpinningTransform.TransformRotation(DistanceRelativeRotation);
					FTransform NewDistanceActorTransform(NewDistanceActorRotation, NewDistanceActorLocation);

					DrawWireSphere(NewDistanceActorLocation, 500, VortexCenter.SpinningLayers[i].Color, 2, 12, true);
					DrawWorldString(DistanceActor.ActorNameOrLabel, NewDistanceActorLocation, VortexCenter.SpinningLayers[i].Color, 1, -1, false, true);

					TArray<AActor> AttachedActorsToDistanceActor;
					DistanceActor.GetAttachedActors(AttachedActorsToDistanceActor, false, true);

					for(auto AttachedActor : AttachedActorsToDistanceActor)
					{
						FVector Origin;
						FVector Extent;
						AttachedActor.GetActorLocalBounds(true, Origin, Extent, true);

						FVector RelativeLocation = DistanceActor.ActorTransform.InverseTransformPositionNoScale(AttachedActor.ActorLocation);
						FQuat RelativeRotation = DistanceActor.ActorTransform.InverseTransformRotation(AttachedActor.ActorQuat);

						FVector Location = Desert::GetLandscapeLocation(NewDistanceActorTransform.TransformPositionNoScale(RelativeLocation));
						FQuat Rotation = NewDistanceActorTransform.TransformRotation(RelativeRotation);

						DrawWireBox(Location, AttachedActor.ActorScale3D * Extent, Rotation, VortexCenter.SpinningLayers[i].Color, 1, true);
					}
				}
			}
		}
		else
		{
			// DrawHeightRange(VortexCenter.ActorLocation, VortexCenter.HeightRange);

			for(int i = 0; i < VortexCenter.SpinningLayers.Num(); i++)
			{
				if(VortexCenter.SpinningLayers[i].SpinningCenter == nullptr)
					continue;

				auto Layer = VortexCenter.SpinningLayers[i];
				DrawCircle(VortexCenter.ActorLocation, Layer.EndDistance, Layer.Color, 100, FVector::UpVector, 100);

				TArray<AActor> AttachedActors;
				GetAllAttachedActors(Layer.SpinningCenter, AttachedActors);

				for(auto Actor : AttachedActors)
				{
					if(Actor == nullptr)
						continue;

					FVector Origin, Extent;
					Actor.GetActorLocalBounds(false, Origin, Extent, false);
					DrawWireBox(Actor.ActorTransform.TransformPosition(Origin), Actor.ActorTransform.Scale3D * Extent, Actor.ActorQuat, VortexCenter.SpinningLayers[i].Color, 1, true);
				}
			}
		}

	}
	
	void GetAllAttachedActors(AActor Actor, TArray<AActor>&out OutAttachedActors) const
	{
		TArray<AActor> AttachedActors;
		Actor.GetAttachedActors(AttachedActors, false);

		if(AttachedActors.IsEmpty())
			return;

		for(auto It : AttachedActors)
		{
			if(It.IsA(ADesertVortexSpinningCenter))
				continue;

			OutAttachedActors.Add(It);
			GetAllAttachedActors(It, OutAttachedActors);
		}
	}

	TArray<ADesertVortexSpinningCenter> GetSpinningCenters(ADesertVortexCenter VortexCenter) const
	{
		TArray<ADesertVortexSpinningCenter> SpinningCenters;
		for(auto SpinningLayer : VortexCenter.SpinningLayers)
		{
			if(SpinningLayer.SpinningCenter != nullptr)
				SpinningCenters.Add(SpinningLayer.SpinningCenter);
		}
		return SpinningCenters;
	}

	FHazeRuntimeSpline ConstructRuntimeSplineFromDistances(UDesertDistanceFromVortexCenterComponent DistanceComp, int Resolution) const
	{
		FHazeRuntimeSpline Spline;
		Spline.SetLooping(true);

		for(int i = 0; i < Resolution; i++)
		{
			float Alpha = i / float(Resolution);
			float Angle = Alpha * 360;
			FVector Location = DistanceComp.GetLocationFromYawAngle(Angle);
			Location.Z = Desert::GetLandscapeHeightByLevel(Location, ESandSharkLandscapeLevel::Upper);
			Spline.AddPoint(Location);
		}

		return Spline;
	}

	// private void DrawHeightRange(FVector ActorLocation, FHazeRange HeightRange) const
	// {
	// 	FVector Location = ActorLocation;
	// 	Location.Z = HeightRange.Min;

	// 	DrawSolidBox(FInstigator(this, n"Min"), Location, FQuat::Identity, FVector(100000, 100000, 10), FLinearColor::Green, 0.1);

	// 	Location.Z = HeightRange.Max;

	// 	DrawSolidBox(FInstigator(this, n"Max"), Location, FQuat::Identity, FVector(100000, 100000, 10), FLinearColor::Blue, 0.1);
	// }
};
#endif