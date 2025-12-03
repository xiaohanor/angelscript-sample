
class UAudioViewportWidget : UHazeAudioViewportOverlayWidget
{
	UPROPERTY(Meta = (BindWidget))
	UHazeImmediateWidget DynamicContent;

	UFUNCTION(BlueprintEvent)
	UVerticalBox GetVerticalBox() property 
	{
		return nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void AddChild(UWidget Widget)
	{
		VerticalBox.AddChild(Widget);
	}

	UFUNCTION(BlueprintOverride)
	void RemoveChild(UWidget Widget)
	{
		VerticalBox.RemoveChild(Widget);
	}
}