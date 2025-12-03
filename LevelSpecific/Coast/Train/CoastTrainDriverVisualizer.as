class UCoastTrainDriverVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UCoastTrainDriverDummyComponent;
	const float ConnectionOffset = 1500.0;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(UActorComponent Component)
	{
		auto Driver = Cast<ACoastTrainDriver>(Component.Owner);

		// Draw driver stuff
		FVector Loc = Driver.ActorLocation + Driver.ActorUpVector * ConnectionOffset;
		DrawWireSphere(
			Loc,
			150.0,
			FLinearColor::Red,
			Thickness = 15.0
		);

		DrawArrow(
			Loc,
			Loc + Driver.ActorForwardVector * 500.0,
			FLinearColor::Red,
			45.0,
			15.0
		);


		if (Driver.Carts.Num() == 0)
			return;

		// Draw subsequent connections
		ACoastTrainCart LastParent = Driver;
		for(int Index = 0; Index < Driver.Carts.Num(); ++Index)
		{
			auto& Child = Driver.Carts[Index];
			if (Child.Cart == nullptr)
				continue;

			DrawConnection(LastParent, Child.Cart);
			LastParent = Child.Cart;
		}
	}

	void DrawConnection(ACoastTrainCart Parent, ACoastTrainCart Child)
	{
		if (Parent == nullptr || Child == nullptr)
			return;

		DrawLine(
			Parent.ActorLocation + Parent.ActorUpVector * ConnectionOffset,
			Child.ActorLocation + Child.ActorUpVector * ConnectionOffset,
			FLinearColor::Blue,
			10.0
		);

		DrawWireSphere(
			Parent.ActorLocation + Parent.ActorUpVector * ConnectionOffset,
			50.0,
			FLinearColor::Blue,
			Thickness = 10.0
		);

		DrawWireSphere(
			Child.ActorLocation + Child.ActorUpVector * ConnectionOffset,
			50.0,
			FLinearColor::Blue,
			Thickness = 10.0
		);
	}
}

class UCoastTrainDriverDummyComponent : UActorComponent {}