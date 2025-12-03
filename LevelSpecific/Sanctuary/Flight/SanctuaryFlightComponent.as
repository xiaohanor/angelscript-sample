event void FSanctuaryFlightEvent(USanctuaryFlightComponent FlightComp);

class USanctuaryFlightComponent : UActorComponent
{
	USceneComponent Center = nullptr;
	UHazeCameraSettingsDataAsset CameraSettings = nullptr;
	float Radius = 25000.0;
	float LowerBounds = -5000.0;
	float UpperBounds = 5000.0;

	bool bFlying = false;
	TInstigated<FVector> AdditionalAcceleration;

	FSanctuaryFlightEvent OnStartFlying;
	FSanctuaryFlightEvent OnStopFlying;
}
