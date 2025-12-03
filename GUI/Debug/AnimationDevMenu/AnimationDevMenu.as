
class UAnimationDevMenu : UHazeDevMenuEntryImmediateWidget
{
	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry Geometry, float DeltaTime)
	{
		if (!Drawer.IsVisible())
			return;
		
		AHazeActor Actor = Cast<AHazeActor>(GetDebugActor());
		if (Actor == nullptr)
		{
			auto S =  Drawer.Begin();
			S.Text("No actor selected.").Scale(2.0);
			if (S.Button("Select Actor"))
			{
				DevMenu::TriggerActorPicker();
			}
			return;
		}

		FHazeImmediateVerticalBoxHandle Root = Drawer.BeginVerticalBox();

		// Show actor name
		FString ActorName = Actor.Name.ToString();
		if(Network::IsGameNetworked())
		{
			if(Actor.HasControl())
				ActorName += " (Control)";
			else
				ActorName += " (Remote)";
		}
		auto Text = Root.SlotPadding(5).Text(f"{ActorName}").Scale(2.0);

		auto PlayerActor = Cast<AHazePlayerCharacter>(Actor);
		if(PlayerActor != nullptr)
		{
			Text.Color(PlayerActor.GetPlayerDebugColor());
		}

		WriteFeatureData(Actor, Root);
	}

	void WriteFeatureData(AHazeActor Actor, FHazeImmediateVerticalBoxHandle Root)
	{
		Root.Text(f"FEATURE DATA").Scale(1.5);

		auto MeshComp = UHazeCharacterSkeletalMeshComponent::Get(Actor);
		if (MeshComp == nullptr)
		{
			Root.Text("Actor does not have a character mesh component.");
			Drawer.End();
			return;
		}

		auto FeaturesScrollBox = Root.SlotFill().ScrollBox();
		FString FeaturesText;

		const TArray<FHazePrioritizedLocomotionFeature> Features = MeshComp.SortedLocomotionFeatures;
		if (Features.Num() > 0)
			FeaturesText += "FEATURES:";

		for (const FHazePrioritizedLocomotionFeature Feature : Features)
		{
			FeaturesText += f"\n\t{Feature.Asset.ToString()} (Instigator: {Feature.Instigator.ToString()})";
		}

		const TArray<FHazePrioritizedLocomotionFeatureBundle> FeatureBundles = MeshComp.SortedLocomotionFeatureBundles;
		if (FeatureBundles.Num() > 0)
		{
			if (Features.Num() > 0)
				FeaturesText += "\n";
			FeaturesText += "FEATURE BUNDLES:";
		}

		TArray<const UHazeLocomotionFeatureBundle> CheckedBundles;
		for (const FHazePrioritizedLocomotionFeatureBundle FeatureBundle : FeatureBundles)
		{
			WriteFeatureBundle(FeaturesText, CheckedBundles, FeatureBundle.Asset, FeatureBundle.Instigator);
		}

		FeaturesScrollBox.SlotPadding(10).RichText(FeaturesText);
	}

	void WriteFeatureBundle(FString& FeaturesText, TArray<const UHazeLocomotionFeatureBundle>& OutCheckedBundles, const UHazeLocomotionFeatureBundle InBundle, const FInstigator InInstigator)
	{
		if (OutCheckedBundles.Contains(InBundle))
			return;

		OutCheckedBundles.Add(InBundle);
		FeaturesText += f"\n\t{InBundle.GetName()} (Instigator: {InInstigator.ToString()})";

		for (const UHazeLocomotionFeatureBase Feature : InBundle.Features)
		{
			if (Feature == nullptr)
				FeaturesText += f"\n\t\tNULL";
			else
				FeaturesText += f"\n\t\t{Feature.GetName().ToString()}";
		}

		for (const UHazeLocomotionFeatureBundle FeatureBundle : InBundle.FeatureBundles)
		{
			WriteFeatureBundle(FeaturesText, OutCheckedBundles, FeatureBundle, InInstigator);
		}
	}
}