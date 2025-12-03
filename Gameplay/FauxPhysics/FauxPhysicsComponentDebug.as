#if EDITOR
class UFauxPhysicsComponentDebugComponent : UActorComponent
{
	UHazeImmediateDrawer Drawer;
	TArray<UFauxPhysicsComponentBase> DebugComponents;

	FVector Origin;
	FVector Force;
	bool bDebugForce = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Drawer = DevMenu::RequestImmediateDevMenu(n"Faux Physics", "🏀");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (!Drawer.IsVisible())
			return;

		auto S = Drawer.Begin();

		Origin = S.VectorInput().Label("Location").Value(Origin);
		Force = S.VectorInput().Label("Force").Value(Force);

		Debug::DrawDebugSphere(Origin, LineColor = FLinearColor::Red, Thickness = 10.0);
		Debug::DrawDebugArrow(Origin, Origin + Force, LineColor = FLinearColor::Red, ArrowSize = 40.0);

		for(auto Component : DebugComponents)
		{
			auto CompSection = S.Section(f"{Component.Owner.Name}::{Component.Name}");
			auto HBox = CompSection.HorizontalBox();
			if (HBox.CheckBox().Label("Debug Force"))
				Component.ApplyForce(Origin, Force);
			if (HBox.Button("MoveTo"))
				Origin = Component.WorldLocation;
		}
	}
}

void AddPhysicsComponentToDebugger(UFauxPhysicsComponentBase Comp)
{
	auto DebugComp = UFauxPhysicsComponentDebugComponent::GetOrCreate(Game::Mio);
	DebugComp.DebugComponents.Add(Comp);
}

void RemovePhysicsComponentFromDebugger(UFauxPhysicsComponentBase Comp)
{
	auto DebugComp = UFauxPhysicsComponentDebugComponent::GetOrCreate(Game::Mio);
	DebugComp.DebugComponents.Remove(Comp);
}
#endif