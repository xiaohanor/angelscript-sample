class UCopyActorsAsArrayMenuExtension : UScriptActorMenuExtension
{
	default ExtensionPoint = n"ActorGeneral";
	default ExtensionOrder = EScriptEditorMenuExtensionOrder::After;

	// Specify one or more classes for which the menu options show
	default SupportedClasses.Add(AActor);

	// Copies the actors to clipboard that can be pasted onto arrays
	UFUNCTION(CallInEditor, meta = (EditorIcon = "GenericCommands.Copy"))
	void CopySelectedActorsAsArray()
	{
		TArray<AActor> SelectedActors = Editor::SelectedActors;

		FString Clipboard = f"({SelectedActors[0].GetPathName()}";
		Log(SelectedActors[0].GetPathName());
		for (int i = 1; i < SelectedActors.Num(); i++)
		{
			Clipboard += "," + SelectedActors[i].GetPathName();
		}
		Clipboard += ")";

		Editor::CopyToClipBoard(Clipboard);
	}
}