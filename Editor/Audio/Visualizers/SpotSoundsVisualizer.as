class USpotSoundsVisualizer : UHazeSpotAudioComponentVisualizer
{
	default VisualizedClass = USpotSoundComponent;

	UFUNCTION()
	bool GetVisualizeColor(UObject Object, FLinearColor& OutColor) const
	{		
		return true;
		
		// FLinearColor CancelColor = FLinearColor::White;
		// OutColor = FLinearColor::White;

		// return true;
	}

	UFUNCTION(BlueprintOverride)
	void DrawVisualization(UHazeSpotSoundComponent SpotSound, bool bIsSelected, const FVector ViewLocation, float DeltaTime)
	{
		FLinearColor Color = SpotSound.WidgetColor;
		Color.A = bIsSelected ? 1.0 : 0.5;

		const FVector Loc = SpotSound.GetWorldLocation();

		const float SpotDistance = Loc.Distance(ViewLocation);
		const float ScaledDistSize = Math::Lerp(100.0, 1000.0, Math::GetPercentageBetweenClamped(500.0, 10000.0, SpotDistance));

		Debug::DrawDebugSolidSphere(Loc, ScaledDistSize, Color, 0.0, 12, true);	
		SpotSound.ScaleSprite(ScaledDistSize / 30);

		if(bIsSelected && SpotSound.LinkedMeshOwner.IsValid())
			SpotSound.DrawLinkedMeshDebugArrow(10, SpotSound.WidgetColor);
					
	}

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto Spot = Cast<USpotSoundComponent>(Component);
		if (Spot == nullptr)
			return;
		
		if (Spot.LinkedMeshOwner.IsValid())
		{
			DrawDashedLine(Spot.WorldLocation, Spot.LinkedMeshOwner.Get().ActorLocation, Spot.WidgetColor);
			
			auto MeshComponent = UPrimitiveComponent::Get(Spot.LinkedMeshOwner.Get());

			if (MeshComponent != nullptr)
			{
				auto ShapeCenter = MeshComponent.Bounds.Origin;
				DrawWireBox(MeshComponent.BoundsOrigin, MeshComponent.BoundsExtent, MeshComponent.WorldRotation.Quaternion(), Spot.WidgetColor);
			}
		}
	}

}
