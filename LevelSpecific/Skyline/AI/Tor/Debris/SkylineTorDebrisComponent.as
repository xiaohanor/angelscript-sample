class USkylineTorDebrisComponent : USceneComponent
{
	UPROPERTY()
	TSubclassOf<ASkylineTorDebris> DebrisClass;
	UPROPERTY()
	TSubclassOf<ASkylineTorRainDebris> RainDebrisClass;
}