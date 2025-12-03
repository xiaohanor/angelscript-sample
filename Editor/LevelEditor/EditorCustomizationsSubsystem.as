class UEditorCustomizationsSubsystem : UHazeEditorSubsystem
{
	bool bApplied = false;
	bool bHasShownVolumetricLightmapWarning = false;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (!bApplied)
		{
			bApplied = true;
			ModifyToolMenus();
			CreateKeybindCommands();
		}
	}

	void ModifyToolMenus()
	{
		UToolMenus ToolMenus = UToolMenus::Get();

		// Remove the "Platforms" button since we don't use it
		ToolMenus.RemoveEntry(n"LevelEditor.LevelEditorToolBar.PlayToolBar", n"Play", n"PlatformsMenu");
		ToolMenus.RemoveSection(n"UnrealEd.PlayWorldCommands.PlayMenu", n"QuickLaunchDevices");
		ToolMenus.RemoveSection(n"UnrealEd.PlayWorldCommands.PlayMenu", n"QuickLaunchTarget");

		// Remove game-mode
		ToolMenus.RemoveSection(n"LevelEditor.LevelEditorToolBar.OpenBlueprint", n"ProjectSettingsClasses");
		ToolMenus.RemoveSection(n"LevelEditor.LevelEditorToolBar.OpenBlueprint", n"WorldSettingsClasses");

		// Remove marketplace
		ToolMenus.RemoveSection(n"MainFrame.MainMenu.Window", n"GetContent");
		ToolMenus.RemoveEntry(n"LevelEditor.LevelEditorToolBar.AddQuickMenu", n"Content", n"OpenMarketplace");
	}

	void CreateKeybindCommands()
	{
		auto CommandsSubsystem = UUICommandsScriptingSubsystem::Get();
		CommandsSubsystem.RegisterCommandSet(n"LevelEditorCustomization");

		{
			FScriptingCommandInfo Command;
			Command.ContextName = n"LevelViewport";
			Command.Set = n"LevelEditorCustomization";
			Command.Name = n"FindActorReferences";
			Command.Label = FText::FromString("Find Actor References");
			Command.Description = FText::FromString("Show all actors in the level that reference the selected actors");
			CommandsSubsystem.RegisterCommand(Command, FExecuteCommand(this, n"OpenActorReferencesWindow"), true);
		}
	}

	UFUNCTION()
	private void OpenActorReferencesWindow(FScriptingCommandInfo Command)
	{
		UActorReferencesActions().FindActorReferences();
	}

	UFUNCTION(BlueprintOverride)
	void OnEditorLevelsChanged()
	{
		bHasShownVolumetricLightmapWarning = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnEditorLevelPreSave(ULevel Level)
	{
		if (!bHasShownVolumetricLightmapWarning)
		{
			// Verify that the volumetric lightmap isn't huge before saving this level
			uint64 Bytes = Editor::GetCurrentAllocatedVolumetricLightmapBytes(Level.GetWorld());
			float Megabytes = float(Bytes) / 1024.0 / 1024.0;
			if (Megabytes > 50.0)
			{
				FMessageDialog::Open(
					EAppMsgType::Ok,
					FText::FromString(
					f"Volumetric lightmap size for this level is really big ({Megabytes :.1} MB). "
					+ "This will cause memory issues on console.\n\n"
					+ "Please reduce the size of LightmassImportanceVolumes in the level to decrease memory usage."
					+ "\nIncreasing the 'Volumetric Lightmap Detail Cell Size' in World Settings will also reduce memory usage."));
				bHasShownVolumetricLightmapWarning = true;
			}
		}
	}
}