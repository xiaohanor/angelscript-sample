
enum ENetworkProfilerViewSpan
{
	PrevSecond,
	PeakSecond,
	PeakMinute,
	TotalSession
};

enum ENetworkProfilerViewType
{
	ByChannel,
	ByObject,
	ByMessageType,
	ByRPCFunction,
	ByMessageSegment,
};

class UNetworkDevMenu : UHazeDevMenuEntryImmediateWidget
{
	ENetworkProfilerViewSpan ViewSpan = ENetworkProfilerViewSpan::PrevSecond;
	ENetworkProfilerViewType ViewType = ENetworkProfilerViewType::ByRPCFunction;

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry MyGeometry, float InDeltaTime)
	{
		if (!Drawer.IsVisible())
			return;

		auto Root = Drawer.BeginVerticalBox();

		auto TopLine = Root.HorizontalBox();

		// Draw the current measured data
		auto InfoBar = TopLine.SlotFill().Section().VerticalBox();
		InfoBar.Text("Network Session").Scale(2.0);
		if (Editor::HasPrimaryGameWorld())
		{
			FScopeDebugPrimaryWorld ScopeWorld;
			if (Network::IsGameNetworked())
			{
				// Show which player is host and which is guest
				auto HostBox = InfoBar.HorizontalBox();
				if (Network::HasWorldControl() == Game::Zoe.HasControl())
				{
					HostBox.SlotPadding(2, 2, 20, 2).Text("Zoe Host").Scale(1.1).Color(PlayerColor::Zoe);
					HostBox.Text("Mio Guest").Scale(1.1).Color(PlayerColor::Mio);
				}
				else
				{
					HostBox.SlotPadding(2, 2, 20, 2).Text("Mio Host").Scale(1.1).Color(PlayerColor::Mio);
					HostBox.Text("Zoe Guest").Scale(1.1).Color(PlayerColor::Zoe);
				}

				// Show the current ping as measured
				ShowInfo(InfoBar, "Measured Ping (roundtrip):", f"{Network::PingRoundtripSeconds * 1000.0 :0.0} ms");

				auto Session = Network::GetNetworkProfilerSession();
				if (Session != nullptr && Session.PrevSecond.Duration > 0)
				{
					int SentPackets = Session.PrevSecond.Total.SentMessageCount;
					float SentKbit = float(Session.PrevSecond.Total.SentBits) / Session.PrevSecond.Duration / 1024.0;

					int RecvPackets = Session.PrevSecond.Total.ReceivedMessageCount;
					float RecvKbit = float(Session.PrevSecond.Total.ReceivedBits) / Session.PrevSecond.Duration / 1024.0;

					if (Game::Mio.HasControl())
					{
						ShowInfo(InfoBar, "Mio Sending", f"{SentKbit :.0} kbit/s in {SentPackets} packets/s");
						ShowInfo(InfoBar, "Zoe Sending", f"{RecvKbit :.0} kbit/s in {RecvPackets} packets/s");
					}
					else
					{
						ShowInfo(InfoBar, "Mio Sending", f"{RecvKbit :.0} kbit/s in {RecvPackets} packets/s");
						ShowInfo(InfoBar, "Zoe Sending", f"{SentKbit :.0} kbit/s in {SentPackets} packets/s");
					}
				}
			}
			else
			{
				InfoBar.Text("Running game session is local.");
			}
		}
		else
		{
			InfoBar.Text("No network game session running.");
		}

		// Draw information about the throttling
		auto ThrottleSection = TopLine.SlotFill().Section();
		ThrottleSection.Text("Throttle Configuration").Scale(2.0);

		auto ThrottleSplit = ThrottleSection.HorizontalBox();
		auto ThrottleBar = ThrottleSplit.SlotFill().VerticalBox();

		FHazeNetThrottleOptions Throttle = NetworkDebug::GetCurrentThrottleOptions();
		bool bThrottleChanged = false;

		float CurrentPing = Math::RoundToFloat(Throttle.Ping * 2.0);
		float CurrentVariance = Math::RoundToFloat(Throttle.PingVariance * 2.0);
		float CurrentLoss = Math::RoundToFloat(Throttle.PacketLoss * 100.0);
		float CurrentOutOfOrder = Math::RoundToFloat(Throttle.OutOfOrder * 100.0);

		// Ping Setting
		auto PingInput = ThrottleBar.FloatInput();
		PingInput.Label("Ping (Roundtrip)");
		PingInput.Value(CurrentPing);
		PingInput.MinMax(0.0, 1000.0);
		PingInput.Delta(1.0);

		if (!Math::IsNearlyEqual(PingInput, CurrentPing))
		{
			Throttle.Ping = PingInput / 2.0;
			bThrottleChanged = true;
		}

		// Ping Variance Setting
		auto VarianceInput = ThrottleBar.FloatInput();
		VarianceInput.Label("Ping Variance");
		VarianceInput.Value(CurrentVariance);
		VarianceInput.MinMax(0.0, 1000.0);
		VarianceInput.Delta(1.0);

		if (!Math::IsNearlyEqual(VarianceInput, CurrentVariance))
		{
			Throttle.PingVariance = VarianceInput / 2.0;
			bThrottleChanged = true;
		}

		// Packet Loss Setting
		auto LossInput = ThrottleBar.FloatInput();
		LossInput.Label("Packet Loss %");
		LossInput.Value(CurrentLoss);
		LossInput.MinMax(0.0, 25.0);
		LossInput.Delta(1.0);

		if (!Math::IsNearlyEqual(LossInput, CurrentLoss))
		{
			Throttle.PacketLoss = LossInput / 100.0;
			bThrottleChanged = true;
		}

		// Out of Order Setting
		auto OutOfOrderInput = ThrottleBar.FloatInput();
		OutOfOrderInput.Label("Out of Order %");
		OutOfOrderInput.Value(CurrentOutOfOrder);
		OutOfOrderInput.MinMax(0.0, 100.0);
		OutOfOrderInput.Delta(1.0);

		if (!Math::IsNearlyEqual(OutOfOrderInput, CurrentOutOfOrder))
		{
			Throttle.OutOfOrder = OutOfOrderInput / 100.0;
			bThrottleChanged = true;
		}

		if (bThrottleChanged)
		{
			// Update throttle settings when changing the value
			NetworkDebug::SetThrottleOptions(Throttle);
		}

		// Profiles
		auto ProfilesList = ThrottleSplit.VerticalBox();

		TArray<FHazeNetThrottleProfile> Profiles = NetworkDebug::GetThrottleProfiles();
		for(const FHazeNetThrottleProfile& Profile : Profiles)
		{
			ThrottleProfileButton(ProfilesList, Throttle, Profile);
		}

		// Draw the network profiler
		if (Editor::HasPrimaryGameWorld())
		{
			FScopeDebugPrimaryWorld ScopeWorld;

			auto Session = Network::GetNetworkProfilerSession();
			if (Session != nullptr)
			{
				auto ProfilerBox = Root.SlotFill().BorderBox().BackgroundStyle("DevMenu.RoundRect", FLinearColor::Black);
				DrawProfilerSession(Session, ProfilerBox);
			}
		}

		Drawer.End();
	}

	void ThrottleProfileButton(FHazeImmediateVerticalBoxHandle List,
							   FHazeNetThrottleOptions CurrentThrottle,
							   FHazeNetThrottleProfile Profile)
	{
		bool bIsActive = true;
		if (CurrentThrottle.Ping != Profile.Options.Ping)
			bIsActive = false;
		if (CurrentThrottle.PingVariance != Profile.Options.PingVariance)
			bIsActive = false;
		if (CurrentThrottle.OutOfOrder != Profile.Options.OutOfOrder)
			bIsActive = false;
		if (CurrentThrottle.PacketLoss != Profile.Options.PacketLoss)
			bIsActive = false;

		auto Button = List.Button(Profile.Name);
		Button.Padding(2.0);
		Button.Tooltip(f"Set connection throttle options to the '{Profile.Name}' profile");
		if (bIsActive)
			Button.BackgroundColor(FLinearColor(0.1, 0.3, 0.1));

		if (Button)
			NetworkDebug::SetThrottleOptions(Profile.Options);
	}

	void DrawProfilerSession(UHazeNetworkProfilerSession Session, FHazeImmediateBorderBoxHandle MainBox)
	{
		const float GraphWidthSeconds = 60.0;
		const float GraphHeightKbps = 220.0;
		const float LimitKbps = 192.0;

		bool bIsNetworkSim = Editor::HasSecondaryGameWorld();

		FLinearColor SendColor;
		FLinearColor RecvColor;

		if (Game::Mio.HasControl())
		{
			SendColor = PlayerColor::Mio;
			RecvColor = PlayerColor::Zoe;
		}
		else
		{
			SendColor = PlayerColor::Zoe;
			RecvColor = PlayerColor::Mio;
		}

		// Incoming/Outgoing Graph
		auto HorizSplit = MainBox.HorizontalBox();

		auto LeftList = HorizSplit.SlotFill().VerticalBox();
		LeftList.Text("Network Profiler").Scale(2.0);

		auto LeftBox = LeftList.SlotFill().BorderBox();
		auto GraphPaint = LeftBox.PaintCanvas();
		FVector2D GraphSize = GraphPaint.WidgetGeometrySize;
		float KbpsToHeight = (GraphSize.Y - 30.0) / GraphHeightKbps;

		// Limit line
		float LimitHeight = (GraphHeightKbps - LimitKbps) * KbpsToHeight;
		GraphPaint.Line(
			FVector2D(0.0, LimitHeight),
			FVector2D(GraphSize.X, LimitHeight),
			FLinearColor::Red,
			2.0);

		GraphPaint.Text(FVector2D(40.0, LimitHeight - 20.0), "LIMIT: 192kbps", FLinearColor::Red);

		// Line data
		int StartIndex = Math::Max(0, Session.SecondTotals.Num() - 60);
		int PointCount = Math::Min(60, Session.SecondTotals.Num());

		float PointSpacing = (GraphSize.X - 30.0) / 59.0;
		for (int i = 1; i < PointCount; ++i)
		{
			int PointIndex = StartIndex + i;
			const FHazeNetworkProfilerTotals& SecondData = Session.SecondTotals[PointIndex];
			const FHazeNetworkProfilerTotals& PrevSecondData = Session.SecondTotals[PointIndex - 1];

			float PointRecvKbps = float(SecondData.Total.ReceivedBits) / SecondData.Duration / 1024.0;
			float PrevPointRecvKbps = float(PrevSecondData.Total.ReceivedBits) / PrevSecondData.Duration / 1024.0;

			float PointRecvHeight = (GraphHeightKbps - PointRecvKbps) * KbpsToHeight;
			float PrevPointRecvHeight = (GraphHeightKbps - PrevPointRecvKbps) * KbpsToHeight;

			GraphPaint.Line(
				FVector2D(30.0 + (i - 1) * PointSpacing, PrevPointRecvHeight),
				FVector2D(30.0 + i * PointSpacing, PointRecvHeight),
				RecvColor,
				2.0);

			float PointSentKbps = float(SecondData.Total.SentBits) / SecondData.Duration / 1024.0;
			float PrevPointSentKbps = float(PrevSecondData.Total.SentBits) / PrevSecondData.Duration / 1024.0;

			float PointSentHeight = (GraphHeightKbps - PointSentKbps) * KbpsToHeight;
			float PrevPointSentHeight = (GraphHeightKbps - PrevPointSentKbps) * KbpsToHeight;

			GraphPaint.Line(
				FVector2D(30.0 + (i - 1) * PointSpacing, PrevPointSentHeight),
				FVector2D(30.0 + i * PointSpacing, PointSentHeight),
				SendColor,
				2.0);
		}

		// Axes
		GraphPaint.Line(
			FVector2D(30.0, 0.0),
			FVector2D(30.0, GraphSize.Y),
			FLinearColor::White,
			1.0);

		GraphPaint.Line(
			FVector2D(0.0, GraphSize.Y - 30.0),
			FVector2D(GraphSize.X, GraphSize.Y - 30.0),
			FLinearColor::White,
			1.0);

		// Global data
		auto RightList = HorizSplit.SlotFill().VerticalBox();

		auto SpanButtons = RightList.HorizontalBox();
		SpanButton(SpanButtons, ENetworkProfilerViewSpan::PrevSecond, "Last Second");
		SpanButton(SpanButtons, ENetworkProfilerViewSpan::PeakSecond, "Peak Second");
		SpanButton(SpanButtons, ENetworkProfilerViewSpan::PeakMinute, "Peak Minute");
		SpanButton(SpanButtons, ENetworkProfilerViewSpan::TotalSession, "Total Session");

		auto ViewButtons = RightList.HorizontalBox();
		ViewButton(ViewButtons, ENetworkProfilerViewType::ByChannel, "Channel");
		ViewButton(ViewButtons, ENetworkProfilerViewType::ByObject, "Object");
		ViewButton(ViewButtons, ENetworkProfilerViewType::ByMessageType, "Type");
		ViewButton(ViewButtons, ENetworkProfilerViewType::ByRPCFunction, "Function");
		ViewButton(ViewButtons, ENetworkProfilerViewType::ByMessageSegment, "Segment");

		RightList.Spacer(3.0);

		auto DataColumnContainer = RightList.SlotFill(5).ScrollBox().ScrollBox(EOrientation::Orient_Horizontal).HorizontalBox();

		const FHazeNetworkProfilerSpan& SpanData = GetViewSpanData(Session);

		auto Size = RightList.WidgetGeometrySize;

		if (SpanData.Duration < 2.0)
			DisplayDataTwoColumns(DataColumnContainer, SpanData, Size);
		else
			DisplayDataFourColumns(DataColumnContainer, SpanData, Size);

		// Totals
		auto Box = RightList.SlotFill().SlotVAlign(EVerticalAlignment::VAlign_Bottom).HorizontalBox();
		Box.SlotFill().Text("Total");

		FString SendText;
		FString RecvText;

		if (SpanData.Duration < 2.0)
		{
			float SentKbit = float(SpanData.Total.SentBits) / 1024.0;
			float RecvKbit = float(SpanData.Total.ReceivedBits) / 1024.0;

			SendText = f"{SentKbit :.1} kb ({SpanData.Total.SentMessageCount}x)";
			RecvText = f"{RecvKbit :.1} kb ({SpanData.Total.ReceivedMessageCount}x)";
		}
		else
		{
			float SentKbps = float(SpanData.Total.SentBits) / SpanData.Duration / 1024.0;
			float RecvKbps = float(SpanData.Total.ReceivedBits) / SpanData.Duration / 1024.0;

			SendText = f"{SentKbps :.1} kbps";
			RecvText = f"{RecvKbps :.1} kbps";
		}

		auto SendBox = Box.BorderBox().MinDesiredWidth(100.0);
		auto RecvBox = Box.BorderBox().MinDesiredWidth(100.0);

		SendBox.SlotHAlign(EHorizontalAlignment::HAlign_Right).Text(SendText).Color(SendColor);
		RecvBox.SlotHAlign(EHorizontalAlignment::HAlign_Right).Text(RecvText).Color(RecvColor);
	}

	void DisplayDataTwoColumns(FHazeImmediateHorizontalBoxHandle& DataColumnContainer, const FHazeNetworkProfilerSpan& SpanData, FVector2D ParentSize)
	{
		FLinearColor SendColor;
		FLinearColor RecvColor;

		if (Game::Mio.HasControl())
		{
			SendColor = PlayerColor::Mio;
			RecvColor = PlayerColor::Zoe;
		}
		else
		{
			SendColor = PlayerColor::Zoe;
			RecvColor = PlayerColor::Mio;
		}

		auto ColumnWidth = ParentSize.X / 7 * 2;
		auto MessageColumn = DataColumnContainer.SlotHAlign(EHorizontalAlignment::HAlign_Left).BorderBox().MinDesiredWidth(ColumnWidth).VerticalBox();
		auto SentColumn = DataColumnContainer.SlotHAlign(EHorizontalAlignment::HAlign_Right).BorderBox().MinDesiredWidth(ColumnWidth).VerticalBox();
		auto ReceivedColumn = DataColumnContainer.SlotHAlign(EHorizontalAlignment::HAlign_Right).BorderBox().MinDesiredWidth(ColumnWidth).VerticalBox();
		MessageColumn.BorderBox().SlotHAlign(EHorizontalAlignment::HAlign_Left).Text("Message");
		SentColumn.BorderBox().SlotHAlign(EHorizontalAlignment::HAlign_Right).Text("Sent Data");
		ReceivedColumn.BorderBox().SlotHAlign(EHorizontalAlignment::HAlign_Right).Text("Received Data");
		const TMap<FName, FHazeNetworkProfilerStat>& StatData = GetStatData(SpanData);
		for (auto Elem : StatData)
		{
			const FHazeNetworkProfilerStat& Stat = Elem.Value;

			// auto Box = ListScrollBox.HorizontalBox().SlotFill();
			MessageColumn.BorderBox().Text(f"{Elem.Key}");

			FString SendText;
			FString RecvText;

			float SentKbit = float(Stat.SentBits) / 1024.0;
			float RecvKbit = float(Stat.ReceivedBits) / 1024.0;

			SendText = f"{SentKbit :.1} kb ({Stat.SentMessageCount}x)";
			RecvText = f"{RecvKbit :.1} kb ({Stat.ReceivedMessageCount}x)";

			SentColumn.BorderBox().SlotHAlign(EHorizontalAlignment::HAlign_Right).Text(SendText).Color(SendColor);
			ReceivedColumn.BorderBox().SlotHAlign(EHorizontalAlignment::HAlign_Right).Text(RecvText).Color(RecvColor);
		}
	}

	void DisplayDataFourColumns(FHazeImmediateHorizontalBoxHandle& DataColumnContainer, const FHazeNetworkProfilerSpan& SpanData, FVector2D Size)
	{
		FLinearColor SendColor;
		FLinearColor RecvColor;

		if (Game::Mio.HasControl())
		{
			SendColor = PlayerColor::Mio;
			RecvColor = PlayerColor::Zoe;
		}
		else
		{
			SendColor = PlayerColor::Zoe;
			RecvColor = PlayerColor::Mio;
		}
		auto MessageColumn = DataColumnContainer.SlotHAlign(EHorizontalAlignment::HAlign_Left).BorderBox().MinDesiredWidth(350).VerticalBox();
		auto SentDataColumn = DataColumnContainer.SlotHAlign(EHorizontalAlignment::HAlign_Right).BorderBox().MinDesiredWidth(200).VerticalBox();
		auto SentCallsColumn = DataColumnContainer.SlotHAlign(EHorizontalAlignment::HAlign_Right).BorderBox().MinDesiredWidth(200).VerticalBox();
		auto ReceivedDataColumn = DataColumnContainer.SlotHAlign(EHorizontalAlignment::HAlign_Right).BorderBox().MinDesiredWidth(200).VerticalBox();
		auto ReceivedCallsColumn = DataColumnContainer.SlotHAlign(EHorizontalAlignment::HAlign_Right).BorderBox().MinDesiredWidth(200).VerticalBox();
		MessageColumn.BorderBox().SlotHAlign(EHorizontalAlignment::HAlign_Left).Text("Message");
		SentDataColumn.BorderBox().SlotHAlign(EHorizontalAlignment::HAlign_Right).Text("Sent Data");
		SentCallsColumn.BorderBox().SlotHAlign(EHorizontalAlignment::HAlign_Right).Text("Sent Calls");
		ReceivedDataColumn.BorderBox().SlotHAlign(EHorizontalAlignment::HAlign_Right).Text("Received Data");
		ReceivedCallsColumn.BorderBox().SlotHAlign(EHorizontalAlignment::HAlign_Right).Text("Received Calls");
		const TMap<FName, FHazeNetworkProfilerStat>& StatData = GetStatData(SpanData);
		for (auto Elem : StatData)
		{
			const FHazeNetworkProfilerStat& Stat = Elem.Value;

			// auto Box = ListScrollBox.HorizontalBox().SlotFill();
			MessageColumn.BorderBox().Text(f"{Elem.Key}");

			FString SendDataText;
			FString SendCallsText;
			FString RecvDataText;
			FString RecvCallsText;

			float SentKbit = float(Stat.SentBits) / 1024.0;
			float RecvKbit = float(Stat.ReceivedBits) / 1024.0;
			float SentKbps = SentKbit / SpanData.Duration;
			float RecvKbps = RecvKbit / SpanData.Duration;

			SendDataText = f"{SentKbit :.1} kb ({SentKbps :.1} kb/s)";
			SendCallsText = f"{Stat.SentMessageCount}x ({Stat.SentMessageCount/SpanData.Duration :.1}x/s)";
			RecvDataText = f"{RecvKbit :.1} kb ({RecvKbps :.1} kb/s)";
			RecvCallsText = f"{Stat.ReceivedMessageCount}x ({Stat.ReceivedMessageCount/SpanData.Duration :.1}x/s)";

			SentDataColumn.BorderBox().SlotHAlign(EHorizontalAlignment::HAlign_Right).Text(SendDataText).Color(SendColor);
			SentCallsColumn.BorderBox().SlotHAlign(EHorizontalAlignment::HAlign_Right).Text(SendCallsText).Color(SendColor);
			ReceivedDataColumn.BorderBox().SlotHAlign(EHorizontalAlignment::HAlign_Right).Text(RecvDataText).Color(RecvColor);
			ReceivedCallsColumn.BorderBox().SlotHAlign(EHorizontalAlignment::HAlign_Right).Text(RecvCallsText).Color(RecvColor);
		}
	}

	void SpanButton(FHazeImmediateHorizontalBoxHandle Buttons, ENetworkProfilerViewSpan Type, const FString& Text)
	{
		auto Button = Buttons.SlotFill().Button(Text);
		Button.Padding(2.0);
		if (ViewSpan == Type)
			Button.BackgroundColor(FLinearColor(0.1, 0.3, 0.1));
		if (Button)
			ViewSpan = Type;
	}

	void ViewButton(FHazeImmediateHorizontalBoxHandle Buttons, ENetworkProfilerViewType Type, const FString& Text)
	{
		auto Button = Buttons.SlotFill().Button(Text);
		Button.Padding(2.0);
		if (ViewType == Type)
			Button.BackgroundColor(FLinearColor(0.1, 0.3, 0.1));
		if (Button)
			ViewType = Type;
	}

	const TMap<FName, FHazeNetworkProfilerStat>& GetStatData(const FHazeNetworkProfilerSpan& SpanData)
	{
		switch (ViewType)
		{
			case ENetworkProfilerViewType::ByChannel:
				return SpanData.ByChannel;
			case ENetworkProfilerViewType::ByObject:
				return SpanData.ByObject;
			case ENetworkProfilerViewType::ByMessageType:
				return SpanData.ByMessageType;
			case ENetworkProfilerViewType::ByRPCFunction:
				return SpanData.ByRPCFunction;
			case ENetworkProfilerViewType::ByMessageSegment:
				return SpanData.ByMessageSegment;
		}
	}

	const FHazeNetworkProfilerSpan& GetViewSpanData(UHazeNetworkProfilerSession Session)
	{
		switch (ViewSpan)
		{
			case ENetworkProfilerViewSpan::PrevSecond:
				return Session.PrevSecond;
			case ENetworkProfilerViewSpan::PeakSecond:
				return Session.PeakSecond;
			case ENetworkProfilerViewSpan::PeakMinute:
				return Session.PeakMinute;
			case ENetworkProfilerViewSpan::TotalSession:
				return Session.TotalSession;
		}
	}

	void ShowInfo(FHazeImmediateVerticalBoxHandle VerticalBox, FString Label, FString Value)
	{
		auto Box = VerticalBox.HorizontalBox();
		Box.BorderBox().SlotPadding(0).MinDesiredWidth(200).Text(Label);
		Box.Text(Value);
	}
}