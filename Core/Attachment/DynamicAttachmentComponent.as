/**
 * Helper component to dynamically attach one of this actor's component to a different component in the level.
 */
UCLASS(HideCategories = "Debug Activation Cooking Tags Collision")
class UDynamicAttachmentComponent : UActorComponent
{
	UPROPERTY(EditAnywhere, Category = "Dynamic Attachment")
	FName SubjectComponentToAttach;

	UPROPERTY(EditAnywhere, Category = "Settings")
	AActor ActorToAttachTo;

	UPROPERTY(EditAnywhere, Category = "Dynamic Attachment")
	FName TargetComponentToAttachTo;

	UPROPERTY(EditAnywhere, Category = "Settings")
	FName TargetAttachSocket;

	UPROPERTY(EditAnywhere, Category = "Settings")
	EAttachmentRule AttachmentRule = EAttachmentRule::KeepWorld;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (!TargetComponentToAttachTo.IsNone() && !SubjectComponentToAttach.IsNone())
		{
			AActor TargetActor = ActorToAttachTo;
			if (TargetActor == nullptr)
				TargetActor = GetOwner().AttachParentActor;

			USceneComponent SubjectComponent = USceneComponent::Get(GetOwner(), SubjectComponentToAttach);
			if (TargetActor != nullptr && SubjectComponent != nullptr)
			{
				USceneComponent TargetComponent = USceneComponent::Get(TargetActor, TargetComponentToAttachTo);
				if (TargetComponent != nullptr)
				{
					SubjectComponent.AttachToComponent(TargetComponent, TargetAttachSocket, AttachmentRule);
				}
			}
		}
	}
};

#if EDITOR
class UDynamicAttachmentComponentDetails : UHazeScriptDetailCustomization
{
	default DetailClass = UDynamicAttachmentComponent;

	UDynamicAttachmentComponent AttachComponent;
	UHazeImmediateDrawer MainDrawer;
	
	UFUNCTION(BlueprintOverride)
	void CustomizeDetails()
	{
		AttachComponent = Cast<UDynamicAttachmentComponent>(GetCustomizedObject());
		MainDrawer = AddImmediateRow(n"Attachment");

		HideCategory(n"Dynamic Attachment");
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
		AActor AttachActor = AttachComponent.ActorToAttachTo;
		if (AttachActor == nullptr)
			AttachActor = AttachComponent.GetOwner().AttachParentActor;

		auto SubjectSection = Root.Section("Subject Component To Attach");
		{
			auto BorderBox = SubjectSection.BorderBox().HeightOverride(40);
			auto HorizBox = BorderBox.HorizontalBox();
			HorizBox
				.SlotVAlign(EVerticalAlignment::VAlign_Center)
				.SlotPadding(10, 0)
				.Text("Attach");

			auto ComboBox = HorizBox
				.SlotFill()
				.SlotPadding(15, 0, 0, 0)
				.SlotHAlign(EHorizontalAlignment::HAlign_Fill)
				.ComboBox();

			TArray<FName> ComponentNames;
			TArray<USceneComponent> SceneComponents;
			AttachComponent.GetOwner().GetComponentsByClass(SceneComponents);

			int SelectedComponent = 0;
			ComponentNames.AddUnique(AttachComponent.GetOwner().RootComponent.GetName());

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
					if (AttachComponent.SubjectComponentToAttach == Comp.GetName())
						SelectedComponent = ComponentNames.Num();
					ComponentNames.Add(Comp.GetName());
				}
			}

			if (AttachComponent.SubjectComponentToAttach != NAME_None)
			{
				if (!ComponentNames.Contains(AttachComponent.SubjectComponentToAttach))
				{
					SelectedComponent = ComponentNames.Num();
					ComponentNames.AddUnique(AttachComponent.SubjectComponentToAttach);

					BorderBox.BackgroundColor(FLinearColor::MakeFromHex(0xff150800));
					Root
						.Section().Color(FLinearColor::MakeFromHex(0xff150800))
						.Text(f"⚠ Component '{AttachComponent.SubjectComponentToAttach}' does not exist on target actor.");
				}
			}

			ComboBox.Items(ComponentNames);
			ComboBox.Value(ComponentNames[SelectedComponent]);

			if (ComboBox.SelectedIndex != SelectedComponent)
			{
				FScopedTransaction Transaction("Change Component Attachment");
				AttachComponent.Modify();
				AttachComponent.SubjectComponentToAttach = ComponentNames[ComboBox.SelectedIndex];
			}
		}

		auto TargetSection = Root.Section("Target Component To Attach To");
		if (AttachActor == nullptr)
		{
			TargetSection.Color(FLinearColor::MakeFromHex(0xff150000))
			.Text("⚠ Select an actor to attach to.");
		}
		else
		{
			auto BorderBox = TargetSection.BorderBox().HeightOverride(40);
			auto HorizBox = BorderBox.HorizontalBox();
			HorizBox
				.SlotVAlign(EVerticalAlignment::VAlign_Center)
				.SlotPadding(10, 0)
				.Text("To");

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
					if (AttachComponent.TargetComponentToAttachTo == Comp.GetName())
						SelectedComponent = ComponentNames.Num();
					ComponentNames.Add(Comp.GetName());
				}
			}

			if (AttachComponent.TargetComponentToAttachTo != NAME_None)
			{
				if (!ComponentNames.Contains(AttachComponent.TargetComponentToAttachTo))
				{
					SelectedComponent = ComponentNames.Num();
					ComponentNames.AddUnique(AttachComponent.TargetComponentToAttachTo);

					BorderBox.BackgroundColor(FLinearColor::MakeFromHex(0xff150800));
					Root
						.Section().Color(FLinearColor::MakeFromHex(0xff150800))
						.Text(f"⚠ Component '{AttachComponent.TargetComponentToAttachTo}' does not exist on target actor.");
				}
			}

			ComboBox.Items(ComponentNames);
			ComboBox.Value(ComponentNames[SelectedComponent]);

			if (ComboBox.SelectedIndex != SelectedComponent)
			{
				FScopedTransaction Transaction("Change Component Attachment");
				AttachComponent.Modify();
				AttachComponent.TargetComponentToAttachTo = ComponentNames[ComboBox.SelectedIndex];
			}
		}
	}

}
#endif