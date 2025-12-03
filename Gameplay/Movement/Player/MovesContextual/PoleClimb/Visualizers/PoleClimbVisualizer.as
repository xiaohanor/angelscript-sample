#if EDITOR
class UPoleClimbVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UPoleClimbEnterZone;

    UFUNCTION(BlueprintOverride)
    void VisualizeComponent(const UActorComponent Component)
    {
        APoleClimbActor Pole = Cast<APoleClimbActor>(Component.Owner);
        if (Pole == nullptr)
            return;
		if (Pole.World.IsGameWorld())
			return;

		FVector PoleSize = Pole.ActorUpVector * Pole.Height;
		FVector PoleBottom = Pole.ActorLocation;
		FVector PoleTop = PoleBottom + PoleSize;
		
		TArray<APoleClimbActor> AllPoles = Editor::GetAllEditorWorldActorsOfClass(APoleClimbActor);

		for (auto It : AllPoles)
		{
			auto OtherPole = Cast<APoleClimbActor>(It);
			if (!OtherPole.bEnablePoleTransferAssist)
				continue;
			if (OtherPole.ActorLocation.Distance(PoleTop) > OtherPole.MaxTransferAssistDistance + OtherPole.Height * 2.0 + 500.0)
				continue;

			FVector OtherPoleSize = OtherPole.ActorUpVector * OtherPole.Height;
			FVector OtherPoleBottom = OtherPole.ActorLocation;
			FVector OtherPoleTop = OtherPoleBottom + OtherPoleSize;

			FVector PoleLocation;
			FVector OtherLocation;

			Math::FindNearestPointsOnLineSegments(
				PoleTop, PoleBottom,
				OtherPoleTop, OtherPoleBottom,
				PoleLocation, OtherLocation
			);

			if (PoleLocation.Distance(OtherLocation) > OtherPole.MaxTransferAssistDistance)
				continue;

			DrawDashedLine(
				Pole.ActorLocation + PoleSize * 0.5,
				OtherPole.ActorLocation + OtherPoleSize * 0.5,
				FLinearColor::Yellow, Thickness = 4);
		}

		if (!Pole.bAllowFull360Rotation)
		{
			TArray<FVector> Directions = Pole.GetAllowedPlayerDirections();
		
			for (FVector Direction : Directions)
			{
				FVector HorizOffset = Direction * 45.0;
				DrawLine(
					Pole.ActorLocation + HorizOffset,
					Pole.ActorLocation + HorizOffset + PoleSize,
					FLinearColor::Blue, 10.0);
			}
		}
    }
}
#endif