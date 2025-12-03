
class URespawnPointVolumeVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = URespawnPointVolumeVisualizerComponent;

    UFUNCTION(BlueprintOverride)
    void VisualizeComponent(const UActorComponent Component)
    {
        URespawnPointVolumeVisualizerComponent Comp = Cast<URespawnPointVolumeVisualizerComponent>(Component);
        if (Comp == nullptr)
            return;

		ARespawnPointVolume RespawnPointVolume = Cast<ARespawnPointVolume>(Component.Owner);
		if (RespawnPointVolume == nullptr)
			return ;

		FVector Offset = FVector(0.0, 0.0, 90.0);
		FVector StartLocation = RespawnPointVolume.ActorLocation + Offset;
		for (ARespawnPoint RespawnPoint : RespawnPointVolume.EnabledRespawnPoints)
		{
			if (RespawnPoint == nullptr)
				continue;

			// Colour depending on who can use it
			FLinearColor Color = FLinearColor(1.0, 0.4, 0.0);
			if (!RespawnPoint.bCanMioUse && !RespawnPoint.bCanZoeUse)
				continue;
			else if (RespawnPoint.bCanMioUse && !RespawnPoint.bCanZoeUse)
				Color = FLinearColor::Blue;
			else if (!RespawnPoint.bCanMioUse && RespawnPoint.bCanZoeUse)
				Color = FLinearColor::Red;

			FVector EndLocation = RespawnPoint.ActorLocation + Offset;
			DrawLine(StartLocation, EndLocation, Color, 5.0);
		}

		for (ARespawnPointVolume DisableBacktrack : RespawnPointVolume.DisableBacktrackingToVolumes)
		{
			if (DisableBacktrack == nullptr)
				continue;

			// Colour depending on who can use it
			FVector EndLocation = DisableBacktrack.ActorLocation + Offset;
			DrawDashedLine(StartLocation, EndLocation, FLinearColor::Red, 5.0);
		}
    }
}

class URespawnPointVolumeDetails : UHazeScriptDetailCustomization
{
	default DetailClass = ARespawnPointVolume;
	UHazeImmediateDrawer MessageDrawer;

	UFUNCTION(BlueprintOverride)
	void CustomizeDetails()
	{
		auto RespawnVolume = Cast<ARespawnPointVolume>(GetCustomizedObject());
		if (RespawnVolume == nullptr)
			return;

		MessageDrawer = AddImmediateRow(n"RespawnPoints");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		auto RespawnVolume = Cast<ARespawnPointVolume>(GetCustomizedObject());
		if (RespawnVolume == nullptr)
			return;

		if (MessageDrawer != nullptr && MessageDrawer.IsVisible())
		{
			auto Root = MessageDrawer.Begin();
			Root.Spacer(5);

			if (RespawnVolume.EnabledRespawnPoints.Num() != 0)
			{
				bool bMioUse = RespawnVolume.HasRespawnPointsUsableBy(EHazePlayer::Mio);
				if (!bMioUse && RespawnVolume.bTriggerForMio)
					Root.Text("No Respawn Points usable by Mio selected.").Color(FLinearColor::Yellow);

				bool bZoeUse = RespawnVolume.HasRespawnPointsUsableBy(EHazePlayer::Zoe);
				if (!bZoeUse && RespawnVolume.bTriggerForZoe)
					Root.Text("No Respawn Points usable by Zoe selected.").Color(FLinearColor::Yellow);
			}

			Root.Spacer(5);
		}
	}
}