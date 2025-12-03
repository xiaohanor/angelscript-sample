#if EDITOR
class USwarmDroneHijackComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = USwarmDroneHijackTargetableComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		USwarmDroneHijackTargetableComponent HijackComponent = Cast<USwarmDroneHijackTargetableComponent>(Component);
		if (HijackComponent == nullptr)
			return;

		VisualizeDiveArea(HijackComponent);

		VisualizeDiveCamera(HijackComponent);

		ASwarmDroneSimpleMovementHijackable MovementHijackable = Cast<ASwarmDroneSimpleMovementHijackable>(HijackComponent.Owner);
		if (MovementHijackable != nullptr)
		{
			if (MovementHijackable.MovementSettings.HijackType == ESwarmDroneSimpleMovementHijackType::AxisConstrained)
				VisualizeMovementOffset(MovementHijackable);
		}

		// Now visualize player location
		FVector PlayerWorldLocation = HijackComponent.GetWorldPlayerSnapLocation();
		// UStaticMesh DroneMesh = Cast<UStaticMesh>(Editor::LoadAsset(n"/Game/Maps/TestMaps/JacobL/DroneTests/MD_Test.MD_Test"));
		// UMaterialInterface Material = Cast<UMaterialInterface>(Editor::LoadAsset(n"/Engine/EngineDebugMaterials/M_SimpleTranslucent.M_SimpleTranslucent"));

		// DrawMeshWithMaterial(DroneMesh, Material, PlayerWorldLocation, FQuat::Identity, FVector(1));
		DrawWireSphere(PlayerWorldLocation, 37.5, FLinearColor::Green * 0.6, 1);
	}

	void VisualizeDiveArea(const USwarmDroneHijackTargetableComponent& HijackComponent)
	{
		FSwarmDroneHijackTargetRectangle TargetRectangle = HijackComponent.MakeBotDiveTargetRectangle();

		FQuat Rotation = FQuat::MakeFromX(TargetRectangle.PlaneNormal);
		DrawWireBox(TargetRectangle.WorldOrigin, FVector(1, TargetRectangle.Size.X, TargetRectangle.Size.Y), Rotation, FLinearColor::LucBlue, 5.0);

		for (int i = 0; i < SwarmDrone::DeployedBotCount; i++)
		{
			FVector BotLocation = SwarmDroneHijack::GetRandomWorldDiveTransformForHijackable(HijackComponent).Location;
			DrawCircle(BotLocation, 2, FLinearColor::MakeRandomColor(), Normal = TargetRectangle.PlaneNormal);
		}
	}

	void VisualizeDiveCamera(const USwarmDroneHijackTargetableComponent& HijackComponent)
	{
		FVector CameraLocation = HijackComponent.GetTargetCameraTransform().Location;
		DrawWireBox(CameraLocation, FVector(10), FQuat::MakeFromX(-HijackComponent.ForwardVector), FLinearColor::Blue, 5);
		DrawWireDiamond(CameraLocation - HijackComponent.ForwardVector * 15, FRotator::MakeFromX(-HijackComponent.ForwardVector), 10, FLinearColor::Blue, 3);
		DrawDashedLine(CameraLocation - HijackComponent.ForwardVector * 20, HijackComponent.WorldLocation, FLinearColor::LucBlue, 5, 1);
	}

	void VisualizeMovementOffset(ASwarmDroneSimpleMovementHijackable SimpleMovementHijackable)
	{
		UMaterialInterface MeshPreviewMaterial = Cast<UMaterialInterface>(Editor::LoadAsset(n"/Engine/EngineDebugMaterials/M_SimpleTranslucent.M_SimpleTranslucent"));

		// Visualize mesh
		TArray<UStaticMeshComponent> MeshComponents;
		SimpleMovementHijackable.GetComponentsByClass(MeshComponents);
		for (auto MeshComponent : MeshComponents)
		{
			switch (SimpleMovementHijackable.MovementSettings.HijackType)
			{
				case ESwarmDroneSimpleMovementHijackType::AxisConstrained:
				{
					FVector NegativeBound, PositiveBound;
					SimpleMovementHijackable.MovementSettings.AxisConstrainedSettings.GetWorldBounds(SimpleMovementHijackable.RootComponent, NegativeBound, PositiveBound);

					if (SimpleMovementHijackable.MovementSettings.AxisConstrainedSettings.NegativeBound != 0.0)
						DrawMeshWithMaterial(MeshComponent.StaticMesh, MeshPreviewMaterial, NegativeBound, MeshComponent.WorldRotation.Quaternion(), MeshComponent.WorldScale);

					if (SimpleMovementHijackable.MovementSettings.AxisConstrainedSettings.PositiveBound != 0.0)
						DrawMeshWithMaterial(MeshComponent.StaticMesh, MeshPreviewMaterial, PositiveBound, MeshComponent.WorldRotation.Quaternion(), MeshComponent.WorldScale);

					DrawDashedLine(NegativeBound, PositiveBound, FLinearColor::DPink);

					continue;
				}

				case ESwarmDroneSimpleMovementHijackType::SplineConstrained:
				{

					continue;
				}
			}
		}
	}
}
#endif