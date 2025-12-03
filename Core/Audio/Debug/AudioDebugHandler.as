class UAudioDebugTypeHandler : UObject
{
	// Set by debug manager
	bool bIsViewportDebugEnabled = false;
	bool bIsWorldDebugEnabled = false;

	bool DrawEnabled() { return bIsViewportDebugEnabled; }
	bool DebugEnabled() { return bIsWorldDebugEnabled; }
	EHazeAudioDebugType Type() { return EHazeAudioDebugType::NumOfTypes; }
	FString GetTitle() { return "Default"; }

	// Settings
	bool bUseCustomDrawing = false;
	bool bUseViewportDrawer = true;

	int32 DrawCount = 0;
	int32 VisualizeCount = 0;
	
	void Setup(UAudioDebugManager DebugManager) {}
	void OnWorldToggled() {}
	void OnViewToggled() {}
	void Shutdown() {}

	// Additional Menu drawing
	void Menu(UHazeAudioDevMenu DevMenu, UAudioDebugManager DebugManager, const FHazeImmediateScrollBoxHandle& Section) {}

	// Draw in viewport
	void Draw(UAudioDebugManager DebugManager, const FHazeImmediateSectionHandle& Section) { DrawCount = 0; }
	void DrawCustom(UAudioDebugManager DebugManager, const FHazeImmediateSectionHandle& MiosSection, const FHazeImmediateSectionHandle& ZoesSection) {}

	// Visualize in world
	void Visualize(UAudioDebugManager DebugManager) { VisualizeCount = 0; }
}

namespace AudioDebug
{
	UAudioDebugTypeHandler GetHandlerOfType(TSubclassOf<UAudioDebugTypeHandler> TypeClass)
	{
		auto Object = Cast<UAudioDebugTypeHandler>(FindObject(GetTransientPackage(), TypeClass.Get().Name.ToString()));
		if (Object != nullptr)
			return Object;

		auto NewObject = NewObject(GetTransientPackage(), TypeClass, TypeClass.Get().Name);
		NewObject.Transactional = true;
		return NewObject;
	}
}
