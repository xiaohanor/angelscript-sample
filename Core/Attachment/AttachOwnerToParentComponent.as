
/**
 * Helper component to attach an actor in the editor to a component on its attach parent instead of the root.
 */
UCLASS(HideCategories = "Debug Activation Cooking Tags Collision")
class UAttachOwnerToParentComponent : UActorComponent
{
	UPROPERTY(EditAnywhere, Category = "Attach Owner to Parent")
	FName ComponentNameOnParent;

	UPROPERTY(EditAnywhere, Category = "Settings")
	EAttachmentRule AttachmentRule = EAttachmentRule::KeepWorld;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (!ComponentNameOnParent.IsNone())
		{
			auto RootAttachment = Owner.RootComponent.GetAttachParent();
			if (RootAttachment != nullptr)
			{
				auto ParentComp = USceneComponent::Get(RootAttachment.Owner, ComponentNameOnParent);
				if (ParentComp != nullptr)
					Owner.RootComponent.AttachToComponent(ParentComp, NAME_None, AttachmentRule);
			}
		}
	}
};

#if EDITOR
class UAttachOwnerToParentComponentDetails : UHazeScriptDetailCustomization
{
	default DetailClass = UAttachOwnerToParentComponent;

	UAttachOwnerToParentComponent AttachComponent;
	UHazeImmediateDrawer MainDrawer;
	
	UFUNCTION(BlueprintOverride)
	void CustomizeDetails()
	{
		AttachComponent = Cast<UAttachOwnerToParentComponent>(GetCustomizedObject());
		MainDrawer = AddImmediateRow(n"Attach Owner to Parent Component");

		HideCategory(n"Attach Owner to Parent");
	}

	UFUNCTION(BlueprintOverride, meta = (NoSuperCall))
	void Tick(float DeltaTime)
	{
		if (AttachComponent == nullptr)
			return;

		if (MainDrawer != nullptr && MainDrawer.IsVisible())
		{
			auto Root = MainDrawer.BeginVerticalBox();
			DrawMainContent(Root);
		}
	}

	void DrawMainContent(FHazeImmediateVerticalBoxHandle& Root)
	{
		AActor AttachActor = AttachComponent.Owner.GetAttachParentActor();

		if (AttachActor == nullptr)
		{
			Root
				.Section().Color(FLinearColor::MakeFromHex(0xff150000))
				.Text("⚠ Actor is not attached to anything in the level.");
		}
		else
		{
			auto BorderBox = Root.BorderBox().HeightOverride(40);
			auto HorizBox = BorderBox.HorizontalBox();
			HorizBox
				.SlotVAlign(EVerticalAlignment::VAlign_Center)
				.SlotPadding(10, 0)
				.Text("Attach To");

			auto ComboBox = HorizBox
				.SlotFill()
				.SlotPadding(15, 0, 0, 0)
				.SlotHAlign(EHorizontalAlignment::HAlign_Fill)
				.ComboBox();

			TArray<FName> ComponentNames;
			TArray<USceneComponent> SceneComponents;
			AttachActor.GetComponentsByClass(SceneComponents);

			int SelectedComponent = 0;
			ComponentNames.AddUnique(AttachActor.RootComponent.GetName());

			for (auto Comp : SceneComponents)
			{
				if (Comp.bIsEditorOnly)
					continue;
				if (Comp.IsVisualizationComponent())
					continue;
				if (Editor::GetCompnentCreationMethod(Comp) == EComponentCreationMethod::UserConstructionScript)
					continue;

				if (!ComponentNames.Contains(Comp.GetName()))
				{
					if (AttachComponent.ComponentNameOnParent == Comp.GetName())
						SelectedComponent = ComponentNames.Num();
					ComponentNames.Add(Comp.GetName());
				}
			}

			if (AttachComponent.ComponentNameOnParent != NAME_None)
			{
				if (!ComponentNames.Contains(AttachComponent.ComponentNameOnParent))
				{
					SelectedComponent = ComponentNames.Num();
					ComponentNames.AddUnique(AttachComponent.ComponentNameOnParent);

					BorderBox.BackgroundColor(FLinearColor::MakeFromHex(0xff150800));
					Root
						.Section().Color(FLinearColor::MakeFromHex(0xff150800))
						.Text(f"⚠ Component '{AttachComponent.ComponentNameOnParent}' does not exist on attach parent.");
				}
			}

			ComboBox.Items(ComponentNames);
			ComboBox.Value(ComponentNames[SelectedComponent]);

			if (ComboBox.SelectedIndex != SelectedComponent)
			{
				FScopedTransaction Transaction("Change Component Attachment");
				AttachComponent.Modify();
				AttachComponent.ComponentNameOnParent = ComponentNames[ComboBox.SelectedIndex];
			}
		}
	}

}
#endif