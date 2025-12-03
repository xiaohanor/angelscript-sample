class UPlayerDefaultProxyEmitterActivationSettings : UHazeComposableSettings
{
	UPROPERTY(EditDefaultsOnly)
	bool bCanActivate = true;

	UPROPERTY(EditDefaultsOnly)
	bool bIncludeVOInDefaultProxies = true;

	// Buffer distance to IdealCameraDistance before the default capability activates
	UPROPERTY(EditDefaultsOnly, Meta = (EditCondition = bCanActivate, ForceUnits = "cm"))
	float CameraDistanceActivationBufferDistance = 300.0;

	UPROPERTY(EditDefaultsOnly)
	float DefaultAttenuation = 1.0;

	UPROPERTY(EditDefaultsOnly)
	float SideScrollerAttenuation = 1.0;
}
