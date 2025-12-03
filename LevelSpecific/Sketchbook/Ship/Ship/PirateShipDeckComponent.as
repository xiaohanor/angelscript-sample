// struct FPirateShipDeckTriangle
// {
// 	UPROPERTY(EditAnywhere)
// 	int IndexA = 0;
// 	UPROPERTY(EditAnywhere)
// 	int IndexB = 0;
// 	UPROPERTY(EditAnywhere)
// 	int IndexC = 0;
// }

// struct FPirateShipDeckTriangleSelectValue
// {
// 	int TriangleIndex;
// 	float SelectValue;

// 	FPirateShipDeckTriangleSelectValue(int InTriangleIndex, float InSelectValue)
// 	{
// 		TriangleIndex = InTriangleIndex;
// 		SelectValue = InSelectValue;
// 	}
// }

UCLASS(NotBlueprintable)
class UPirateShipDeckComponent : UActorComponent
{
	access Internal = private, UPirateShipDeckComponentVisualizer;

	UPROPERTY(EditAnywhere)
	access:Internal
	FVector CenterOfDeck;

	UPROPERTY(EditAnywhere)
	access:Internal
	TArray<FVector> TargetPoint;

	int GetNumTargetPoints() const
	{
		return TargetPoint.Num();
	}

	FVector GetRelativeTargetPointLocationFromIndex(int Index)
	{
		return TargetPoint[Index];
	}

	FVector GetWorldTargetPointLocationFromIndex(int Index)
	{
		return Owner.ActorTransform.TransformPosition(TargetPoint[Index]);
	}

	int GetRandomTargetPointIndex() const
	{
		return Math::RandRange(0, TargetPoint.Num() - 1);
	}

	FVector GetRandomWorldTargetPoint() const
	{
		return Owner.ActorTransform.TransformPosition(TargetPoint[GetRandomTargetPointIndex()]);
	}

	int GetClosestTargetPointIndexTo(FVector Location) const
	{
		FVector RelativeLocation = Owner.ActorTransform.InverseTransformPosition(Location);
		float ClosestDistance = BIG_NUMBER;
		int ClosestIndex = 0;

		for(int i = 0; i < TargetPoint.Num(); i++)
		{
			float Distance = RelativeLocation.Distance(TargetPoint[i]);
			if(Distance < ClosestDistance)
			{
				ClosestDistance = Distance;
				ClosestIndex = i;
			}
		}

		return ClosestIndex;
	}

	FVector GetClosestTargetPointTo(FVector Location) const
	{
		return TargetPoint[GetClosestTargetPointIndexTo(Location)];
	}

	FVector GetCenterOfDeck() const
	{
		return Owner.ActorTransform.TransformPosition(CenterOfDeck);
	}

	// UPROPERTY(EditAnywhere)
	// TArray<FVector> Vertices;

	// UPROPERTY(EditAnywhere)
	// TArray<FPirateShipDeckTriangle> Triangles;

	// TArray<FPirateShipDeckTriangleSelectValue> SelectValues;
	// private float MaxValue;

	// private TArray<int> TimesSelected;

	// UFUNCTION(BlueprintOverride)
	// void BeginPlay()
	// {
	// 	float SelectValue = 0;

	// 	for(int i = 0; i < Triangles.Num(); i++)
	// 	{
	// 		float Area = GetTriangleArea(Triangles[i]);
	// 		Print(f"{i} with area {Area}");
	// 		SelectValue += Area;
	// 		SelectValues.Add(FPirateShipDeckTriangleSelectValue(i, SelectValue));
	// 	}

	// 	MaxValue = SelectValue;

	// 	TimesSelected.SetNumZeroed(Triangles.Num());
	// }

	// UFUNCTION(BlueprintOverride)
	// void Tick(float DeltaSeconds)
	// {
	// 	Debug::DrawDebugPoint(GetRandomLocationOnDeck(), 10, FLinearColor::MakeRandomColor(), 3);
	// 	for(int i = TimesSelected.Num() - 1; i >= 0; i--)
	// 	{
	// 		PrintToScreen(f"{i}: {TimesSelected[i]} with area of {Math::RoundToDouble((GetTriangleArea(Triangles[i]) / MaxValue) * 100)}%");
	// 	}
	// }

	// FVector GetRandomLocationOnDeck()
	// {
	// 	auto Triangle = GetRandomTriangleUniform();
	// 	FVector RelativePoint = GetRandomRelativePointOnTriangle(Triangle);
	// 	return Owner.ActorTransform.TransformPosition(RelativePoint);
	// }

	// FPirateShipDeckTriangle GetRandomTriangleUniform()
	// {
	// 	float RandomValue = Math::RandRange(0.0, MaxValue);

	// 	for(auto SelectValue : SelectValues)
	// 	{
	// 		if(SelectValue.SelectValue > RandomValue)
	// 		{
	// 			TimesSelected[SelectValue.TriangleIndex]++;
	// 			return Triangles[SelectValue.TriangleIndex];
	// 		}
	// 	}

	// 	DebugBreak();
	// 	return FPirateShipDeckTriangle();
	// }

	// float GetTriangleArea(FPirateShipDeckTriangle Triangle)
	// {
	// 	const FVector A = Vertices[Triangle.IndexA];
	// 	const FVector B = Vertices[Triangle.IndexB];
	// 	const FVector C = Vertices[Triangle.IndexC];

	// 	const float AB = A.Distance(B);
	// 	const float BC = B.Distance(C);
	// 	const float CA = C.Distance(A);

	// 	const float SemiPerimeter = (AB + BC + CA) * 0.5;
	// 	return Math::Sqrt(SemiPerimeter * (SemiPerimeter - AB) * (SemiPerimeter - BC) * (SemiPerimeter * CA));
	// }

	// FVector GetRandomRelativePointOnTriangle(FPirateShipDeckTriangle Triangle)
	// {
	// 	FVector A = Vertices[Triangle.IndexA];
	// 	FVector B = Vertices[Triangle.IndexB];
	// 	FVector C = Vertices[Triangle.IndexC];

	// 	float AB = Math::RandRange(0.0, 1.0);
	// 	float BC = Math::RandRange(0.0, 1.0);
	// 	float AC = Math::RandRange(0.0, 1.0);

	// 	return (Math::Lerp(A, B, AB) + Math::Lerp(B, C, BC) + Math::Lerp(A, C, AC)) / 3;
	// }
};

#if EDITOR
class UPirateShipDeckComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UPirateShipDeckComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto DeckComp = Cast<UPirateShipDeckComponent>(Component);
		if(DeckComp == nullptr)
			return;

		DrawPoint(DeckComp.GetCenterOfDeck(), FLinearColor::Blue, 20);

		for(int i = 0; i < DeckComp.TargetPoint.Num(); i++)
		{
			FVector Location = DeckComp.Owner.ActorTransform.TransformPosition(DeckComp.TargetPoint[i]);
			DrawPoint(Location, FLinearColor::Red, 20);
			DrawCircle(Location, 100, FLinearColor::Red, 3);
			DrawWorldString(f"{i}", Location + FVector::UpVector * 50, FLinearColor::Red, 1, -1, false, true);
		}

		// for(int i = 0; i < DeckComp.Vertices.Num(); i++)
		// {
		// 	FVector Location = DeckComp.Owner.ActorTransform.TransformPosition(DeckComp.Vertices[i]);
		// 	DrawPoint(Location, FLinearColor::Blue, 20);
		// 	DrawWorldString(f"{i}", Location + FVector::UpVector * 100, FLinearColor::White, 1, -1, false, true);
		// }

		// for(int i = 0; i < DeckComp.Triangles.Num(); i++)
		// {
		// 	auto Triangle = DeckComp.Triangles[i];

		// 	if(!DeckComp.Vertices.IsValidIndex(Triangle.IndexA) || !DeckComp.Vertices.IsValidIndex(Triangle.IndexB) || !DeckComp.Vertices.IsValidIndex(Triangle.IndexC))
		// 	{
		// 		PrintWarning("Invalid index", 0);
		// 		continue;
		// 	}

		// 	FVector LocationA = DeckComp.Owner.ActorTransform.TransformPosition(DeckComp.Vertices[Triangle.IndexA]);
		// 	FVector LocationB = DeckComp.Owner.ActorTransform.TransformPosition(DeckComp.Vertices[Triangle.IndexB]);
		// 	FVector LocationC = DeckComp.Owner.ActorTransform.TransformPosition(DeckComp.Vertices[Triangle.IndexC]);
		// 	DrawLine(LocationA, LocationB, FLinearColor::LucBlue, 20);
		// 	DrawLine(LocationB, LocationC, FLinearColor::LucBlue, 20);
		// 	DrawLine(LocationC, LocationA, FLinearColor::LucBlue, 20);

		// 	FVector Location = (LocationA + LocationB + LocationC) / 3.0;

		// 	DrawWorldString(f"Deck Triangle {i}", Location + FVector::UpVector * 50, FLinearColor::LucBlue, 1, -1, false, true);
		// }
	}
};
#endif