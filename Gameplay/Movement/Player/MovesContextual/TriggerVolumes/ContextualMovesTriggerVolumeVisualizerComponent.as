
class UContextualMovesTriggerVolumeVisualizerComponent : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UContextualMovesVolumeVisualizerComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		UContextualMovesVolumeVisualizerComponent Comp = Cast<UContextualMovesVolumeVisualizerComponent>(Component);

		if(Comp == nullptr)
			return;

		AContextualMovesTriggerVolume VolumeActor = Cast<AContextualMovesTriggerVolume>(Component.Owner);

		if(VolumeActor == nullptr)
			return;

		FVector StartActorOffset = FVector(0.0, 0.0, 90.0);
		FLinearColor LineColor = FLinearColor::Green;

		if(VolumeActor.ContextMoveActorsToEnable.Num() > 0)
		{
			for (auto EnableActor : VolumeActor.ContextMoveActorsToEnable)
			{
				if(EnableActor == nullptr)
					continue;

				DrawLine(VolumeActor.ActorLocation + StartActorOffset, EnableActor.ActorLocation, LineColor, 5);
				DrawWireDiamond(EnableActor.ActorLocation, FRotator::ZeroRotator, Size = 50, Color = LineColor);
			}
		}

		if(VolumeActor.ContextMoveActorsToDisable.Num() > 0)
		{
			LineColor = FLinearColor::Red;

			for (auto DisableActor : VolumeActor.ContextMoveActorsToDisable)
			{
				if(DisableActor == nullptr)
					continue;

				DrawLine(VolumeActor.ActorLocation + StartActorOffset, DisableActor.ActorLocation, LineColor, 5);
				DrawWireDiamond(DisableActor.ActorLocation, FRotator::ZeroRotator, Size = 50, Color = LineColor);
			}
		}

		if(VolumeActor.bValidateWorldUp)
		{
			DrawArc(VolumeActor.ActorLocation + FVector(0, 0, 25), Angle = 2 * VolumeActor.WorldUpDegreeMargin, Radius = 300, Direction = VolumeActor.ActorUpVector, Normal = VolumeActor.ActorForwardVector, Color = FLinearColor::Yellow, Thickness = 5);
			DrawArc(VolumeActor.ActorLocation + FVector(0, 0, 25), Angle = 2 * VolumeActor.WorldUpDegreeMargin, Radius = 300, Direction = VolumeActor.ActorUpVector, Normal = VolumeActor.ActorRightVector, Color = FLinearColor::Yellow, Thickness = 5);
		}
	}
}

// class UContextualMovesTriggerVolumeDetails : UHazeScriptDetailCustomization
// {
// 	default DetailClass = AContextualMovesTriggerVolume;
// 	UHazeImmediateDrawer MessageDrawer;

// 	UFUNCTION(BlueprintOverride)
// 	void CustomizeDetails()
// 	{
// 		auto Volume = Cast<AContextualMovesTriggerVolume>(GetCustomizedObject());

// 		if(Volume == nullptr)
// 			return;

// 		MessageDrawer = AddImmediateRow(n"Settings");
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	void Tick(float DeltaTime)
// 	{
// 		auto Volume = Cast<AContextualMovesTriggerVolume>(GetCustomizedObject());

// 		if(Volume == nullptr)
// 			return;

// 		if(MessageDrawer != nullptr && MessageDrawer.IsVisible())
// 		{
// 			auto Root = MessageDrawer.Begin();
// 			Root.Spacer(5);

// 			Root.Text("Remove this if no information is needed in script details customizer").Color(FLinearColor::DPink);

// 			Root.Spacer(5);
// 		}
// 	}
// }