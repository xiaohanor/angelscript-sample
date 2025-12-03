USTRUCT()
struct FSplineCircle
{
	FVector Center;
	bool bIsActivated = false;
	float DeactivationTime;
	TArray<FMoonMarketFlowerPuzzleOverlapData> FlowerGroups;

	FSplineCircle(FVector Location)
	{
		Center = Location;
	}

	void AddFlowers(FMoonMarketFlowerPuzzleOverlapData OverlapData)
	{
		//Erase other players flowers
		for(int i = FlowerGroups.Num()-1; i >= 0; i--)
		{
			if(FlowerGroups[i].Player != OverlapData.Player)
			{
				FlowerGroups[i].FlowerComp.RemoveInstances(FlowerGroups[i].FlowerIds);
				FlowerGroups.RemoveAt(i);
			}
		}

		FlowerGroups.Add(OverlapData);
	}
}

class AFlowerCatPuzzlePiece : ASplineActor
{
	UPROPERTY(EditInstanceOnly)
	APropLine PropLineSpline;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	UMaterialInstanceDynamic DynamicMat;

	//FHazeAcceleratedFloat ColorAlpha;

	UPROPERTY(EditAnywhere)
	EMoonMarketFlowerHatType ColorType;


	AFlowerCatPuzzle Puzzle;

	UPROPERTY()
	TArray<FSplineCircle> Circles;

	UPROPERTY(EditAnywhere)
	const float CircleRadius = 50;

	UPROPERTY(EditAnywhere)
	const float SplineStepSize = CircleRadius;
	
	UPROPERTY(EditAnywhere)
	const float ActivationPercentageThreshold = 0.98;

	UPROPERTY(EditAnywhere)
	bool bForQuest = true;

	TArray<AMoonMarketFlowerHat> Hats;

	bool bPieceActivated = false;

	EHazePlayer DebugIncorrectColorPlayer;

	bool bSetup = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		//DynamicMat = Material::CreateDynamicMaterialInstance(this, Puzzle.PuzzlePieceMat);
		//DynamicMat.SetVectorParameterValue(n"TargetColor", Puzzle.TargetColor[ColorCode]);
		//DynamicMat.SetScalarParameterValue(n"EmissiveStrength", Puzzle.EmissiveStrength);
		RegenerateSplinePiece();
		
		// if(PropLine != nullptr)
		// {
		// 	FHazePropMaterialOverride OverrideMat;
		// 	OverrideMat.Material = DynamicMat;

		// 	TArray<UMeshComponent> AllMeshes;
		// 	PropLine.GetComponentsByClass(AllMeshes);

		// 	for (auto MeshComp : AllMeshes)
		// 	{
		// 		MeshComp.SetMaterial(0, DynamicMat);
		// 	}
		// }
		// else
		// 	PrintError("No propline assigned to " + Name);

		

	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(!bSetup)
		{
			Puzzle = TListedActors<AFlowerCatPuzzle>().Single;
			if(Puzzle == nullptr)
				return;

			if (bForQuest)
				Puzzle.AddPiece(this);
			
			Hats = TListedActors<AMoonMarketFlowerHat>().GetArray();

			for (AMoonMarketFlowerHat Hat : Hats)
			{
				Hat.OnMoonMarketFlowerHatStarted.AddUFunction(this, n"OnMoonMarketFlowerHatStarted");
				Hat.OnMoonMarketFlowerHatStopped.AddUFunction(this, n"OnMoonMarketFlowerHatStopped");
			}

			bSetup = true;
			SetActorTickEnabled(false);
		}
	}

	UFUNCTION()
	private void OnMoonMarketFlowerHatStarted(AMoonMarketFlowerHat Hat)
	{
		//Set to that players control side on interaction
		if (Hat.Type == ColorType)
		{
			SetActorControlSide(Hat.UsingPlayer);
		}
	}
	
	UFUNCTION()
	private void OnMoonMarketFlowerHatStopped(AMoonMarketFlowerHat Hat)
	{
	}

	#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnActorModifiedInEditor()
	{
		// if(PropLine != nullptr)
		// {
		// 	PropLine.SetActorLocation(ActorLocation + FVector::DownVector * 10);
		// 	PropLine.SetActorScale3D(ActorScale3D);
		// 	PropLine.SetActorRotation(ActorRotation);
		// }

		RegenerateSplinePiece();
	}
	#endif

	UFUNCTION(CallInEditor)
	void RegenerateSplinePiece()
	{
		// #if EDITOR
		// if(PropLineSpline != nullptr)
		// {
		// 	Spline.SplinePoints = UPropLineSplineComponent::Get(PropLineSpline).SplinePoints;
		// 	ActorLocation = PropLineSpline.ActorLocation;
		// 	ActorRotation = PropLineSpline.ActorRotation;
		// 	ActorScale3D = PropLineSpline.ActorScale3D;
		// }
		// #endif

		bPieceActivated = false;
		Circles.Empty();

		for(float Dist = 0; Dist <= Spline.SplineLength; Dist += SplineStepSize)
		{
			Circles.Add(FSplineCircle(Spline.GetWorldLocationAtSplineDistance(Dist)));
		}
	}

	bool IsWithinRadius(FSplineCircle Circle, FVector Location, float Radius) const
	{
		float Dist = Location.DistSquared2D(Circle.Center);
		return (Dist <= Radius * Radius);
	}

	// void EraseFlowers(EHazePlayer Player, FVector EraseLocation, float EraseRadius)
	// {
	// 	//Loop over every circle on the spline
	// 	for(auto& Circle : Circles)
	// 	{
	// 		//If the flower is within the radius of a circle
	// 		if(IsWithinRadius(Circle, EraseLocation, EraseRadius))
	// 		{
	// 			for(int i = 0; i < Circle.FlowerGroups.Num();)
	// 			{
	// 				if(Circle.FlowerGroups[i].Player == Player)
	// 				{
	// 					for(auto Flower : Circle.FlowerGroups[i].Flowers)
	// 					{
	// 						if(Flower == nullptr)
	// 							continue;
							
	// 						Flower.LifeSpan = Time::GameTimeSeconds + FlowerPuzzle::FlowerUnhealthyLifeTime;
	// 						Flower.SetLifeSpan(FlowerPuzzle::FlowerUnhealthyLifeTime);
	// 					}

	// 					Circle.FlowerGroups.RemoveAt(i);
	// 				}
	// 				else
	// 				{
	// 					i++;
	// 				}
	// 			}
	// 		}
	// 	}

	// 	UpdateActivatedCirclesAmount();
	// }

	void CheckForOverlap(FMoonMarketFlowerPuzzleOverlapData OverlapData, FMoonMarketFlowerPuzzleOverlapResult& OverlapResult)
	{
		float RadiusToCheck = CircleRadius;
		if(OverlapData.Type != ColorType)
			RadiusToCheck = CircleRadius / 2;

		//Loop over every circle on the spline
		for(int i = 0; i < Circles.Num(); i++)
		{
			//If the flower is within the radius of a circle
			if(IsWithinRadius(Circles[i], OverlapData.FlowerLocation, RadiusToCheck))
			{
				if(OverlapResult.BelongingPiece == nullptr)
				{
					OverlapResult.OverlappedCircleIndex.Set(i);
					OverlapResult.BelongingPiece = this;
					OverlapResult.bSuccesfulPlacement = true;
					OverlapResult.bCorrectColor = OverlapData.Type == ColorType;
					return;
				}
			}
		}
	}

	void UpdateActivatedCirclesAmount()
	{
		int ActivatedCircles = 0;
		bool bHasIncorrectColor = false;

		for(auto& Circle : Circles)
		{
			bool bHasCorrectColor = false;

			for(int i = Circle.FlowerGroups.Num() -1; i >= 0; i--)
			{
				if(Circle.FlowerGroups[i].Type != ColorType)
				{
					DebugIncorrectColorPlayer = Circle.FlowerGroups[i].Player;
					bHasIncorrectColor = true;
					break;
				}
				else
					bHasCorrectColor = true;
			}

			if(bHasCorrectColor && !bHasIncorrectColor)
			{
				Circle.bIsActivated = true;
				ActivatedCircles++;
			}
		}

		//Calculate new percentage of activated circles
		float Percentage = ActivatedCircles / float(Circles.Num());

		if(bHasIncorrectColor)
			Percentage = 0;

		//If the percentage is over a threshold, this piece of the puzzle counts as solved
		if(Percentage >= ActivationPercentageThreshold && !bPieceActivated)
		{
			Puzzle.ActivatePiece(this);
			bPieceActivated = true;
			UpdateFlowersEmissive();
		}
		else if(Percentage < ActivationPercentageThreshold && bPieceActivated)
		{
			Puzzle.DeactivatePiece(this);
			bPieceActivated = false;
			UpdateFlowersEmissive();
		}
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnVisualizeInEditor() const
	{
		for(auto& Circle : Circles)
		{
			FLinearColor DebugCol = Circle.bIsActivated ? FLinearColor::Green : FLinearColor::Red;
			Debug::DrawDebugCircle(Circle.Center, CircleRadius, 12, DebugCol);
		}
	}
#endif

	void UpdateFlowersEmissive()
	{
		for(auto& Circle : Circles)
		{
			for(auto& FlowerGroup : Circle.FlowerGroups)
			{		
				FlowerGroup.FlowerComp.SetFlowersActivated(FlowerGroup.FlowerIds, bPieceActivated);
			}
		}
	}
};