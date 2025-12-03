
#if EDITOR
class UDisableComponentVisualizer : UHazeScriptComponentVisualizer
{
    default VisualizedClass = UDisableComponent;

    UFUNCTION(BlueprintOverride)
    void VisualizeComponent(const UActorComponent Component)
    {
		UDisableComponent DisableComp = Cast<UDisableComponent>(Component);
		if (DisableComp != nullptr && DisableComp.bAutoDisable && (
				Editor::IsComponentSelected(DisableComp) || 
				DisableComp.Owner.ActorHasTag(n"GroupedDisable")))
		{
			float Range = DisableComp.AutoDisableRange;

			FVector Origin = DisableComp.Owner.ActorLocation;

			FVector PrevPoint;
			FVector FirstPoint;

			if(DisableComp.bDrawDisableRange)
			{
				for (int i = 0; i < 40; ++i)
				{
					float Angle = (360.0 / 40.0) * float(i);
					FVector Point = Origin + FRotator(0.0, Angle, 0.0).RotateVector(FVector(Range, 0.0, 0.0));
					DrawLine(Origin, Point, FLinearColor::Green, Thickness = 10.0);

					if (i != 0)
						DrawLine(PrevPoint, Point, FLinearColor::Green, Thickness = 10.0);
					else
						FirstPoint = Point;
					PrevPoint = Point;
				}

				DrawLine(PrevPoint, FirstPoint, FLinearColor::Green, Thickness = 10.0);
				DrawWireSphere(Origin, Range, FLinearColor::Green, 10.0, 24);
			}

			if(DisableComp.bDrawLinkedActors)
			{
				for (auto GroupActor : DisableComp.AutoDisableLinkedActors)
				{
					if (GroupActor.Get() != nullptr)
						DrawLine(Origin, GroupActor.Get().ActorLocation, FLinearColor::Purple, Thickness = 20.0);
				}
			}
		}
	}
};
#endif