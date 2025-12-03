
class UEffectEventDevMenu : UHazeDevMenuEntryWidget
{
	UPROPERTY(Meta = (BindWidget))
	UHazeImmediateWidget Content;

	TArray<FHazeDebugEffectEvent> DebugEvents;
	TArray<FName> EventHandlerClasses;

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry MyGeometry, float InDeltaTime)
	{
		if (!Content.Drawer.IsVisible())
			return;

		AHazeActor Actor = Cast<AHazeActor>(GetDebugActor());
		if (Actor == nullptr)
		{
			auto S = Content.Drawer.Begin();
			S.Text("No actor selected.").Scale(2.0);
			if (S.Button("Select Actor"))
			{
				// Trigger actor picker?
				DevMenu::TriggerActorPicker();
			}
			Content.Drawer.End();
			return;
		}

		auto Root = Content.Drawer.BeginVerticalBox();
		FString ActorName = Actor.Name.ToString();
		if(Network::IsGameNetworked())
		{
			if(Actor.HasControl())
				ActorName += " (Control)";
			else
				ActorName += " (Remote)";
		}
		Root.SlotPadding(4).Text(f"{ActorName}").Scale(2.0);

		DebugEvents.Reset();
		EffectEventDebug::ListEffectEvents(Actor, DebugEvents);

		EventHandlerClasses.Reset();
		for (auto Event : DebugEvents)
			EventHandlerClasses.AddUnique(Event.EventClass.Get().GetName());

		if (DebugEvents.Num() == 0)
		{
			Root.Text("Actor has not received or bound any effect events.");
			Content.Drawer.End();
			return;
		}

		auto Splitter = Root.SlotFill().Splitter();
		auto Sidebar = Splitter.SlotFill(0.5).VerticalBox();

		// List of event handlers
		auto HandlerList = Sidebar.SlotFill().SlotPadding(0).ListView(EventHandlerClasses.Num());
		HandlerList.BackgroundColor(FLinearColor(0.05, 0.05, 0.045, 1.0));
		HandlerList.DefaultSelectedItem(0);
		for (int ItemIndex : HandlerList)
		{
			FName HandlerName = EventHandlerClasses[ItemIndex];

			auto Item = HandlerList.Item(HandlerName);
			Item.Text(f"{HandlerName}").Scale(1.1);
		}

		// Determine which handler class is selected
		FName SelectedHandlerName;
		if (EventHandlerClasses.IsValidIndex(HandlerList.SelectedItemIndex))
			SelectedHandlerName = EventHandlerClasses[HandlerList.SelectedItemIndex];

		// List of effect events
		TArray<FHazeDebugEffectEvent> EventsInSelectedHandler;
		for (auto& DebugEvent : DebugEvents)
		{
			if (DebugEvent.EventClass.Get().Name == SelectedHandlerName)
				EventsInSelectedHandler.Add(DebugEvent);
		}

		Sidebar.Spacer(10);
		auto EventList = Sidebar.SlotFill().SlotPadding(0).ListView(EventsInSelectedHandler.Num());
		EventList.BackgroundColor(FLinearColor(0.05, 0.05, 0.045, 1.0));
		EventList.SelectedColor(FLinearColor(0.2, 0.0, 0.5, 0.5));
		EventList.DefaultSelectedItem(0);
		for (int Index : EventList)
		{
			FHazeDebugEffectEvent& DebugEvent = EventsInSelectedHandler[Index];
			auto Item = EventList.Item(DebugEvent.EventName);
			Item.Text(DebugEvent.EventName.ToString()).Scale(1.1);
		}

		// Details of selected event
		auto Details = Splitter.Section();
		int SelectedEventIndex = EventList.SelectedItemIndex;
		if (EventsInSelectedHandler.IsValidIndex(SelectedEventIndex))
		{
			FHazeDebugEffectEvent& Event = EventsInSelectedHandler[SelectedEventIndex];

			Details.Text(f"{Event.EventName}").Scale(1.5);
			if (!Event.Description.IsEmpty())
				Details.Text(f"{Event.Description}").Color(FLinearColor(0.4, 0.4, 0.4, 1.0));

			Details.Spacer(12.0);

			// Parameter struct type
			if (Event.ParamStructType.Len() != 0)
			{
				Details.Text(f"Parameters: {Event.ParamStructType}");
			}

			// Last time this event was triggered in game
			if (Event.LastTriggerGameTime >= 0.0 && Editor::HasPrimaryGameWorld())
			{
				FScopeDebugPrimaryWorld ScopeWorld;

				float CurGameTime = Time::GameTimeSeconds;
				int Seconds = Math::FloorToInt(CurGameTime - Event.LastTriggerGameTime);
				Details.Text(f"Last triggered {Seconds} seconds ago");
			}

			Details.Spacer(20);

			// List of handlers bound to this event
			if (Event.BoundByHandlers.Num() != 0)
			{
				Details.Text("Handled by:");
				for (FName Handler : Event.BoundByHandlers)
					Details.SlotPadding(10, 0, 0, 0).Text(Handler.ToString());
			}
			else
			{
				Details.Text("No handlers bound.");
			}

			// Button to trigger the event for debug purposes
			Details.Spacer(20);
			if (Actor.HasActorBegunPlay() && Actor.World.IsGameWorld())
			{
				if (Details.Button("Trigger"))
				{
					EffectEventDebug::DebugTriggerEffectEvent(Actor, Event.EventClass, Event.EventName);
				}
			}
		}

		Content.Drawer.End();
	}
};