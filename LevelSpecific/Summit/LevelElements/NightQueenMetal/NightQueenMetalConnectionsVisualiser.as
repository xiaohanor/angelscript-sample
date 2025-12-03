#if EDITOR
class UNightQueenMetalConnectionsVisualiser : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UNightQueenMetalComponent;

	UFUNCTION(BlueprintOverride)
    void VisualizeComponent(const UActorComponent Component)
    {
        UNightQueenMetalComponent Comp = Cast<UNightQueenMetalComponent>(Component);
		ANightQueenMetal Metal = Cast<ANightQueenMetal>(Comp.Owner);
        if (!ensure((Comp != nullptr) && (Comp.GetOwner() != nullptr)))
            return;

		SetRenderForeground(false);
        
		for(auto Crystal : Metal.PoweringCrystals)
		{
			if(Crystal == nullptr)
			{
				continue;
			}

			DrawLine(Metal.ActorLocation, Crystal.ActorLocation, FLinearColor::Red, 5);
		}
    }  
}
#endif