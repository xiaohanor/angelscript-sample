namespace HiddenDevToggleStatics
{
	const FHazeDevToggleCategory DevPrintCategory = FHazeDevToggleCategory(n"Dev Print");
	const FHazeDevToggleBool PrintGeneric = FHazeDevToggleBool(HiddenDevToggleStatics::DevPrintCategory, n"Default");
	const FHazeDevToggleBool PrintEvent = FHazeDevToggleBool(HiddenDevToggleStatics::DevPrintCategory, n"Event");
	const FHazeDevToggleBool PrintAudio = FHazeDevToggleBool(HiddenDevToggleStatics::DevPrintCategory, n"Audio");
}

UFUNCTION(Category = "Debug", Meta = (DevelopmentOnly))
void DevPrintString(FString Prefix = "", FString PrintString = "Hello", float Duration = 2.0, FLinearColor Color = FLinearColor(0.698, 0.886, 0.741), float TextScale = 1.2)
{
#if !RELEASE
	if (HiddenDevToggleStatics::PrintGeneric.IsEnabled())
		PrintToScreenScaled("[Dev] " + Prefix + " - " + PrintString, Duration, Color, TextScale);
#endif	
}

UFUNCTION(Category = "Debug", Meta = (DevelopmentOnly))
void DevPrintStringCategory(FName CategoryName = n"Generic", FString Prefix = "", FString PrintString = "Hello", float Duration = 2.0, FLinearColor Color = FLinearColor(1.0, 0.705, 0.231), float TextScale = 1.2)
{
#if !RELEASE
	if (CategoryName.IsNone())
		return;
	UHazeDevToggleSubsystem::Get().PrintCategoryString(CategoryName, Prefix + " - " + PrintString, Duration, Color, TextScale);
#endif	
}

UFUNCTION(Category = "Debug", Meta = (DevelopmentOnly))
void DevPrintStringEvent(FString Prefix = "", FString PrintString = "EventName", float Duration = 2.0, FLinearColor Color = FLinearColor(1.0, 0.517, 0.0), float TextScale = 2.0)
{
#if !RELEASE
	if (HiddenDevToggleStatics::PrintEvent.IsEnabled())
		PrintToScreenScaled("[Event] " + Prefix + " - " + PrintString, Duration, Color, TextScale);
#endif	
}

UFUNCTION(Category = "Debug", Meta = (DevelopmentOnly))
void DevPrintStringAudio(FString Prefix = "", FString PrintString = "AudioName", float Duration = 3.0, FLinearColor Color = FLinearColor(0.917, 0.662, 1.0), float TextScale = 2.0)
{
#if !RELEASE
	if (HiddenDevToggleStatics::PrintAudio.IsEnabled())
		PrintToScreenScaled("[SFX] " + Prefix + " - " + PrintString, Duration, Color, TextScale);
#endif	
}