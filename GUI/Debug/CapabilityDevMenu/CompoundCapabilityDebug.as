
/**
 * Draws an immediate mode debug UI for compound capabilities.
 */
struct FCompoundCapabilityDebug
{
	bool bCanSelectNodes = false;
	int SelectedIndex = -1;
	int ClickedIndex = -1;

	UClass GetDebugCompoundClass(EHazeCapabilityCompoundNodeType CompoundType)
	{
		switch (CompoundType)
		{
			case EHazeCapabilityCompoundNodeType::Sequence:
				return UHazeCompoundSequence;
			case EHazeCapabilityCompoundNodeType::Selector:
				return UHazeCompoundSelector;
			case EHazeCapabilityCompoundNodeType::StatePicker:
				return UHazeCompoundStatePicker;
			case EHazeCapabilityCompoundNodeType::RunAll:
				return UHazeCompoundRunAll;
			case EHazeCapabilityCompoundNodeType::Capability:
				return nullptr;
		}
	}

	FLinearColor GetCompoundColor(EHazeCapabilityCompoundNodeType CompoundType)
	{
		switch (CompoundType)
		{
			case EHazeCapabilityCompoundNodeType::Sequence:
				return FLinearColor(1.0, 0.2, 0.2);
			case EHazeCapabilityCompoundNodeType::Selector:
				return FLinearColor(0.0, 1.0, 1.0);
			case EHazeCapabilityCompoundNodeType::StatePicker:
				return FLinearColor(1.0, 1.0, 0.2);
			case EHazeCapabilityCompoundNodeType::RunAll:
				return FLinearColor(0.2, 1.0, 0.2);
			case EHazeCapabilityCompoundNodeType::Capability:
				return FLinearColor::White;
		}
	}

	void Draw(FHazeImmediateCanvasPanelHandle ContainingPanel, TArray<FHazeCapabilityCompoundDebug> CompoundTree)
	{
		auto Paint = ContainingPanel.SlotAnchors(0.0, 0.0, 1.0, 1.0).SlotOffset(0.0).PaintCanvas();
		ClickedIndex = -1;

		int Height = 4;
		DrawNode(ContainingPanel, Paint, CompoundTree, -1, 10, Height);
	}

	void DrawNode(
		FHazeImmediateCanvasPanelHandle Panel, FHazeImmediatePaintCanvasHandle Paint,
		TArray<FHazeCapabilityCompoundDebug> CompoundTree, int ParentIndex,
		int Indent, int& Height,
		EHazeCapabilityCompoundNodeType CompoundType = EHazeCapabilityCompoundNodeType::Capability,
		FLinearColor ParentLineColor = FLinearColor(0.05, 0.05, 0.05))
	{
		int PrevChildHeight = Height - 23;
		int ParentHeight = Height;
		int IndexInParent = 0;

		for (int i = 0, Count = CompoundTree.Num(); i < Count; ++i)
		{
			auto& Node = CompoundTree[i];
			if (Node.IndexOfParent != ParentIndex)
				continue;

			IndexInParent += 1;
			int ChildHeight = Height;
			auto OuterBorder = Panel
				.SlotAnchors(0.0)
				.SlotOffset(Indent, Height)
				.SlotAutoSize(true)
				.BorderBox();

			auto Border = OuterBorder
				.SlotPadding(1.0)
				.BorderBox();

			Border.SlotPadding(6.0);

			int NodeHeight = 38;
			Height += NodeHeight;

			FLinearColor NodeLineColor;
			FLinearColor NodeBackgroundColor;

			bool bIsEvaluated = false;
			if (Node.bIsActive)
			{
				// Green lines for active nodes
				NodeLineColor = FLinearColor::Green;
				NodeBackgroundColor = FLinearColor(0.05, 0.1, 0.05, 1.0);
				bIsEvaluated = true;
			}
			else if (Node.bIsEvaluated)
			{
				// White lines for evaluated nodes
				NodeLineColor = FLinearColor(1.0, 1.0, 1.0);
				NodeBackgroundColor = FLinearColor(0.03, 0.03, 0.03, 1.0);
				bIsEvaluated = true;
			}
			else
			{
				// Gray lines for unevaluated nodes
				NodeLineColor = FLinearColor(0.05, 0.05, 0.05);
				NodeBackgroundColor = FLinearColor(0.0, 0.0, 0.0, 1.0);
			}

			// Draw the prefix
			auto HorizBox = Border.HorizontalBox();
			switch (CompoundType)
			{
				case EHazeCapabilityCompoundNodeType::Sequence:
					HorizBox
						.SlotVAlign(EVerticalAlignment::VAlign_Center)
						.Text(f"{IndexInParent}:")
						.Color(GetCompoundColor(CompoundType));
					HorizBox.Spacer(3);
				break;
				case EHazeCapabilityCompoundNodeType::Selector:
					HorizBox
						.SlotVAlign(EVerticalAlignment::VAlign_Center)
						.Text(f"[TRY]")
						.Color(GetCompoundColor(CompoundType));
					HorizBox.Spacer(3);
				break;
				case EHazeCapabilityCompoundNodeType::StatePicker:
					HorizBox
						.SlotVAlign(EVerticalAlignment::VAlign_Center)
						.Text(f"[STATE]")
						.Color(GetCompoundColor(CompoundType));
					HorizBox.Spacer(3);
				break;
				case EHazeCapabilityCompoundNodeType::RunAll:
				break;
				case EHazeCapabilityCompoundNodeType::Capability:
				break;
			}

			if (Node.Type == EHazeCapabilityCompoundNodeType::Capability)
			{
				HorizBox.Text(Node.DisplayName);
			}
			else
			{
				// Draw all children of this node
				Height += 4;
				NodeHeight += 5;

				DrawNode(Panel, Paint, CompoundTree, i, Indent+50, Height, Node.Type, NodeLineColor);

				FString ClassName = Node.DisplayName;
				ClassName.RemoveFromStart("HAZECOMPOUND");

				HorizBox.Text(ClassName).Scale(1.3).Color(GetCompoundColor(Node.Type));
				Border.Tooltip(Editor::GetFieldTooltip(GetDebugCompoundClass(Node.Type)));
			}

			if (Node.Type == EHazeCapabilityCompoundNodeType::Capability || bCanSelectNodes)
			{
				if (Border.IsHovered())
					Border.BackgroundColor(Math::Lerp(NodeBackgroundColor, FLinearColor::White, 0.02));
				else
					Border.BackgroundColor(NodeBackgroundColor);

				if (Border.WasClicked())
					ClickedIndex = i;
			}
			else
			{
				Border.BackgroundColor(NodeBackgroundColor);
			}

			if (Indent > 10)
			{
				Paint.Line(
					FVector2D(Indent - 30, ChildHeight + 19),
					FVector2D(Indent, ChildHeight + 19),
					NodeLineColor,
					2.0,
				);

				if (Node.bIsActive)
				{
					Paint.Line(
						FVector2D(Indent - 30, ParentHeight - 4),
						FVector2D(Indent - 30, ChildHeight + 19),
						NodeLineColor,
						2.0,
					);
				}
				else
				{
					Paint.Line(
						FVector2D(Indent - 30, PrevChildHeight + 19),
						FVector2D(Indent - 30, ChildHeight + 19),
						NodeLineColor,
						2.0,
					);
				}
			}

			if (i == SelectedIndex)
			{
				FLinearColor SelectedColor(0.2, 0.4, 0.8, 1.0);

				Paint.Line(
					FVector2D(Indent-5, ChildHeight),
					FVector2D(Indent-5, ChildHeight+NodeHeight-5),
					SelectedColor, 10.0,
				);

				OuterBorder.BackgroundColor(SelectedColor);
			}
			else
			{
				OuterBorder.BackgroundColor(NodeBackgroundColor);
			}

			PrevChildHeight = ChildHeight;
		}
	}
};