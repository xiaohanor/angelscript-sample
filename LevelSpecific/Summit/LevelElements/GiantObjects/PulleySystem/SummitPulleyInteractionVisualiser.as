#if EDITOR
class USummitPulleyInteractionVisualiser : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UPulleyInteractionComponent;

	UFUNCTION(BlueprintOverride)
    void VisualizeComponent(const UActorComponent Component)
    {
        UPulleyInteractionComponent Comp = Cast<UPulleyInteractionComponent>(Component);
		
        if (!ensure((Comp != nullptr) && (Comp.GetOwner() != nullptr)))
            return;

		APulleyInteraction Pulley = Cast<APulleyInteraction>(Comp.Owner);

		if(!ensure(Pulley != nullptr))
			return;

		USummitPulleySettings Settings = USummitPulleySettings::GetSettings(Pulley);

		SetRenderForeground(false);
		
		if(Pulley.PulleyObject != nullptr)
			VisualisePullPoints(Pulley.ActorLocation, Pulley.PulleyRopePoints, Pulley.PulleyObject.ActorLocation);

		VisualisePullThreshold(Pulley.ActorLocation, -Pulley.TranslateComponent.MinX, Settings.FullyPulledThreshold, -Pulley.ActorForwardVector);
    }

	void VisualisePullPoints(FVector PulleyLocation, TArray<FVector> PullPoints, FVector PullObjectLocation)
	{
		if(PullPoints.Num() == 0)
			return;

		for(int i = 0; i < PullPoints.Num(); i++)
		{
			FVector PointLocation = PulleyLocation + PullPoints[i];
			DrawWireSphere(PointLocation, 50,  FLinearColor::White, 5);
		}

		DrawLine(PulleyLocation, PullPoints[0] + PulleyLocation, FLinearColor::Blue, 5);

		for(int i = 0; i < PullPoints.Num() - 1; i++)
		{
			FVector PointLocation = PulleyLocation + PullPoints[i];
			FVector NextPoint = PullPoints[i+1] + PulleyLocation;
			DrawLine(PointLocation, NextPoint, FLinearColor::Blue, 5);
		}
		
		DrawLine(PullPoints.Last() + PulleyLocation, PullObjectLocation, FLinearColor::Blue, 5);
	}

	void VisualisePullThreshold(FVector PulleyLocation, float MaxPulledBackLength, float Threshold, FVector PulleyBackwards)
	{
		FVector ThresholdLocation = PulleyLocation + PulleyBackwards * MaxPulledBackLength * Threshold;
		DrawWireSphere(ThresholdLocation, 40, FLinearColor::Red, 5);
	}	
			
}
#endif