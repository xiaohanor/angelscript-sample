class UMagnetDroneForceFeedbackEventHandler : UMagnetDroneEventHandler
{
	UPROPERTY()
	UForceFeedbackEffect FFA_Launch;

	UPROPERTY()
	UForceFeedbackEffect FFA_Collision;

	UPROPERTY()
	UForceFeedbackEffect FFA_NoMagneticSurfaceFound;

	bool bAttracting = false;
	float TimeStampStartedAttracting = -1.0;
}