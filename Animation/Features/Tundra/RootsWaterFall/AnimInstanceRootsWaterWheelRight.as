UCLASS(Abstract)
class UAnimInstanceRootsWaterWheelRight : UAnimInstance
{
	UPROPERTY(Transient, BlueprintReadOnly, NotVisible)
	FTransform TipTransform;

	AWaterslide_Geyser WaterslideGeyser;

	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		if(OwningComponent == nullptr)
			return;

		WaterslideGeyser = Cast<AWaterslide_Geyser>(OwningComponent.Owner);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTimeX)
	{
		if(WaterslideGeyser == nullptr)
			WaterslideGeyser = Cast<AWaterslide_Geyser>(OwningComponent.Owner);

		if(WaterslideGeyser == nullptr)
			return;

		FTransform Transform = FTransform::Identity;
		FVector WorldLocation = WaterslideGeyser.RightRootCurrentPoint;

#if EDITOR
		if(!Editor::IsPlaying())
		{
			if(WaterslideGeyser.bPreviewTargetInEditor)
			{
				WorldLocation = WaterslideGeyser.RightVineTargetRoot.WorldLocation;
			}
			else
			{
				if(WaterslideGeyser.bAnimatePreviewAlpha)
				{
					WaterslideGeyser.PreviewAlpha = Math::Saturate(Math::Fmod(Time::GameTimeSeconds, WaterslideGeyser.ChargeDuration) / WaterslideGeyser.ChargeDuration);
					WaterslideGeyser.PreviewAlpha = Math::EaseInOut(0.0, 1.0, WaterslideGeyser.PreviewAlpha, 2.0);
					if(Math::FloorToInt(Time::GameTimeSeconds / WaterslideGeyser.ChargeDuration) % 2 == 0)
						WaterslideGeyser.PreviewAlpha = 1.0 - WaterslideGeyser.PreviewAlpha;
				}
				WorldLocation = Math::Lerp(WaterslideGeyser.RightVineRoot.WorldLocation, WaterslideGeyser.RightVineTargetRoot.WorldLocation, WaterslideGeyser.PreviewAlpha);
			}
		}
#endif

		FVector LocalOffset = WaterslideGeyser.RightRootsMesh.WorldTransform.InverseTransformPosition(WorldLocation + WaterslideGeyser.RightRootWorldOffset);
		Transform.Location = FVector(-LocalOffset.Z, LocalOffset.Y, LocalOffset.X);
		Transform.Rotation = FQuat::Identity;
		TipTransform = Transform;
	}
}