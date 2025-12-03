class UAudioDebugProxy : UAudioDebugTypeHandler
{
	EHazeAudioDebugType Type() override { return EHazeAudioDebugType::Proxy; }
	default bUseCustomDrawing = true;

	bool bShowProxyEmitterProperties = false;
	
	FString GetTitle() override
	{
		return "Proxy";
	}

	void Menu(UHazeAudioDevMenu DevMenu, UAudioDebugManager DebugManager,
			  const FHazeImmediateScrollBoxHandle& Section) override
	{
		Super::Menu(DevMenu, DebugManager, Section);

		auto CurrentState = bShowProxyEmitterProperties ? "Proxy" : "Source";

		Section.Text("Proxy Debug");
		if (Section
			.SlotPadding(20, 0)
			.Button(f"NodeProperties Toggle - {CurrentState}"))
		{
			bShowProxyEmitterProperties = !bShowProxyEmitterProperties;
		}
	}

	void DrawCustom(UAudioDebugManager DebugManager, const FHazeImmediateSectionHandle& MiosSection,
					const FHazeImmediateSectionHandle& ZoesSection) override
	{
		Super::DrawCustom(DebugManager, MiosSection, ZoesSection);
		DrawProxyDebug(DebugManager, Game::GetMio(), MiosSection.Section("Mio Proxy"));
		DrawProxyDebug(DebugManager, Game::GetZoe(), ZoesSection.Section("Zoe Proxy"));
	}

	void DrawProxyDebug(UAudioDebugManager DebugManager, AHazePlayerCharacter Player, FHazeImmediateSectionHandle Section)
	{
		if (Player == nullptr)
			return;

		auto ProxySettings = Cast<UPlayerDefaultProxyEmitterActivationSettings>(Player.GetSettings(UPlayerDefaultProxyEmitterActivationSettings));

		auto BorderColor = FLinearColor::Black;
		BorderColor.A = 0.7;
		Section.Color(BorderColor);	

		auto MainHorizBox = Section.HorizontalBox();
		auto FirstVertBox = MainHorizBox.VerticalBox();

		FirstVertBox.SlotPadding(0, 10.0);

		auto GroupsHeader = FirstVertBox.Text("Proxy Settings");
		GroupsHeader.Scale(1.5);
		GroupsHeader.Bold();
		GroupsHeader.Color(FLinearColor(0.88, 0.07, 0.52));	
		
		FirstVertBox.Text(f"Can Activate: {ProxySettings.bCanActivate}");

		const bool bDefaultProxyActive = Player.IsAnyCapabilityActive(Audio::Tags::DefaultProxyEmitter);		
		const bool bSidescrollerProxyActive = Player.IsAnyCapabilityActive(Audio::Tags::SidescrollerProxyEmitter);	

		FString ActiveProxyTag = "None";
		if(bDefaultProxyActive)
			ActiveProxyTag = "Default";
		else if(bSidescrollerProxyActive)
			ActiveProxyTag = "Sidescroller";	
		
		FirstVertBox.Text(f"Active Proxy: {ActiveProxyTag}").Color(ActiveProxyTag != "None" ? FLinearColor::Green : FLinearColor::Red);
		FirstVertBox.Text(f"Activation Distance: {ProxySettings.CameraDistanceActivationBufferDistance}");
		FirstVertBox.Text(f"Attenuation Scaling: {ProxySettings.DefaultAttenuation}");

		auto CameraGroupsHeader = FirstVertBox.Text("View");
		GroupsHeader.Scale(1.5);
		GroupsHeader.Bold();
		GroupsHeader.Color(FLinearColor(0.88, 0.07, 0.52));	
		
		FirstVertBox.Text(f"Ears distance to view: {Audio::GetEarsLocation(Player).Distance(Player.ViewLocation)}");
		FirstVertBox.Text(f"Listener distance to player: {Player.ActorLocation.Distance(Player.PlayerListener.WorldLocation)}");

		if (Player.IsMio())
			return;

		auto ProxySystem = UHazeAudioProxyEmitterSystem::Get();

		TArray<FHazeProxyLinkedObjects> LinksByObject;
		ProxySystem.GetLinksByObject(LinksByObject);

		TArray<FHazeLinkedProxyObject> ObjectLinksToObject;
		ProxySystem.GetObjectLinksToObject(ObjectLinksToObject);

		FirstVertBox.Spacer(20);

		FirstVertBox.Text("All ActiveRequests;");
		auto ActiveRequestsBox = FirstVertBox.VerticalBox()
			.SlotPadding(20, 0);

		for (const auto& Object : LinksByObject)
		{
			ActiveRequestsBox
				.SlotPadding(20, 0)
				.Text(f"Target: {Object.Target}")
				.Color(FLinearColor::Green);

			ActiveRequestsBox
				.SlotPadding(20, 0)
				.Text(f"ActivePriority: {Object.ActivePriority}")
				.Color(FLinearColor::Green);

			auto RequestsByPriority = ActiveRequestsBox.VerticalBox();

			for (const auto& RequestData: Object.RequestsByAux)
			{
				for (const auto& Request: RequestData.GetValue().Requests)
				{
					RequestsByPriority
						.SlotPadding(40, 0)
						.Text(f"Priority: {Request.Priority}");

					RequestsByPriority
						.SlotPadding(40, 0)
						.Text(f"Auxbus: {Request.AuxBus.Name}");

						RequestsByPriority
						.SlotPadding(40, 0)
						.Text(f"Instigator: {Request.Instigator.ToPlainString()}");
				}
			}

			for (const auto& ProxyEmitterData: Object.Proxies)
			{
				if (ProxyEmitterData.Proxy == nullptr)
					continue;

				auto SourceEmitter = Cast<UHazeAudioEmitter>(ProxyEmitterData.Proxy.GetOuter());

				if (SourceEmitter == nullptr)
					continue;
				
				DrawNodeProperties(DebugManager, bShowProxyEmitterProperties ? ProxyEmitterData.Proxy : SourceEmitter, RequestsByPriority);
			}
		}
	}

	void DrawNodeProperties(UAudioDebugManager DebugManager, UHazeAudioEmitter Emitter, const FHazeImmediateVerticalBoxHandle& DrawHandle)
	{
		DrawHandle
			.SlotPadding(20, 0)
			.Text(f"{Emitter.Name} - Additive Properties")
			.Color(FLinearColor::Green);

		TArray<FHazeAudioNodePropertySet> NodeProperties;
		if(DebugManager.GetNodeProperties(Emitter, NodeProperties))
		{
			auto VLBox = DrawHandle.VerticalBox();

			for	(const auto& PropertySet: NodeProperties)
			{
				if (!PropertySet.AudioNode.IsValid())
					continue;

				if (PropertySet.AdditiveProperties.Num() == 0)
					continue;

				FString NameOfTheNode = PropertySet.AudioNode.Get().Name.ToString();

				if (DebugManager.IsFiltered(NameOfTheNode, false, EDebugAudioFilter::NodeProperties))
					continue;

				VLBox
					.SlotPadding(25,0,0,0)
					.Text(NameOfTheNode)
					.Color(FLinearColor::Purple);

				for (const auto& PropertyTypeAndValue : PropertySet.AdditiveProperties)
				{

					VLBox
						.SlotPadding(50,0,0,0)
						.Text(f"{PropertyTypeAndValue.Key :n } : {PropertyTypeAndValue.Value:<2}")
						.Color(FLinearColor::Yellow);

				}
			}
		}
	}
}