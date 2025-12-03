asset SanctuaryCylinderFlightSheet of UHazeCapabilitySheet
{
	AddCapability(n"SanctuaryFlightCapability");
	AddCapability(n"SanctuaryCylindricalFlyingCapability");
	AddCapability(n"SanctuaryFlightCameraCapability");
	AddCapability(n"SanctuaryCylindricalDashCapability");
	AddCapability(n"SanctuaryFlightSoarCapability");
	AddCapability(n"SanctuaryFlightDiveCapability");

	Components.Add(USanctuaryFlightComponent);
}

asset SanctuaryFlightCameraSettings of UHazeCameraSpringArmSettingsDataAsset
{
	SpringArmSettings.bUseIdealDistance = true;
	SpringArmSettings.IdealDistance = 1000.0;
}

UCLASS(Abstract)
class ASanctuaryFlightCenterActor : AHazeActor
{
	UPROPERTY(DefaultComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UArrowComponent Arrow;
	default Arrow.ArrowColor = FLinearColor::Yellow;
	default Arrow.RelativeScale3D = FVector(10.0);
	default Arrow.RelativeRotation = FRotator(90.0, 0.0, 0.0);

	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent PlayerCapabilityComp;
	default PlayerCapabilityComp.InitialStoppedSheets.Add(SanctuaryCylinderFlightSheet);

	UPROPERTY(EditAnywhere)
	UHazeCameraSettingsDataAsset CameraSettings = SanctuaryFlightCameraSettings;

	UPROPERTY(EditAnywhere)
	float Radius = 25000.0;

	UPROPERTY(EditAnywhere)
	float LowerBounds = -10000.0;

	UPROPERTY(EditAnywhere)
	float UpperBounds = 10000.0;

	UPROPERTY(DefaultComponent, NotVisible, BlueprintHidden)
	UDummyVisualizationComponent DummyVisualizer;
	default DummyVisualizer.Color = FLinearColor::Yellow;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		DummyVisualizer.Cylinders.SetNum(2);
		DummyVisualizer.Cylinders[0] = FDummyVisualizationCylinder(Root, Radius, LowerBounds, UpperBounds, 10.0, 64);
		DummyVisualizer.Cylinders[1] = FDummyVisualizationCylinder(Root, Radius, LowerBounds * 0.33, UpperBounds * 0.33, 10.0, 64);
	}

	UFUNCTION(DevFunction)
	void StartFlying()
	{
		for (AHazePlayerCharacter Player : Game::Players)
		{
			USanctuaryFlightComponent FlightComp = USanctuaryFlightComponent::GetOrCreate(Player);
			FlightComp.bFlying = true;
			FlightComp.Center = Root;
			FlightComp.CameraSettings = CameraSettings;
			FlightComp.LowerBounds = LowerBounds;
			FlightComp.UpperBounds = UpperBounds;
			FlightComp.Radius = Radius;
			PlayerCapabilityComp.StartInitialSheetsAndCapabilities(Player, this);
			
		}
	}

	UFUNCTION(DevFunction)
	void StopFlying()
	{
		for (AHazePlayerCharacter Player : Game::Players)
		{
			USanctuaryFlightComponent FlightComp = USanctuaryFlightComponent::GetOrCreate(Player);
			FlightComp.bFlying = false;
			PlayerCapabilityComp.StopInitialSheetsAndCapabilities(Player, this);
		}
	}
}

