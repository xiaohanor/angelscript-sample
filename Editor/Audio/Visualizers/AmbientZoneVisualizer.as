
struct FAmbientZonePrioritySelection
{
	AHazeAudioZone GetZoneWithHighestPriority() const
	{
		if (Editor::IsPlaying())
			return nullptr;

		TArray<AAmbientZone> OverlappingZones = Editor::GetAllEditorWorldActorsOfClass(AAmbientZone);
		auto Actors = EditorFilter::BySelection(OverlappingZones);

		// Ignore if it's only one actor
		if (Actors.Num() == 1)
			return nullptr;

		AHazeAudioZone HighestPriorityZone;
		for	(auto ZoneOverlap: Actors)
		{
			auto Zone = Cast<AAmbientZone>(ZoneOverlap);
			if (Zone == nullptr)
				continue;

			if (HighestPriorityZone == nullptr || Zone.GetZonePriority() > HighestPriorityZone.GetZonePriority())
			{
				HighestPriorityZone = Zone;
			}
		}

		return HighestPriorityZone;
	}
}

const FAmbientZonePrioritySelection PrioritySelection;

class UAmbientZoneVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UBrushComponent;

	bool bCreatedZones = false;

	UFUNCTION(BlueprintOverride)
	void EndEditing()
	{
		bCreatedZones = false;
	}

    UFUNCTION(BlueprintOverride)
    void VisualizeComponent(const UActorComponent Component)
    {
        auto BrushComp = Cast<UBrushComponent>(Component);
        if (BrushComp == nullptr)
            return;

		auto AudioZone = Cast<AHazeAudioZone>(Component.Owner);
		if (AudioZone == nullptr)
			return;

		// NOTE: HACK to add overlapping ambient zones
		#if EDITOR
		// Only update if audio people
		if (AudioUtility::IsWaapiConnected())
		{
			auto PortalZone = Cast<APortalZone>(Component.Owner);
			if (PortalZone != nullptr)
			{
				if (!PortalZone.Connections.bOverrideConnectedZones)
				{
					AAmbientZone ZoneA = nullptr;
					AAmbientZone ZoneB = nullptr;

					TArray<AAmbientZone> OverlappingZones = Editor::GetAllEditorWorldActorsOfClass(AAmbientZone);

					FBox PortalBox = FBox::BuildAABB(PortalZone.BrushComponent.BoundsOrigin, PortalZone.BrushComponent.BoundsExtent);

					for	(auto ZoneOverlap: OverlappingZones)
					{
						auto AmbientZone = Cast<AAmbientZone>(ZoneOverlap);
						if (AmbientZone == nullptr)
							continue;

						auto ZoneBox = FBox::BuildAABB(AmbientZone.BrushComponent.BoundsOrigin, AmbientZone.BrushComponent.BoundsExtent);
						if (!(PortalBox.Intersect(ZoneBox)))
							continue;

						if (ZoneA == nullptr || AmbientZone.GetZonePriority() > ZoneA.GetZonePriority())
						{
							if (ZoneB == nullptr || ZoneA.GetZonePriority() > ZoneB.GetZonePriority())
								ZoneB = ZoneA;

							ZoneA = AmbientZone;
						}

						if ((ZoneB == nullptr
							|| AmbientZone.GetZonePriority() > ZoneB.GetZonePriority())
							&& AmbientZone != ZoneA)
						{
							ZoneB = AmbientZone;
						}
					}

					PortalZone.Connections.Zones.Empty();
					if (ZoneB != nullptr)
						PortalZone.Connections.Zones.AddUnique(ZoneB);
					if (ZoneA != nullptr)
						PortalZone.Connections.Zones.AddUnique(ZoneA);
				}
				PortalZone.CalculateBounds(this);
			}
		}
		#endif

		AudioZone::DrawZone(AudioZone, PrioritySelection.GetZoneWithHighestPriority() == AudioZone,  this);
    }
}