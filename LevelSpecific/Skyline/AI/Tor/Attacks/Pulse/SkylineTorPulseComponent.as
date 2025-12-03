class USkylineTorPulseComponent : USceneComponent
{
	UPROPERTY()
	TSubclassOf<ASkylineTorPulse> PulseClass;

	bool bAllowWhileNotStolen;
	bool bSpawningPulses = false;
}