class ASlidingDiscBecomeBoatVolume : APlayerTrigger
{
	default Shape::SetVolumeBrushColor(this, ColorDebug::Blue);
	default BrushComponent.LineThickness = 6.0;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		//Debug::DrawDebugSolidPlane(GetWaterHeightLocation(), ActorUpVector, Bounds.BoxExtent.Y, Bounds.BoxExtent.X, ColorDebug::Blue);
	}

	FVector GetWaterHeightLocation()
	{
		FVector TopLocation = ActorLocation;
		TopLocation.Z += Bounds.BoxExtent.Z;
		return TopLocation;
	}
};