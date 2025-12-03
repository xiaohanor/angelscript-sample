#if EDITOR

class UAudioWaterMovementVolumeDetails : UHazeScriptDetailCustomization
{
	default DetailClass = AAudioWaterMovementVolume;
	UHazeImmediateDrawer Drawer;

	UFUNCTION(BlueprintOverride)
	void CustomizeDetails()
	{
		Drawer = AddImmediateRow(n"Audio Water Movement Volume");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		auto Volume = Cast<AAudioWaterMovementVolume>(GetCustomizedObject());
		if (Volume == nullptr)
			return;

		if (Drawer == nullptr || !Drawer.IsVisible())
			return;

		// if (Volume.MovementType == EHazeAudioWaterMovementType::Footsteps)
		{
			auto NewSurfacePosition = FVector::ZeroVector;

			auto Distance = 
				Volume.BrushComponent.GetClosestPointOnCollision(
					Volume.BrushComponent.GetBoundsOrigin() + 
					(Volume.BrushComponent.BoundingBoxExtents * FVector::UpVector) + 
					Volume.ActorUpVector * 50
				, NewSurfacePosition);

			if (NewSurfacePosition != Volume.SurfacePosition)
			{
				Volume.Modify();
				Volume.SurfacePosition = NewSurfacePosition;
			}
		}
	}
}

#endif