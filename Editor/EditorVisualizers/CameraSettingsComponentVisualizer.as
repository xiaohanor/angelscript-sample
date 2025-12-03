class UCameraSettingsComponentVisualizer : UHazeScriptComponentVisualizer
{
    default VisualizedClass = UHazeCameraSettingsComponent;

    UFUNCTION(BlueprintOverride)
    void VisualizeComponent(const UActorComponent Component)
    {
        UHazeCameraSettingsComponent SettingsComp = Cast<UHazeCameraSettingsComponent>(Component);
        if (!ensure((SettingsComp != nullptr) && (SettingsComp.GetOwner() != nullptr)))
            return;
        
		if (SettingsComp.Camera != nullptr)
		{
			FLinearColor Color = FLinearColor::Black;
			switch(SettingsComp.Player)
			{
				case EHazeSelectPlayer::Both:
					Color = FLinearColor::Yellow;
					break;
				case EHazeSelectPlayer::Mio:
					Color = PlayerColor::Mio;
					break;
				case EHazeSelectPlayer::Zoe:
					Color = PlayerColor::Zoe;
					break;
				default:
					break;
			}
			DrawDashedLine(SettingsComp.GetOwner().GetActorLocation(), SettingsComp.Camera.GetActorLocation(), Color, 20);
		}
    }   
} 

