class UAudioDebugMovement: UAudioDebugTypeHandler
{
	EHazeAudioDebugType Type() override { return EHazeAudioDebugType::Movement; }

	default bUseCustomDrawing = true;
	
	FString GetTitle() override
	{
		return "Movement";
	}

	void DrawCustom(UAudioDebugManager DebugManager, 
		const FHazeImmediateSectionHandle& MiosSection,
		const FHazeImmediateSectionHandle& ZoesSection) override
	{
		DebugMovement(Game::GetMio(), MiosSection.Section("Mio Movement"));
		DebugMovement(Game::GetZoe(), ZoesSection.Section("Zoe Movement"));
	}

	void DebugMovement(AHazePlayerCharacter Player, FHazeImmediateSectionHandle Section)
	{
		const FName PlayerName = Player.IsMio() ? n"Mio" : n"Zoe";
		UPlayerMovementAudioComponent MoveAudioComp = UPlayerMovementAudioComponent::Get(Player);		

		auto BorderColor = FLinearColor::Black;
		BorderColor.A = 0.2;
		Section.Color(BorderColor);	

		auto MainHorizBox = Section.HorizontalBox();
		auto FirstVertBox = MainHorizBox.VerticalBox();

		FirstVertBox.SlotPadding(0, 10.0);

		auto GroupsHeader = FirstVertBox.Text("Active Groups");
		GroupsHeader.Scale(2.0);
		GroupsHeader.Bold();
		GroupsHeader.Color(FLinearColor(0.8, 0.5, 0, 1));		

		auto Border = FirstVertBox.BorderBox();

		Border.BackgroundStyle("DevMenu.RoundRect", BorderColor);
		Border.MinDesiredHeight(200);
		Border.MaxDesiredHeight(200);
		
		TMap<FName, FName> GroupsAndTags;
		TArray<FName> ActiveGroups;
		MoveAudioComp.GetActiveMovementGroups(ActiveGroups);		

		auto TagsVertBox = Border.VerticalBox();

		TArray<FName> UniqueSources;
		for(auto Group : ActiveGroups)
		{
			const FName SourceName = MoveAudioComp.GetMovementTagInstigatorName(Group);

			if(SourceName != NAME_None)
				UniqueSources.AddUnique(SourceName);
		}

		for(auto AnimSource : UniqueSources)
		{
			auto TagGroupBox = TagsVertBox.VerticalBox();
			TagGroupBox.SlotPadding(0, 10.0);
			auto SourceTextBox = TagGroupBox.Section();
			SourceTextBox.Color(BorderColor);
			FLinearColor SourceColor = AnimSource.ToString().Contains("_ABP_") ? FLinearColor::Yellow : FLinearColor::Teal;		

			auto SourceText = SourceTextBox.Text(AnimSource.ToString());
			SourceText.Scale(1.5);
			SourceText.Color(SourceColor);

			for(auto Group : ActiveGroups)
			{	
				const FName SourceName = MoveAudioComp.GetMovementTagInstigatorName(Group);
				if(SourceName != AnimSource)
					continue;

				const FName ActiveTag = MoveAudioComp.GetActiveMovementTag(Group);	
				auto GroupTagText = SourceTextBox.Text(f"{Group} -> {ActiveTag}");	

				GroupTagText.Color(FLinearColor::White);
				GroupTagText.Scale(1.5);

				TEMPORAL_LOG(Player)
				.Value("Active Tag", ActiveTag)
				.Value("Instigator", SourceName);
			}
			
		}


		FirstVertBox.SlotPadding(0, 10.0);

		auto RequestsHeader = FirstVertBox.Text("Requested Movement");
		RequestsHeader.Scale(2.0);
		RequestsHeader.Bold();
		RequestsHeader.Color(FLinearColor(0.8, 0.5, 0, 1));	

		// Bit of a hacky way to check all movement flags
		int32 EnumIndex = 1;
		while(EnumIndex < int(EMovementAudioFlags::EMovementAudioFlags_MAX))
		{
			EMovementAudioFlags MovementFlag = EMovementAudioFlags(EnumIndex);
			const bool bActive = MoveAudioComp.CanPerformMovement(MovementFlag);
			auto FootstepsText = FirstVertBox.Text(f"{MovementFlag}}: {bActive}");
			FootstepsText.Scale(1.8);

			FLinearColor Color = bActive ? FLinearColor::Green : FLinearColor::Gray;

			if(MoveAudioComp.IsMovementBlocked(MovementFlag))
				Color = FLinearColor::Red;
			
			FootstepsText.Color(Color);

			EnumIndex *= 2;
		}


		FirstVertBox.SlotPadding(0, 10.0);
		auto PropertiesHeader = FirstVertBox.Text("Properties");
		PropertiesHeader.Scale(2.0);
		PropertiesHeader.Bold();
		PropertiesHeader.Color(FLinearColor(0.87, 0.57, 0.05));		

		auto PropertiesVertBox = FirstVertBox.VerticalBox();
		PropertiesVertBox.SlotPadding(10.0, 5.0, 0, 0);

		const float MovementSpeed = UHazeMovementComponent::Get(Player).Velocity.Size();
		AddMovementPropertyTracking(PropertiesVertBox, n"Movement Speed:", MovementSpeed);
		
		#if TEST
		if(MoveAudioComp.DebugLeftFootMaterial != nullptr)
			AddMovementPropertyTracking(PropertiesVertBox, n"Left Foot Material:", MoveAudioComp.DebugLeftFootMaterial.FootstepData.FootstepTag.ToString());

		if(MoveAudioComp.DebugRightFootMaterial != nullptr)
			AddMovementPropertyTracking(PropertiesVertBox, n"Right Foot Material:", MoveAudioComp.DebugRightFootMaterial.FootstepData.FootstepTag.ToString());

		#endif

		// Exertion debug
		auto SecondVertBox = MainHorizBox.VerticalBox();
		SecondVertBox.SlotPadding(0, 10.0);

		UPlayerEffortAudioComponent EffortComp = UPlayerEffortAudioComponent::Get(Player);

		auto ExertionHeader = SecondVertBox.Text("Exertion");
		ExertionHeader.Scale(2.0);
		ExertionHeader.Bold();
		ExertionHeader.Color(FLinearColor(0.87, 0.57, 0.05));	
	
		AddMovementPropertyTracking(SecondVertBox, n"Exertion Level:", ""+EEffortAudioIntensity(EffortComp.GetHighestEffortCategory()));
		const float ExertionAmount = EffortComp.GetExertion();
		AddMovementPropertyTracking(SecondVertBox, n"Exertion Amount:", ExertionAmount);

		const FEffortData CurrentEffortData = EffortComp.GetCurrentEffortData();
		if(CurrentEffortData.Intensity != EEffortAudioIntensity::None)
		{
			const float MovementTimeActive = EffortComp.GetEffortTimeActive();
			AddMovementPropertyTracking(SecondVertBox, n"Current Effort Time:", MovementTimeActive);

			const float ExertionFactor = CurrentEffortData.EffortFactor;
			AddMovementPropertyTracking(SecondVertBox, n"Effort Factor:", ExertionFactor);
			
			const float RecoveryFactor = CurrentEffortData.RecoveryFactor;
			AddMovementPropertyTracking(SecondVertBox, n"Recovery Factor:", RecoveryFactor);
		}
		else
		{
			AddMovementPropertyTracking(SecondVertBox, n"Current Effort Time:", "-");			
			AddMovementPropertyTracking(SecondVertBox, n"Effort Factor:", "-");
			AddMovementPropertyTracking(SecondVertBox, n"Recovery Factor:", "-");
		}

	}

	void AddMovementPropertyTracking(FHazeImmediateVerticalBoxHandle& MainBox, const FName PropertyName, const float PropertyValue)
	{
		auto HorizBox = MainBox.HorizontalBox();
		HorizBox.SlotMaxWidth(250.0);
		HorizBox.SlotFill(1);

		auto NameText = HorizBox.Text(PropertyName.ToString());		
		NameText.Scale(1.75);

		auto PropText = HorizBox.Text(f"{PropertyValue :.1}");
		PropText.Scale(1.75);

		MainBox.SlotPadding(10.0, 20.0, 0, 0);
	}

	void AddMovementPropertyTracking(FHazeImmediateVerticalBoxHandle& MainBox, const FName PropertyName, const FString PropertyValue)
	{
		auto HorizBox = MainBox.HorizontalBox();
		HorizBox.SlotMaxWidth(250.0);
		HorizBox.SlotFill(1);

		auto NameText = HorizBox.Text(PropertyName.ToString());		
		NameText.Scale(1.75);

		auto PropText = HorizBox.Text(PropertyValue);
		PropText.Scale(1.75);

		MainBox.SlotPadding(10.0, 20.0, 0, 0);
	}

}