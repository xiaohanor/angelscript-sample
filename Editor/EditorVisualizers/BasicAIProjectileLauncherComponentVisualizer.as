class UBasicAIProjectileLauncherComponentVisualizer : UHazeScriptComponentVisualizer
{
    default VisualizedClass = UBasicAIProjectileLauncherComponent;

    UFUNCTION(BlueprintOverride)
    void VisualizeComponent(const UActorComponent Component)
    {
        UBasicAIProjectileLauncherComponent LauncherComp = Cast<UBasicAIProjectileLauncherComponent>(Component);
        if (!ensure((LauncherComp != nullptr) && (LauncherComp.GetOwner() != nullptr)))
            return;
        
		FLinearColor Colour = FLinearColor::Red;
		DrawDashedLine(LauncherComp.WorldLocation, LauncherComp.GetLaunchLocation(), Colour, 10);
		DrawWireSphere(LauncherComp.GetLaunchLocation(), 5.0, Colour, 3.0, 4);
    }   
} 

